<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");
header("Content-Type: application/json");

// Get the POST body
$input = json_decode(file_get_contents('php://input'), true);

if (!isset($input['mobile']) || !isset($input['otp'])) {
    echo json_encode([
        "success" => false,
        "message" => "Mobile number and OTP required"
    ]);
    exit;
}

$mobile = $input['mobile'];
$otp = $input['otp'];

// For testing, always return success
// In a real app, you would check the OTP against a database or session
$response = [
    "success" => true,
    "user" => [
        "name" => "Test User",
        "phone" => $mobile,
        "id" => 1
    ]
];

echo json_encode($response);
?>
