
<?php
header("Content-Type: application/json");
include 'db_config.php';

// Get user_id from GET or POST
$user_id = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;

if ($user_id > 0) {
    $sql = "SELECT id, name, phone, address FROM clients WHERE user_id = $user_id";
    $result = $conn->query($sql);

    $clients = [];

    if ($result->num_rows > 0) {
        while ($row = $result->fetch_assoc()) {
            $clients[] = $row;
        }
    }

    echo json_encode(["success" => true, "clients" => $clients]);
} else {
    echo json_encode(["success" => false, "message" => "Invalid user_id"]);
}

$conn->close();
?>
