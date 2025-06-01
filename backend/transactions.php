<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

// Enable error reporting
error_reporting(E_ALL);
ini_set('display_errors', 1);

$host = "localhost";
$user = "root";
$password = "";
$db = "flutter_auth";

$conn = new mysqli($host, $user, $password, $db);

if ($conn->connect_error) {
    die(json_encode(["success" => false, "message" => "Connection failed: " . $conn->connect_error]));
}

// Create transactions table if it doesn't exist
$sql = "CREATE TABLE IF NOT EXISTS transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    client_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    description TEXT NOT NULL,
    type ENUM('got', 'give') NOT NULL,
    date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE
)";

if (!$conn->query($sql)) {
    die(json_encode(["success" => false, "message" => "Error creating table: " . $conn->error]));
}

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
    case 'GET':
        if (isset($_GET['client_id'])) {
            $client_id = $conn->real_escape_string($_GET['client_id']);
            $sql = "SELECT * FROM transactions WHERE client_id = ? ORDER BY date DESC";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("i", $client_id);
            $stmt->execute();
            $result = $stmt->get_result();
            
            $transactions = [];
            while ($row = $result->fetch_assoc()) {
                $transactions[] = $row;
            }
            
            echo json_encode([
                "success" => true,
                "transactions" => $transactions
            ]);
        } else {
            echo json_encode(["success" => false, "message" => "Client ID is required"]);
        }
        break;

    case 'POST':
        $data = json_decode(file_get_contents("php://input"), true);
        
        if (!isset($data['client_id']) || !isset($data['amount']) || !isset($data['description']) || !isset($data['type'])) {
            echo json_encode(["success" => false, "message" => "Missing required fields"]);
            exit();
        }

        $client_id = $conn->real_escape_string($data['client_id']);
        $amount = $conn->real_escape_string($data['amount']);
        $description = $conn->real_escape_string($data['description']);
        $type = $conn->real_escape_string($data['type']);

        // Validate type
        if ($type !== 'got' && $type !== 'give') {
            echo json_encode(["success" => false, "message" => "Invalid transaction type"]);
            exit();
        }

        $sql = "INSERT INTO transactions (client_id, amount, description, type) VALUES (?, ?, ?, ?)";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("idss", $client_id, $amount, $description, $type);

        if ($stmt->execute()) {
            error_log("Transaction inserted successfully for client ID: " . $client_id);
            // Update client's balance
            $balance_change = $type === 'got' ? $amount : -$amount;
            $update_sql = "UPDATE clients SET balance = balance + ? WHERE id = ?";
            $update_stmt = $conn->prepare($update_sql);
            $update_stmt->bind_param("di", $balance_change, $client_id);
            
            if ($update_stmt->execute()) {
                error_log("Client balance updated successfully for client ID: " . $client_id . " with change: " . $balance_change);
            } else {
                error_log("Error updating client balance for client ID: " . $client_id . ": " . $update_stmt->error);
            }

            echo json_encode([
                "success" => true,
                "message" => "Transaction added successfully",
                "transaction_id" => $conn->insert_id
            ]);
        } else {
            echo json_encode(["success" => false, "message" => "Error adding transaction: " . $conn->error]);
        }
        break;

    default:
        echo json_encode(["success" => false, "message" => "Method not allowed"]);
        break;
}

$conn->close();
?> 