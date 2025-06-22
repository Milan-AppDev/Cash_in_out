<?php
// db_connect.php

// Database configuration
$host = 'localhost'; // Your database host (usually 'localhost' for local development)
$dbname = 'cash_in_out'; // The name of the database you created
$user = 'root'; // Your MySQL username (default is 'root' for XAMPP/WAMP)
$pass = ''; // Your MySQL password (default is empty for XAMPP/WAMP)

try {
    // Create a new PDO instance
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $user, $pass);

    // Set the PDO error mode to exception
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    // Set default fetch mode to associative array
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);

    // echo "Connected successfully to the database!"; // For testing connection
} catch (PDOException $e) {
    // If connection fails, output error and exit
    echo "Connection failed: " . $e->getMessage();
    exit(); // Stop script execution
}
?>