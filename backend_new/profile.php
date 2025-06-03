<?php
header('Content-Type: application/json');

$servername = "localhost";
$username = "root";
$password = "";
$dbname = "flutter_auth_new"; // Your database name

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die(json_encode(['success' => false, 'message' => "Connection failed: " . $conn->connect_error]));
}

// Handle GET request to fetch profile data
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    if (isset($_GET['user_id'])) {
        $userId = $_GET['user_id'];

        // Select all profile columns
        $sql = "SELECT username, phone, profile_image_url, address, gender, email, city, state, date_of_birth FROM users WHERE id = ? LIMIT 1";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("i", $userId);
        $stmt->execute();
        $result = $stmt->get_result();

        if ($result->num_rows > 0) {
            $user = $result->fetch_assoc();
            // Include all columns in the JSON response
            echo json_encode([
                'success' => true,
                'username' => $user['username'] ?? null,
                'phone' => $user['phone'] ?? null,
                'profile_image_url' => $user['profile_image_url'] ?? null,
                'address' => $user['address'] ?? null,
                'gender' => $user['gender'] ?? null,
                'email' => $user['email'] ?? null,
                'city' => $user['city'] ?? null,
                'state' => $user['state'] ?? null,
                'date_of_birth' => $user['date_of_birth'] ?? null, // Date will be a string
            ]);
        } else {
            echo json_encode(['success' => false, 'message' => 'User not found.']);
        }

        $stmt->close();
    } else {
        echo json_encode(['success' => false, 'message' => 'User ID not provided.']);
    }
} elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Handle POST request for updating profile (including image upload)

    // Check if the request is for image upload (multipart/form-data)
    if (isset($_FILES['profile_image'])) {
        $userId = $_POST['user_id'] ?? null;
        // For image upload, other fields might also be in $_POST
        $phone = $_POST['phone'] ?? null;
        $address = $_POST['address'] ?? null;
        $gender = $_POST['gender'] ?? null;
        $email = $_POST['email'] ?? null;
        $city = $_POST['city'] ?? null;
        $state = $_POST['state'] ?? null;
        $dateOfBirth = $_POST['date_of_birth'] ?? null;

    } else {
         // If not image upload, assume application/json
        $json_data = file_get_contents('php://input');
        $data = json_decode($json_data, true);

        $userId = $data['user_id'] ?? null;
        $phone = $data['phone'] ?? null;
        $address = $data['address'] ?? null;
        $gender = $data['gender'] ?? null;
        $email = $data['email'] ?? null;
        $city = $data['city'] ?? null;
        $state = $data['state'] ?? null;
        $dateOfBirth = $data['date_of_birth'] ?? null;
        $profileImageUrl = null; // Image upload is handled in the multipart section
    }

    if ($userId === null) {
        echo json_encode(['success' => false, 'message' => 'User ID not provided.']);
        $conn->close();
        exit();
    }

     // Handle image upload if present
    $profileImageUrl = null;
    if (isset($_FILES['profile_image']) && $_FILES['profile_image']['error'] === UPLOAD_ERR_OK) {
        $uploadDir = 'uploads/profiles/'; // Directory relative to backend_new
        $fileName = uniqid() . '_' . basename($_FILES['profile_image']['name']);
        $uploadFile = $uploadDir . $fileName;

        // Create the directory if it doesn't exist
        if (!is_dir($uploadDir)) {
            mkdir($uploadDir, 0777, true);
        }

        if (move_uploaded_file($_FILES['profile_image']['tmp_name'], $uploadFile)) {
            $profileImageUrl = $uploadFile; // Path to save in database
        } else {
            echo json_encode(['success' => false, 'message' => 'Failed to upload image.']);
            $conn->close();
            exit();
        }
    }

    // Build the UPDATE query dynamically based on provided fields
    $updateFields = [];
    $params = [];
    $types = "";

    // Add fields from JSON data (or $_POST for image upload)
    if ($phone !== null) { $updateFields[] = "phone = ?"; $params[] = $phone; $types .= "s"; }
    if ($email !== null) { $updateFields[] = "email = ?"; $params[] = $email; $types .= "s"; }
    if ($address !== null) { $updateFields[] = "address = ?"; $params[] = $address; $types .= "s"; }
    if ($gender !== null) { $updateFields[] = "gender = ?"; $params[] = $gender; $types .= "s"; }
    if ($city !== null) { $updateFields[] = "city = ?"; $params[] = $city; $types .= "s"; }
    if ($state !== null) { $updateFields[] = "state = ?"; $params[] = $state; $types .= "s"; }
    if ($dateOfBirth !== null) { $updateFields[] = "date_of_birth = ?"; $params[] = $dateOfBirth; $types .= "s"; }

    // Add profile image URL to update fields if a new image was uploaded
    if ($profileImageUrl !== null) { $updateFields[] = "profile_image_url = ?"; $params[] = $profileImageUrl; $types .= "s"; }

    // Only proceed with update if there are fields to update
    if (!empty($updateFields)) {
        $sql = "UPDATE users SET " . implode(", ", $updateFields) . " WHERE id = ?";
        $params[] = $userId;
        $types .= "i";

        $stmt = $conn->prepare($sql);
        // Use the spread operator to pass the parameters to bind_param
        // Ensure the number of parameters matches the number of types
        if (count($params) != strlen($types)) {
             echo json_encode(['success' => false, 'message' => 'Parameter count mismatch.']);
             $stmt->close();
             $conn->close();
             exit();
        }
        $stmt->bind_param($types, ...$params);

        if ($stmt->execute()) {
             // Fetch the updated user data to return in the response
            $fetchSql = "SELECT username, phone, profile_image_url, address, gender, email, city, state, date_of_birth FROM users WHERE id = ? LIMIT 1";
            $fetchStmt = $conn->prepare($fetchSql);
            $fetchStmt->bind_param("i", $userId);
            $fetchStmt->execute();
            $fetchResult = $fetchStmt->get_result();
            $updatedUser = $fetchResult->fetch_assoc();

            echo json_encode([
                'success' => true,
                'message' => 'Profile updated successfully.',
                'user' => [
                    'username' => $updatedUser['username'] ?? null,
                    'phone' => $updatedUser['phone'] ?? null,
                    'profile_image_url' => $updatedUser['profile_image_url'] ?? null,
                    'address' => $updatedUser['address'] ?? null,
                    'gender' => $updatedUser['gender'] ?? null,
                    'email' => $updatedUser['email'] ?? null,
                    'city' => $updatedUser['city'] ?? null,
                    'state' => $updatedUser['state'] ?? null,
                    'date_of_birth' => $updatedUser['date_of_birth'] ?? null,
                ]
            ]);

            $fetchStmt->close();

        } else {
            echo json_encode(['success' => false, 'message' => 'Failed to update profile: ' . $conn->error]);
        }
        $stmt->close();
    } else {
        echo json_encode(['success' => false, 'message' => 'No data provided for update.']);
    }
}

$conn->close();
?> 