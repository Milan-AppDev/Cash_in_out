<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json');

$servername = "localhost";
$username = "root";
$password = ""; // Your database password
$dbname = "flutter_auth_new"; // New database name

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    die(json_encode(['success' => false, 'message' => 'Connection failed: ' . $conn->connect_error]));
}

$method = $_SERVER['REQUEST_METHOD'];

// Get user ID from Authorization header (or other method like session/token)
// For simplicity here, we'll expect user_id in the request body/query params
// In a real app, use tokens for authentication

switch ($method) {
    case 'GET':
        $user_id = $_GET['user_id'] ?? null;
        if (!$user_id) {
            echo json_encode(['success' => false, 'message' => 'User ID is required']);
            exit;
        }

        // Get clients for the user with their last transaction date and balance
        $sql_clients = "SELECT c.*, 
                        COALESCE(SUM(CASE WHEN t.type = 'got' THEN t.amount ELSE -t.amount END), 0) AS balance, 
                        MAX(t.date) AS last_transaction_date
                      FROM clients c
                      LEFT JOIN transactions t ON c.id = t.client_id
                      WHERE c.user_id = ?
                      GROUP BY c.id
                      ORDER BY c.name ASC"; // You can adjust the ORDER BY clause as needed

        $stmt_clients = $conn->prepare($sql_clients);
        $stmt_clients->bind_param("i", $user_id);
        $stmt_clients->execute();
        $result_clients = $stmt_clients->get_result();

        $clients = [];
        while ($row = $result_clients->fetch_assoc()) {
            $clients[] = $row;
        }

        // Get user's total balance (sum of client balances)
        // This sum will now be computed from the clients' fetched balances
        $total_balance = 0.00;
        foreach ($clients as $client) {
            $total_balance += $client['balance'];
        }

        // Get total 'got' and 'given' amounts for the user
        $sql_got_given = "SELECT type, SUM(amount) as total FROM transactions WHERE user_id = ? GROUP BY type";
        $stmt_got_given = $conn->prepare($sql_got_given);
        $stmt_got_given->bind_param("i", $user_id);
        $stmt_got_given->execute();
        $result_got_given = $stmt_got_given->get_result();

        $total_got = 0.00;
        $total_given = 0.00;
        while ($row = $result_got_given->fetch_assoc()) {
            if ($row['type'] == 'got') {
                $total_got = $row['total'];
            } else if ($row['type'] == 'given') {
                $total_given = $row['total'];
            }
        }

        echo json_encode([
            'success' => true,
            'clients' => $clients,
            'total_balance' => $total_balance,
            'total_got' => $total_got,
            'total_given' => $total_given
        ]);
        break;

    case 'POST':
        $data = json_decode(file_get_contents('php://input'), true);

        if (!isset($data['name']) || !isset($data['phone']) || !isset($data['user_id'])) {
            echo json_encode(['success' => false, 'message' => 'Name, phone, and user_id are required']);
            exit;
        }

        $sql = "INSERT INTO clients (name, phone, user_id, balance) VALUES (?, ?, ?, 0.00)"; // Initialize balance to 0.00
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("ssi", $data['name'], $data['phone'], $data['user_id']);

        if ($stmt->execute()) {
            // No need to update user total balance here, it's calculated from client balances
            echo json_encode(['success' => true, 'message' => 'Client added successfully', 'client_id' => $conn->insert_id]);
        } else {
            echo json_encode(['success' => false, 'message' => 'Error adding client: ' . $conn->error]);
        }
        break;

    case 'PUT':
        $data = json_decode(file_get_contents('php://input'), true);

        if (!isset($data['id']) || !isset($data['user_id'])) {
            echo json_encode(['success' => false, 'message' => 'Client ID and user_id are required']);
            exit;
        }

        $updates = [];
        $types = "";
        $params = [];

        if (isset($data['name'])) {
            $updates[] = "name = ?";
            $types .= "s";
            $params[] = $data['name'];
        }
        if (isset($data['phone'])) {
            $updates[] = "phone = ?";
            $types .= "s";
            $params[] = $data['phone'];
        }

        if (empty($updates)) {
            echo json_encode(['success' => false, 'message' => 'No fields to update']);
            exit;
        }

        $types .= "ii"; // for id and user_id
        $params[] = $data['id'];
        $params[] = $data['user_id'];

        $sql = "UPDATE clients SET " . implode(", ", $updates) . " WHERE id = ? AND user_id = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param($types, ...$params);

        if ($stmt->execute()) {
            // No need to update user total balance here
            echo json_encode(['success' => true, 'message' => 'Client updated successfully']);
        } else {
            echo json_encode(['success' => false, 'message' => 'Error updating client: ' . $conn->error]);
        }
        break;

    case 'DELETE':
        $data = json_decode(file_get_contents('php://input'), true);

        if (!isset($data['id']) || !isset($data['user_id'])) {
            echo json_encode(['success' => false, 'message' => 'Client ID and user_id are required']);
            exit;
        }

        $client_id = $data['id'];
        $user_id = $data['user_id'];

        // Get client balance before deleting
        $sql_get_balance = "SELECT balance FROM clients WHERE id = ? AND user_id = ?";
        $stmt_get_balance = $conn->prepare($sql_get_balance);
        $stmt_get_balance->bind_param("ii", $client_id, $user_id);
        $stmt_get_balance->execute();
        $result_get_balance = $stmt_get_balance->get_result();

        if ($result_get_balance->num_rows === 0) {
             echo json_encode(['success' => false, 'message' => 'Client not found or unauthorized']);
             exit;
        }

        $client_data = $result_get_balance->fetch_assoc();
        $client_balance = $client_data['balance'];

        // Start transaction
         $conn->begin_transaction();

        try {
            // Delete client
            $sql_delete_client = "DELETE FROM clients WHERE id = ? AND user_id = ?";
            $stmt_delete_client = $conn->prepare($sql_delete_client);
            $stmt_delete_client->bind_param("ii", $client_id, $user_id);
            $stmt_delete_client->execute();

            // Update user total balance
            $sql_update_user_total_balance = "UPDATE users SET total_balance = total_balance - ? WHERE id = ?";
            $stmt_update_user_total_balance = $conn->prepare($sql_update_user_total_balance);
            $stmt_update_user_total_balance->bind_param("di", $client_balance, $user_id);
            $stmt_update_user_total_balance->execute();

            // Commit transaction
            $conn->commit();

            echo json_encode(['success' => true, 'message' => 'Client deleted successfully']);

        } catch (mysqli_sql_exception $exception) {
            $conn->rollback();
            echo json_encode(['success' => false, 'message' => 'Error deleting client: ' . $exception->getMessage()]);
        }

        break;

    default:
        echo json_encode(["success" => false, "message" => "Method not allowed"]);
        break;
}

$conn->close();
?> 