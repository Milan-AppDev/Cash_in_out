<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json");
include 'db_config.php';

$data = json_decode(file_get_contents("php://input"));

if (
    isset($data->client_id) &&
    isset($data->name) &&
    isset($data->phone) &&
    isset($data->address)
) {
    $client_id = (int)$data->client_id;
    $name = $conn->real_escape_string($data->name);
    $phone = $conn->real_escape_string($data->phone);
    $address = $conn->real_escape_string($data->address);

    $sql = "UPDATE clients SET name='$name', phone='$phone', address='$address' WHERE id = $client_id";

    if ($conn->query($sql) === TRUE) {
        echo json_encode(["success" => true, "message" => "Client updated successfully"]);
    } else {
        echo json_encode(["success" => false, "message" => "Error: " . $conn->error]);
    }
} else {
    echo json_encode(["success" => false, "message" => "Invalid input"]);
}

$conn->close();
?>
