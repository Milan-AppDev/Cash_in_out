<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json');

include 'db_config.php';

$data = json_decode(file_get_contents('php://input'));

// Try to get mobile from JSON or fallback to POST
$mobile = null;
if (isset($data->mobile)) {
    $mobile = $data->mobile;
} elseif (isset($_POST['mobile'])) {
    $mobile = $_POST['mobile'];
}

if (!$mobile) {
    echo json_encode(['success' => false, 'message' => 'Mobile number required']);
    exit;
}

$mobile = $conn->real_escape_string($mobile);
$otp = rand(100000, 999999);
$created_at = date('Y-m-d H:i:s');

// Create OTP table if not exists
$conn->query("CREATE TABLE IF NOT EXISTS mobile_otps (
    id INT AUTO_INCREMENT PRIMARY KEY,
    mobile VARCHAR(20) NOT NULL,
    otp VARCHAR(10) NOT NULL,
    created_at DATETIME NOT NULL
)");

// Remove old OTPs for this mobile
$conn->query("DELETE FROM mobile_otps WHERE mobile='$mobile'");

// Insert new OTP
$sql = "INSERT INTO mobile_otps (mobile, otp, created_at) VALUES ('$mobile', '$otp', '$created_at')";
if ($conn->query($sql) === TRUE) {
    echo json_encode(['success' => true, 'otp' => $otp, 'message' => 'OTP generated (for testing, see response)']);
} else {
    echo json_encode(['success' => false, 'message' => 'Failed to generate OTP']);
}
$conn->close();
