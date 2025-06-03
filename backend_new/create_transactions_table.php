<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

$servername = "localhost";
$username = "root";
$password = ""; // Your database password
$dbname = "flutter_auth_new"; // New database name

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die(json_encode(['success' => false, 'message' => 'Connection failed: ' . $conn->connect_error]));
}

// SQL to create transactions table
$sql = "CREATE TABLE IF NOT EXISTS transactions (
    id INT(11) AUTO_INCREMENT PRIMARY KEY,
    user_id INT(11) NOT NULL,
    client_id INT(11) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    type ENUM('got', 'given') NOT NULL,
    description TEXT,
    date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE
)";

if ($conn->query($sql) === TRUE) {
    echo json_encode(['success' => true, 'message' => 'Transactions table created successfully']);
} else {
    echo json_encode(['success' => false, 'message' => 'Error creating transactions table: ' . $conn->error]);
}

$conn->close();
?> 