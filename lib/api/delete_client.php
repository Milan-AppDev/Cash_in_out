<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json");
include 'db_config.php';

$data = json_decode(file_get_contents("php://input"));

if (isset($data->client_id)) {
    $client_id = (int)$data->client_id;

    $conn->query("DELETE FROM payments WHERE client_id = $client_id");

    $sql = "DELETE FROM clients WHERE id = $client_id";

    if ($conn->query($sql) === TRUE) {
        echo json_encode(["success" => true, "message" => "Client deleted successfully"]);
    } else {
        echo json_encode(["success" => false, "message" => "Error: " . $conn->error]);
    }
} else {
    echo json_encode(["success" => false, "message" => "Invalid input"]);
}

$conn->close();
?>
