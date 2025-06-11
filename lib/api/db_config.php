<?php
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "cash_in_out"; // <-- Change this to your actual database name in phpMyAdmin

$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}
