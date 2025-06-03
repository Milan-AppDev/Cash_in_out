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

// Get user ID from Authorization header (or other method)
// For simplicity here, we'll expect user_id in request

switch ($method) {
    case 'GET':
        $client_id = $_GET['client_id'] ?? null;
        $user_id = $_GET['user_id'] ?? null;

        if (!$client_id || !$user_id) {
            echo json_encode(['success' => false, 'message' => 'Client ID and user ID are required']);
            exit;
        }

        $sql = "SELECT * FROM transactions WHERE client_id = ? AND user_id = ? ORDER BY date DESC";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("ii", $client_id, $user_id);
        $stmt->execute();
        $result = $stmt->get_result();

        $transactions = [];
        while ($row = $result->fetch_assoc()) {
            $transactions[] = $row;
        }

        echo json_encode(['success' => true, 'transactions' => $transactions]);
        break;

    case 'POST':
        $data = json_decode(file_get_contents('php://input'), true);

        if (!isset($data['client_id']) || !isset($data['user_id']) || !isset($data['amount']) || !isset($data['type']) || !isset($data['description'])) {
            echo json_encode(['success' => false, 'message' => 'All fields are required']);
            exit;
        }

        $client_id = $data['client_id'];
        $user_id = $data['user_id'];
        $amount = $data['amount'];
        $type = $data['type'];
        $description = $data['description'];

        // Verify client_id belongs to user_id
        $check_sql = "SELECT id FROM clients WHERE id = ? AND user_id = ?";
        $check_stmt = $conn->prepare($check_sql);
        $check_stmt->bind_param("ii", $client_id, $user_id);
        $check_stmt->execute();
        $check_stmt->store_result();

        if ($check_stmt->num_rows === 0) {
            echo json_encode(['success' => false, 'message' => 'Client not found or unauthorized']);
            $check_stmt->close();
            exit;
        }
        $check_stmt->close();

        // Start transaction
        $conn->begin_transaction();

        try {
            // Insert transaction
            $sql_insert_transaction = "INSERT INTO transactions (client_id, user_id, amount, type, description) VALUES (?, ?, ?, ?, ?)";
            $stmt_insert_transaction = $conn->prepare($sql_insert_transaction);
            $stmt_insert_transaction->bind_param("iidss", $client_id, $user_id, $amount, $type, $description);
            $stmt_insert_transaction->execute();

            // Update client balance
            $balance_change = ($type == 'got') ? $amount : -$amount;
            $sql_update_client_balance = "UPDATE clients SET balance = balance + ? WHERE id = ?";
            $stmt_update_client_balance = $conn->prepare($sql_update_client_balance);
            $stmt_update_client_balance->bind_param("di", $balance_change, $client_id);
            $stmt_update_client_balance->execute();

            // Update user total balance
            $sql_update_user_total_balance = "UPDATE users SET total_balance = (SELECT SUM(balance) FROM clients WHERE user_id = ?) WHERE id = ?";
            $stmt_update_user_total_balance = $conn->prepare($sql_update_user_total_balance);
            $stmt_update_user_total_balance->bind_param("ii", $user_id, $user_id);
            $stmt_update_user_total_balance->execute();

            // Commit transaction
            $conn->commit();

            echo json_encode(['success' => true, 'message' => 'Transaction added successfully', 'transaction_id' => $conn->insert_id]);

        } catch (mysqli_sql_exception $exception) {
            $conn->rollback();
            echo json_encode(['success' => false, 'message' => 'Error adding transaction: ' . $exception->getMessage()]);
        }

        break;

    case 'DELETE':
        $data = json_decode(file_get_contents('php://input'), true);

        if (!isset($data['id']) || !isset($data['user_id'])) {
            echo json_encode(['success' => false, 'message' => 'Transaction ID and user ID are required']);
            exit;
        }

        $transaction_id = $data['id'];
        $user_id = $data['user_id'];

        // Get transaction details before deleting
        $sql_get_transaction = "SELECT client_id, amount, type FROM transactions WHERE id = ? AND user_id = ?";
        $stmt_get_transaction = $conn->prepare($sql_get_transaction);
        $stmt_get_transaction->bind_param("ii", $transaction_id, $user_id);
        $stmt_get_transaction->execute();
        $result_get_transaction = $stmt_get_transaction->get_result();

        if ($result_get_transaction->num_rows === 0) {
            echo json_encode(['success' => false, 'message' => 'Transaction not found or unauthorized']);
            exit;
        }

        $transaction = $result_get_transaction->fetch_assoc();
        $client_id = $transaction['client_id'];
        $amount = $transaction['amount'];
        $type = $transaction['type'];

        // Start transaction
        $conn->begin_transaction();

        try {
            // Delete transaction
            $sql_delete_transaction = "DELETE FROM transactions WHERE id = ? AND user_id = ?";
            $stmt_delete_transaction = $conn->prepare($sql_delete_transaction);
            $stmt_delete_transaction->bind_param("ii", $transaction_id, $user_id);
            $stmt_delete_transaction->execute();

            // Revert client balance update
            $balance_change = ($type == 'got') ? -$amount : $amount; // Reverse the change
            $sql_update_client_balance = "UPDATE clients SET balance = balance + ? WHERE id = ?";
            $stmt_update_client_balance = $conn->prepare($sql_update_client_balance);
            $stmt_update_client_balance->bind_param("di", $balance_change, $client_id);
            $stmt_update_client_balance->execute();

            // Update user total balance
            $sql_update_user_total_balance = "UPDATE users SET total_balance = (SELECT SUM(balance) FROM clients WHERE user_id = ?) WHERE id = ?";
            $stmt_update_user_total_balance = $conn->prepare($sql_update_user_total_balance);
            $stmt_update_user_total_balance->bind_param("ii", $user_id, $user_id);
            $stmt_update_user_total_balance->execute();

            // Commit transaction
            $conn->commit();

            echo json_encode(['success' => true, 'message' => 'Transaction deleted successfully']);

        } catch (mysqli_sql_exception $exception) {
            $conn->rollback();
            echo json_encode(['success' => false, 'message' => 'Error deleting transaction: ' . $exception->getMessage()]);
        }

        break;

    default:
        echo json_encode(["success" => false, "message" => "Method not allowed"]);
        break;
}

$conn->close();
?> 