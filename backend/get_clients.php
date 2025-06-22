<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *'); // IMPORTANT: For development, allow all origins. RESTRICT THIS IN PRODUCTION!
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle OPTIONS request for CORS preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$response = ['success' => false, 'message' => 'An unknown error occurred.', 'clients' => []];

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

// Fetch all clients from the 'clients' table including mobile_number and amount
$sql = "SELECT id, name, mobile_number, amount, last_transaction_date FROM clients ORDER BY name ASC";
$result = $conn->query($sql);

if ($result) {
    $clients = [];
    if ($result->num_rows > 0) {
        while ($row = $result->fetch_assoc()) {
            $clients[] = $row;
        }
    }
    $response['success'] = true;
    $response['message'] = "Clients fetched successfully.";
    $response['clients'] = $clients;
} else {
    $response['message'] = "Error fetching clients: " . $conn->error;
}

$conn->close();

echo json_encode($response);
?>
