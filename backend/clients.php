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

// Note: The transactions table should be created by accessing backend/transactions.php
// Note: The users table should be created by accessing backend/create_users_table.php
// Note: The clients table should be created by accessing backend/create_clients_table.php

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
    case 'GET':
        // Get all clients with calculated balance from transactions
        $sql = "SELECT ";
        $sql .= "c.id, c.name, c.phone, ";
        $sql .= "SUM(CASE WHEN t.type = 'got' THEN t.amount ELSE -t.amount END) AS balance ";
        $sql .= "FROM clients c ";
        $sql .= "LEFT JOIN transactions t ON c.id = t.client_id ";
        $sql .= "GROUP BY c.id, c.name, c.phone ";
        $sql .= "ORDER BY c.created_at DESC";
        
        $result = $conn->query($sql);
        
        if ($result) {
            $clients = [];
            while ($row = $result->fetch_assoc()) {
                // Handle case where a client has no transactions (balance will be null from SUM)
                $row['balance'] = $row['balance'] ?? 0.00;
                $clients[] = $row;
            }
            echo json_encode(["success" => true, "clients" => $clients]);
        } else {
            echo json_encode(["success" => false, "message" => "Error fetching clients: " . $conn->error]);
        }
        break;

    case 'POST':
        // Add new client
        $raw_data = file_get_contents("php://input");
        $data = json_decode($raw_data, true);
        
        if (!isset($data['name']) || !isset($data['phone'])) {
            echo json_encode(["success" => false, "message" => "Name and phone are required"]);
            break;
        }

        $name = $conn->real_escape_string($data['name']);
        $phone = $conn->real_escape_string($data['phone']);
        // Initial balance will always be 0 for a new client based on transactions
        $balance = 0.00;

        $sql = "INSERT INTO clients (name, phone, balance) VALUES (?, ?, ?)";
        $stmt = $conn->prepare($sql);
        
        if (!$stmt) {
             echo json_encode(["success" => false, "message" => "Prepare failed: " . $conn->error]);
            break;
        }

        $stmt->bind_param("ssd", $name, $phone, $balance);

        if ($stmt->execute()) {
            echo json_encode([
                "success" => true,
                "message" => "Client added successfully",
                "id" => $conn->insert_id
            ]);
        } else {
            echo json_encode(["success" => false, "message" => "Error adding client: " . $stmt->error]);
        }
        break;

    case 'PUT':
        // Update client (excluding balance, which is calculated)
        $raw_data = file_get_contents("php://input");
        $data = json_decode($raw_data, true);
        
        if (!isset($data['id'])) {
            echo json_encode(["success" => false, "message" => "Client ID is required"]);
            break;
        }

        $id = intval($data['id']);
        $updates = [];
        $types = "";
        $values = [];

        if (isset($data['name'])) {
            $updates[] = "name = ?";
            $types .= "s";
            $values[] = $data['name'];
        }
        if (isset($data['phone'])) {
            $updates[] = "phone = ?";
            $types .= "s";
            $values[] = $data['phone'];
        }
        // Do not update balance directly here, it's calculated from transactions

        if (empty($updates)) {
            echo json_encode(["success" => false, "message" => "No fields to update"]);
            break;
        }

        $sql = "UPDATE clients SET " . implode(", ", $updates) . " WHERE id = ?";
        $types .= "i";
        $values[] = $id;

        $stmt = $conn->prepare($sql);
         if (!$stmt) {
             echo json_encode(["success" => false, "message" => "Prepare failed: " . $conn->error]);
            break;
        }
        $stmt->bind_param($types, ...$values);

        if ($stmt->execute()) {
            echo json_encode(["success" => true, "message" => "Client updated successfully"]);
        } else {
             echo json_encode(["success" => false, "message" => "Error updating client: " . $stmt->error]);
        }
        break;

    case 'DELETE':
        // Delete client
        $raw_data = file_get_contents("php://input");
        $data = json_decode($raw_data, true);
        
        if (!isset($data['id'])) {
            echo json_encode(["success" => false, "message" => "Client ID is required"]);
            break;
        }

        $id = intval($data['id']);
        $sql = "DELETE FROM clients WHERE id = ?";
        $stmt = $conn->prepare($sql);
         if (!$stmt) {
             echo json_encode(["success" => false, "message" => "Prepare failed: " . $conn->error]);
            break;
        }
        $stmt->bind_param("i", $id);

        if ($stmt->execute()) {
            echo json_encode(["success" => true, "message" => "Client deleted successfully"]);
        } else {
             echo json_encode(["success" => false, "message" => "Error deleting client: " . $stmt->error]);
        }
        break;

    default:
        echo json_encode(["success" => false, "message" => "Method not allowed"]);
        break;
}

$conn->close();
?> 