<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

$servername = "localhost";
$username = "root";
$password = ""; // Your database password
$dbname = "flutter_auth_new"; // Your database name

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die(json_encode(['success' => false, 'message' => 'Connection failed: ' . $conn->connect_error]));
}

// SQL to add total_balance column to users table
$sql = "ALTER TABLE users ADD COLUMN total_balance DECIMAL(10, 2) DEFAULT 0.00";

if ($conn->query($sql) === TRUE) {
    echo json_encode(['success' => true, 'message' => 'Total_balance column added to users table successfully or already exists']);
} else {
    echo json_encode(['success' => false, 'message' => 'Error adding total_balance column: ' . $conn->error]);
}

$conn->close();
?> 