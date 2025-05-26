<?php
header("Access-Control-Allow-Origin: *"); 
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

// Function to return JSON response
function sendResponse($success, $message) {
    echo json_encode(["success" => $success, "message" => $message]);
    exit;
}

// Allow only POST method
if ($_SERVER["REQUEST_METHOD"] !== "POST") {
    sendResponse(false, "Invalid request method");
}

// Get raw body and decode JSON
$rawData = file_get_contents("php://input");
$data = json_decode($rawData, true);

// Fallback to $_POST if not JSON
$username = isset($data['username']) ? $data['username'] : ($_POST['username'] ?? '');
$password = isset($data['password']) ? $data['password'] : ($_POST['password'] ?? '');

// Sanitize input
$username = trim($username);
$password = trim($password);

// Validation
if (empty($username) || empty($password)) {
    sendResponse(false, "Username and password are required");
}

if (strlen($password) > 8) {
    sendResponse(false, "Password must be at least 8 characters");
}

// DB credentials
$host = "localhost";
$db_user = "root";
$db_pass = "";
$db_name = "flutter_auth";

// Connect to database
$conn = new mysqli($host, $db_user, $db_pass, $db_name);
if ($conn->connect_error) {
    sendResponse(false, "Connection failed: " . $conn->connect_error);
}

// Check if username already exists
$checkUser = "SELECT * FROM users WHERE username = ?";
$stmt = $conn->prepare($checkUser);
$stmt->bind_param("s", $username);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    sendResponse(false, "Username already exists");
}

// Hash password and insert user
$hashedPassword = password_hash($password, PASSWORD_DEFAULT);
$insertStmt = $conn->prepare("INSERT INTO users (username, password) VALUES (?, ?)");
$insertStmt->bind_param("ss", $username, $hashedPassword);

if ($insertStmt->execute()) {
    sendResponse(true, "User registered successfully");
} else {
    sendResponse(false, "Error: " . $conn->error);
}

$conn->close();
?>
