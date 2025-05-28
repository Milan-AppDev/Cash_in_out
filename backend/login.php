<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

// Enable error reporting
error_reporting(E_ALL);
ini_set('display_errors', 1);

$host = "localhost";
$user = "root";
$password = "";
$db = "flutter_auth";

$conn = new mysqli($host, $user, $password, $db);

if ($conn->connect_error) {
    die(json_encode(["success" => false, "message" => "Connection failed: " . $conn->connect_error]));
}

$data = json_decode(file_get_contents("php://input"), true);

// Add logging
error_log("Received raw data: " . file_get_contents("php://input"));
error_log("Decoded data: " . print_r($data, true));

if (!isset($data['username']) || !isset($data['password'])) {
    error_log("Missing username or password in decoded data.");
    echo json_encode(["success" => false, "message" => "Username and password are required"]);
    exit();
}

$username = $conn->real_escape_string($data['username']);
$password = $conn->real_escape_string($data['password']);

// Retrieve user from database
$sql = "SELECT id, password FROM users WHERE username = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $username);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 1) {
    $user = $result->fetch_assoc();
    // Verify password
    if (password_verify($password, $user['password'])) {
        echo json_encode(["success" => true, "message" => "Login successful", "user_id" => $user['id']]);
    } else {
        echo json_encode(["success" => false, "message" => "Incorrect password"]);
    }
} else {
    echo json_encode(["success" => false, "message" => "User not found"]);
}

$stmt->close();
$conn->close();
?> 