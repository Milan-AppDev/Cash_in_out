<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json');
include 'db_config.php';

$data = json_decode(file_get_contents("php://input"));

if (
    isset($data->payment_id) &&
    isset($data->amount) &&
    isset($data->payment_date) &&
    isset($data->payment_type)
) {
    $payment_id = (int)$data->payment_id;
    $amount = (float)$data->amount;
    $payment_date = $conn->real_escape_string($data->payment_date);
    $payment_type = $conn->real_escape_string($data->payment_type);

    $sql = "UPDATE payments SET amount=$amount, payment_date='$payment_date', payment_type='$payment_type' WHERE id = $payment_id";

    if ($conn->query($sql) === TRUE) {
        echo json_encode(["success" => true, "message" => "Payment updated successfully"]);
    } else {
        echo json_encode(["success" => false, "message" => "Error: " . $conn->error]);
    }
} else {
    echo json_encode(["success" => false, "message" => "Invalid input"]);
}

$conn->close();
?>
