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
    // Log connection error
    error_log("Database Connection failed: " . $conn->connect_error);
    die(json_encode(["success" => false, "message" => "Database Connection failed"]));
}

// Read the raw POST data
$raw_data = file_get_contents("php://input");
error_log("Received raw data: " . $raw_data);

// Decode the JSON data
$data = json_decode($raw_data, true);

// Log the decoded data and potential JSON errors
if ($data === null && json_last_error() !== JSON_ERROR_NONE) {
    $json_error = json_last_error_msg();
    error_log("JSON Decode Error: " . $json_error);
    echo json_encode(["success" => false, "message" => "Invalid JSON received: " . $json_error]);
    exit();
} else if ($data === null) {
     error_log("JSON Decode resulted in null (possibly empty body)");
     // Proceed to check for required fields, which will fail and send the required message
}

error_log("Decoded data: " . print_r($data, true));

if (!isset($data['username']) || !isset($data['password'])) {
    error_log("Missing username or password in decoded data.");
    echo json_encode(["success" => false, "message" => "Username and password are required"]);
    exit();
}

$username = $conn->real_escape_string($data['username']);
$password = $conn->real_escape_string($data['password']);

// Hash the password
$hashed_password = password_hash($password, PASSWORD_DEFAULT);
error_log("Processing signup for user: " . $username);

// Check if username already exists
$sql = "SELECT id FROM users WHERE username = ?";
$stmt = $conn->prepare($sql);

if (!$stmt) {
    error_log("Prepare statement failed: " . $conn->error);
    echo json_encode(["success" => false, "message" => "Database error during preparation."]);
    exit();
}

$stmt->bind_param("s", $username);
$stmt->execute();
$stmt->store_result();

if ($stmt->num_rows > 0) {
    error_log("Signup failed: Username already exists - " . $username);
    echo json_encode(["success" => false, "message" => "Username already exists"]);
} else {
    // Insert new user
    $sql = "INSERT INTO users (username, password) VALUES (?, ?)";
    $stmt_insert = $conn->prepare($sql);

    if (!$stmt_insert) {
         error_log("Prepare insert statement failed: " . $conn->error);
         echo json_encode(["success" => false, "message" => "Database error during insertion preparation."]);
         exit();
    }

    $stmt_insert->bind_param("ss", $username, $hashed_password);

    if ($stmt_insert->execute()) {
        error_log("User registered successfully: " . $username);
        echo json_encode(["success" => true, "message" => "User registered successfully"]);
    } else {
        error_log("Error inserting user: " . $stmt_insert->error);
        echo json_encode(["success" => false, "message" => "Error registering user."]);
    }
    $stmt_insert->close();
}

$stmt->close();
$conn->close();
?> 