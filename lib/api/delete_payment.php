<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json');
include 'db_config.php';

$data = json_decode(file_get_contents("php://input"));

if (isset($data->payment_id)) {
    $payment_id = (int)$data->payment_id;

    $sql = "DELETE FROM payments WHERE id = $payment_id";

    if ($conn->query($sql) === TRUE) {
        echo json_encode(["success" => true, "message" => "Payment deleted successfully"]);
    } else {
        echo json_encode(["success" => false, "message" => "Error: " . $conn->error]);
    }
} else {
    echo json_encode(["success" => false, "message" => "Invalid input"]);
}

$conn->close();
?>
