<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json');

$servername = "localhost";
$username = "root";
$password = ""; // Your database password
$dbname = "flutter_auth_new"; // New database name

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    die(json_encode(['success' => false, 'message' => 'Connection failed: ' . $conn->connect_error]));
}

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['username']) || !isset($data['password'])) {
    echo json_encode(['success' => false, 'message' => 'Username and password are required']);
    exit;
}

$username = $conn->real_escape_string($data['username']);
$password = password_hash($data['password'], PASSWORD_DEFAULT); // Hash the password

// Check if username already exists
$check_sql = "SELECT id FROM users WHERE username = ?";
$check_stmt = $conn->prepare($check_sql);
$check_stmt->bind_param("s", $username);
$check_stmt->execute();
$check_stmt->store_result();

if ($check_stmt->num_rows > 0) {
    echo json_encode(['success' => false, 'message' => 'Username already exists']);
    $check_stmt->close();
    exit;
}

$check_stmt->close();

// Insert new user
$sql = "INSERT INTO users (username, password) VALUES (?, ?)";
$stmt = $conn->prepare($sql);
$stmt->bind_param("ss", $username, $password);

if ($stmt->execute()) {
    echo json_encode(['success' => true, 'message' => 'User registered successfully', 'user_id' => $conn->insert_id]);
} else {
    echo json_encode(['success' => false, 'message' => 'Error registering user: ' . $conn->error]);
}

$conn->close();
?> 