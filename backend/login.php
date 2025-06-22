<?php
// login.php
// Allow requests from any origin (for development)
header("Access-Control-Allow-Origin: *");
// Allow specific methods like GET, POST, OPTIONS
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
// Allow specific headers
header("Access-Control-Allow-Headers: Origin, Content-Type, Accept");
header('Content-Type: application/json'); // Tell client we're sending JSON
require 'db.php'; // Include the database connection file

$response = array(); // Initialize response array

// Check if the request method is POST
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Get raw POST data
    $json_data = file_get_contents("php://input");
    $data = json_decode($json_data, true); // Decode JSON into associative array

    $email = $data['email'] ?? '';
    $password = $data['password'] ?? '';

    if (empty($email) || empty($password)) {
        $response['success'] = false;
        $response['message'] = 'Email and password are required.';
    } else {
        try {
            // Prepare the SQL statement to select user by email
            $stmt = $pdo->prepare("SELECT id, email, password FROM users WHERE email = :email");
            $stmt->bindParam(':email', $email);
            $stmt->execute();

            $user = $stmt->fetch(PDO::FETCH_ASSOC); // Fetch the user row

            if ($user) {
                // Verify the submitted password against the hashed password from the database
                if (password_verify($password, $user['password'])) {
                    $response['success'] = true;
                    $response['message'] = 'Login successful!';
                    $response['user'] = array(
                        'id' => $user['id'],
                        'email' => $user['email']
                    );
                } else {
                    $response['success'] = false;
                    $response['message'] = 'Invalid credentials.'; // Generic message for security
                }
            } else {
                $response['success'] = false;
                $response['message'] = 'Invalid credentials.'; // Generic message for security
            }
        } catch (PDOException $e) {
            $response['success'] = false;
            $response['message'] = 'Database error: ' . $e->getMessage();
        }
    }
} else {
    $response['success'] = false;
    $response['message'] = 'Invalid request method. Only POST is allowed.';
}

echo json_encode($response); // Output the JSON response
?>