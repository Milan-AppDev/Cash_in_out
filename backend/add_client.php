<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *'); // IMPORTANT: For development, allow all origins. RESTRICT THIS IN PRODUCTION!
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle OPTIONS request for CORS preflight (important for modern browsers)
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$response = ['success' => false, 'message' => 'An unknown error occurred.'];

// Database connection details (REPLACE WITH YOUR ACTUAL DETAILS)
$servername = "localhost";
$username = "root"; // Your MySQL username
$password = "";     // Your MySQL password
$dbname = "cash_in_out"; // The name of your database

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    $response['message'] = "Database connection failed: " . $conn->connect_error;
    echo json_encode($response);
    exit();
}

// Get the POST data
$json_data = file_get_contents("php://input");
$data = json_decode($json_data, true);

// Validate input
if (!isset($data['name']) || empty(trim($data['name']))) {
    $response['message'] = "Client name is required.";
    echo json_encode($response);
    $conn->close();
    exit();
}

if (!isset($data['mobile_number']) || empty(trim($data['mobile_number']))) {
    $response['message'] = "Mobile number is required.";
    echo json_encode($response);
    $conn->close();
    exit();
}

$name = trim($data['name']);
$mobile_number = trim($data['mobile_number']);

// Basic mobile number validation (optional, but good practice)
if (!preg_match('/^[0-9]{10}$/', $mobile_number)) {
    $response['message'] = "Invalid mobile number format. Must be 10 digits.";
    echo json_encode($response);
    $conn->close();
    exit();
}

// Check if mobile number already exists to prevent duplicates
$check_stmt = $conn->prepare("SELECT id FROM clients WHERE mobile_number = ?");
if ($check_stmt === false) {
    $response['message'] = "Failed to prepare check statement: " . $conn->error;
    echo json_encode($response);
    $conn->close();
    exit();
}
$check_stmt->bind_param("s", $mobile_number);
$check_stmt->execute();
$check_stmt->store_result();

if ($check_stmt->num_rows > 0) {
    $response['message'] = "A client with this mobile number already exists.";
    echo json_encode($response);
    $check_stmt->close();
    $conn->close();
    exit();
}
$check_stmt->close();


// Insert new client with default amount 0.00 and current date
// Use prepared statements to prevent SQL injection
$stmt = $conn->prepare("INSERT INTO clients (name, mobile_number, amount, last_transaction_date) VALUES (?, ?, ?, CURDATE())");

if ($stmt === false) {
    $response['message'] = "Failed to prepare insert statement: " . $conn->error;
    echo json_encode($response);
    $conn->close();
    exit();
}

$default_amount = 0.00; // New clients start with a 0 balance
$stmt->bind_param("ssd", $name, $mobile_number, $default_amount); // 's' for string, 's' for string, 'd' for double

if ($stmt->execute()) {
    $response['success'] = true;
    $response['message'] = "Client '$name' added successfully!";
} else {
    $response['message'] = "Error adding client: " . $stmt->error;
}

$stmt->close();
$conn->close();

echo json_encode($response);
?>
