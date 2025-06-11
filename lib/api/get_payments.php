<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json');
include 'db_config.php';

// Get client_id from GET or POST
$client_id = isset($_GET['client_id']) ? (int)$_GET['client_id'] : 0;

if ($client_id > 0) {
    $sql = "SELECT id, amount, payment_date, payment_type FROM payments WHERE client_id = $client_id ORDER BY payment_date DESC";
    $result = $conn->query($sql);

    $payments = [];

    if ($result->num_rows > 0) {
        while ($row = $result->fetch_assoc()) {
            $payments[] = $row;
        }
    }

    echo json_encode(["success" => true, "payments" => $payments]);
} else {
    echo json_encode(["success" => false, "message" => "Invalid client_id"]);
}

$conn->close();
?>
