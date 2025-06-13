<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

// Turn off error messages as HTML
// DEBUG: Show all errors (remove in production)
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

$host = "localhost";
$user = "root";
$password = "";
$db = "flutter_auth"; // your DB

$conn = new mysqli($host, $user, $password, $db);
if ($conn->connect_error) {
    echo json_encode(["success" => false, "message" => "Connection failed", "error" => $conn->connect_error]);
    exit();
}

// Handle POST: INSERT payment
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $json = file_get_contents("php://input");
    $data = json_decode($json, true);

    if (!$data) {
        echo json_encode(["success" => false, "message" => "Invalid JSON", "raw" => $json]);
        exit();
    }

    // Validate
    $required = ['client_id', 'amount', 'timestamp', 'tag', 'note', 'status'];
    foreach ($required as $field) {
        if (!isset($data[$field])) {
            echo json_encode(["success" => false, "message" => "Missing field: $field"]);
            exit();
        }
    }

    $client_id = intval($data['client_id']);
    $amount = floatval($data['amount']);
    $timestamp = $data['timestamp'];  // ISO 8601 string
    $tag = $data['tag'];
    $note = $data['note'];
    $status = $data['status'];

$stmt = $conn->prepare("INSERT INTO payments (client_id, amount, timestamp, tag, note, status) VALUES (?, ?, ?, ?, ?, ?)");
    if (!$stmt) {
        echo json_encode(["success" => false, "message" => "Prepare failed", "error" => $conn->error]);
        exit();
    }

$stmt->bind_param("idssss", $client_id, $amount, $timestamp, $tag, $note, $status);
    $success = $stmt->execute();

    if ($success) {
        echo json_encode(["success" => true, "message" => "Payment added"]);
    } else {
        echo json_encode(["success" => false, "message" => "Insert failed", "error" => $stmt->error]);
    }

    $stmt->close();
    $conn->close();
    exit();
}

// Else: GET request — return list
$result = $conn->query("SELECT * FROM payments ORDER BY timestamp DESC");

$data = [];
while ($row = $result->fetch_assoc()) {
    $data[] = $row;
}

echo json_encode(["success" => true, "data" => $data]);
$conn->close();
?>
