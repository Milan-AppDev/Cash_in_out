<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json');
include 'db_config.php';

// Get user_id from POST or GET
$user_id = isset($_POST['user_id']) ? (int)$_POST['user_id'] : (isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0);

if ($user_id > 0) {
    $stmt = $conn->prepare("SELECT id, name, phone, address FROM clients WHERE user_id = ?");
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $result = $stmt->get_result();

    $clients = [];

    while ($row = $result->fetch_assoc()) {
        $clients[] = $row;
    }

    echo json_encode(["success" => true, "clients" => $clients]);

    $stmt->close();
} else {
    echo json_encode(["success" => false, "message" => "Invalid user_id"]);
}

$conn->close();
?>
