<?php
header("Content-Type: application/json");
include 'db_config.php';

// Get POST data
$data = json_decode(file_get_contents("php://input"));

if (
    isset($data->user_id) &&
    isset($data->name) &&
    isset($data->phone) &&
    isset($data->address)
) {
    $user_id = (int)$data->user_id;
    $name = $conn->real_escape_string($data->name);
    $phone = $conn->real_escape_string($data->phone);
    $address = $conn->real_escape_string($data->address);

    $sql = "INSERT INTO clients (user_id, name, phone, address) 
            VALUES ($user_id, '$name', '$phone', '$address')";

    if ($conn->query($sql) === TRUE) {
        echo json_encode(["success" => true, "message" => "Client added successfully"]);
    } else {
        echo json_encode(["success" => false, "message" => "Error: " . $conn->error]);
    }
} else {
    echo json_encode(["success" => false, "message" => "Invalid input"]);
}

$conn->close();
?>
