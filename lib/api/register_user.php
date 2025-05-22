<?php
header("Content-Type: application/json");
include 'db_config.php';

// Get POST data
$data = json_decode(file_get_contents("php://input"));

if (
    isset($data->name) && 
    isset($data->email) && 
    isset($data->password)
) {
    $name = $conn->real_escape_string($data->name);
    $email = $conn->real_escape_string($data->email);
    $password = password_hash($data->password, PASSWORD_DEFAULT);

    // Check if user already exists
    $check = $conn->query("SELECT id FROM users WHERE email = '$email'");
    if ($check->num_rows > 0) {
        echo json_encode(["success" => false, "message" => "Email already registered"]);
    } else {
        $sql = "INSERT INTO users (name, email, password) VALUES ('$name', '$email', '$password')";
        if ($conn->query($sql) === TRUE) {
            echo json_encode(["success" => true, "message" => "Registration successful"]);
        } else {
            echo json_encode(["success" => false, "message" => "Error: " . $conn->error]);
        }
    }
} else {
    echo json_encode(["success" => false, "message" => "Invalid input"]);
}

$conn->close();
?>
