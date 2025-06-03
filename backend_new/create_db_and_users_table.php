<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

$servername = "localhost";
$username = "root";
$password = ""; // Your database password
$dbname = "flutter_auth_new"; // New database name

// Create connection
$conn = new mysqli($servername, $username, $password);

// Check connection
if ($conn->connect_error) {
    die(json_encode(['success' => false, 'message' => 'Connection failed: ' . $conn->connect_error]));
}

// Create database if it does not exist
$sql_create_db = "CREATE DATABASE IF NOT EXISTS $dbname";
if ($conn->query($sql_create_db) === TRUE) {
    // Connect to the new database
    $conn->select_db($dbname);

    // SQL to create users table
    $sql_create_table = "CREATE TABLE IF NOT EXISTS users (\n
        id INT(11) AUTO_INCREMENT PRIMARY KEY,\n
        username VARCHAR(191) NOT NULL UNIQUE,\n
        password VARCHAR(255) NOT NULL,\n
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP\n
    )";

    if ($conn->query($sql_create_table) === TRUE) {
        echo json_encode(['success' => true, 'message' => 'Database and users table created successfully']);
    } else {
        echo json_encode(['success' => false, 'message' => 'Error creating users table: ' . $conn->error]);
    }
} else {
    echo json_encode(['success' => false, 'message' => 'Error creating database: ' . $conn->error]);
}

$conn->close();
?> 