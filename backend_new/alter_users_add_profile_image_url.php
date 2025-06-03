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

// SQL to add profile_image_url column if it doesn't exist
$sql = "ALTER TABLE users ADD COLUMN profile_image_url VARCHAR(255) DEFAULT NULL";

if ($conn->query($sql) === TRUE) {
    echo "Column 'profile_image_url' added to table 'users' successfully.";
} else {
    // Check if the error is because the column already exists
    if ($conn->errno == 1060) {
        echo "Column 'profile_image_url' already exists in table 'users'. No changes made.";
    } else {
        echo "Error altering table: " . $conn->error;
    }
}

$conn->close();
?> 