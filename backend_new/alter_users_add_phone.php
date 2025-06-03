<?php
header('Content-Type: text/plain'); // Use plain text for output of this script

$servername = "localhost";
$username = "root";
$password = "";
$dbname = "flutter_auth_new"; // Your database name

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// SQL to add phone column if it doesn't exist
$sql = "ALTER TABLE users ADD COLUMN phone VARCHAR(20) DEFAULT NULL";

if ($conn->query($sql) === TRUE) {
    echo "Column 'phone' added to table 'users' successfully.";
} else {
    // Check if the error is because the column already exists
    if ($conn->errno == 1060) {
        echo "Column 'phone' already exists in table 'users'. No changes made.";
    } else {
        echo "Error altering table: " . $conn->error;
    }
}

$conn->close();
?> 