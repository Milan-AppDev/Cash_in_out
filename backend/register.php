<?php
// register.php
header("Access-Control-Allow-Origin: *");
// Allow specific methods like GET, POST, OPTIONS
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
// Allow specific headers
header("Access-Control-Allow-Headers: Origin, Content-Type, Accept");
header('Content-Type: application/json'); // Tell client we're sending JSON// Inform client that response is JSON
require 'db.php'; // Include database connection - Make sure db_connect.php is in the same directory!

$response = array(); // Initialize response array

// Check if the request method is POST
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Get the raw JSON data from the request body
    $json_data = file_get_contents("php://input");
    $data = json_decode($json_data, true); // Decode JSON into an associative array

    $email = $data['email'] ?? '';    // Get email from JSON, default to empty string if not set
    $password = $data['password'] ?? ''; // Get password from JSON, default to empty string if not set

    // Basic server-side validation
    if (empty($email) || empty($password)) {
        $response['success'] = false;
        $response['message'] = 'Email and password are required.';
    } elseif (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        $response['success'] = false;
        $response['message'] = 'Invalid email format.';
    } else {
        // Hash the password using a strong, recommended algorithm (BCRYPT)
        // This is crucial for security: NEVER store plain text passwords!
        $hashed_password = password_hash($password, PASSWORD_BCRYPT);

        try {
            // Prepare an SQL INSERT statement using PDO for security (prevents SQL injection)
            $stmt = $pdo->prepare("INSERT INTO users (email, password) VALUES (:email, :password)");

            // Bind parameters to the prepared statement
            $stmt->bindParam(':email', $email);
            $stmt->bindParam(':password', $hashed_password);

            // Execute the statement
            if ($stmt->execute()) {
                $response['success'] = true;
                $response['message'] = 'Registration successful!';
                $response['userId'] = $pdo->lastInsertId(); // Get the ID of the newly created user
            } else {
                $response['success'] = false;
                $response['message'] = 'Registration failed. Please try again.';
            }
        } catch (PDOException $e) {
            // Check for specific error code for duplicate entry (e.g., email already exists)
            // SQLSTATE 23000 indicates integrity constraint violation, often a unique key violation
            if ($e->getCode() == '23000') {
                $response['success'] = false;
                $response['message'] = 'Email already registered.';
            } else {
                // Generic database error message for other issues
                $response['success'] = false;
                $response['message'] = 'Database error: ' . $e->getMessage();
            }
        }
    }
} else {
    // If request method is not POST, return an error
    $response['success'] = false;
    $response['message'] = 'Invalid request method. Only POST is allowed.';
}

echo json_encode($response); // Output the response as JSON
?>