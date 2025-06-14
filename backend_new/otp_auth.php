<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json');

$servername = "localhost";
$username = "root";
$password = "";
$dbname = "flutter_auth_new";

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    die(json_encode(['success' => false, 'message' => 'Connection failed: ' . $conn->connect_error]));
}

$data = json_decode(file_get_contents('php://input'), true);
$action = isset($data['action']) ? $data['action'] : '';

switch ($action) {
    case 'generate_otp':
        if (!isset($data['mobile_number'])) {
            echo json_encode(['success' => false, 'message' => 'Mobile number is required']);
            exit;
        }

        $mobile_number = $conn->real_escape_string($data['mobile_number']);
        
        // Generate a 6-digit OTP
        $otp = str_pad(rand(0, 999999), 6, '0', STR_PAD_LEFT);
        
        // Set OTP expiry to 5 minutes from now
        $otp_expiry = date('Y-m-d H:i:s', strtotime('+5 minutes'));

        // Check if user exists
        $check_sql = "SELECT id FROM users WHERE mobile_number = ?";
        $check_stmt = $conn->prepare($check_sql);
        $check_stmt->bind_param("s", $mobile_number);
        $check_stmt->execute();
        $result = $check_stmt->get_result();

        if ($result->num_rows === 0) {
            // Create new user
            $sql = "INSERT INTO users (mobile_number, otp, otp_expiry) VALUES (?, ?, ?)";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("sss", $mobile_number, $otp, $otp_expiry);
        } else {
            // Update existing user's OTP
            $sql = "UPDATE users SET otp = ?, otp_expiry = ? WHERE mobile_number = ?";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("sss", $otp, $otp_expiry, $mobile_number);
        }

        if ($stmt->execute()) {
            // In a real application, you would send the OTP via SMS here
            // For development, we'll just return it in the response
            echo json_encode([
                'success' => true,
                'message' => 'OTP generated successfully',
                'otp' => $otp // Remove this in production
            ]);
        } else {
            echo json_encode(['success' => false, 'message' => 'Error generating OTP']);
        }
        break;

    case 'verify_otp':
        if (!isset($data['mobile_number']) || !isset($data['otp'])) {
            echo json_encode(['success' => false, 'message' => 'Mobile number and OTP are required']);
            exit;
        }

        $mobile_number = $conn->real_escape_string($data['mobile_number']);
        $otp = $conn->real_escape_string($data['otp']);

        // Debugging: Get current server time for comparison
        $current_server_time_sql = "SELECT NOW()";
        $current_server_time_result = $conn->query($current_server_time_sql);
        if ($current_server_time_result === false) {
            error_log("OTP Debug: SQL Error fetching NOW(): " . $conn->error);
            echo json_encode(['success' => false, 'message' => 'Internal server error (time fetch)']);
            exit;
        }
        $current_server_time = $current_server_time_result->fetch_row()[0];

        // Debugging: Get stored OTP and expiry for the given mobile number
        $debug_sql = "SELECT otp, otp_expiry FROM users WHERE mobile_number = ?";
        $debug_stmt = $conn->prepare($debug_sql);
        $debug_stmt->bind_param("s", $mobile_number);
        $debug_stmt->execute();
        $debug_result = $debug_stmt->get_result();
        $debug_user_data = $debug_result->fetch_assoc();
        $debug_stmt->close();

        // Log or print debug information to Apache error log
        error_log("OTP Debug: Mobile Number: $mobile_number, Entered OTP: $otp");
        error_log("OTP Debug: Stored OTP: " . ($debug_user_data['otp'] ?? 'N/A') . ", Stored OTP Expiry: " . ($debug_user_data['otp_expiry'] ?? 'N/A'));
        error_log("OTP Debug: Current Server Time (NOW()): $current_server_time");

        $sql = "SELECT id FROM users WHERE mobile_number = ? AND otp = ? AND otp_expiry > NOW()";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("ss", $mobile_number, $otp);
        $stmt->execute();
        $result = $stmt->get_result();

        if ($result->num_rows === 1) {
            $user = $result->fetch_assoc();
            // Clear OTP after successful verification
            $update_sql = "UPDATE users SET otp = NULL, otp_expiry = NULL WHERE id = ?";
            $update_stmt = $conn->prepare($update_sql);
            $update_stmt->bind_param("i", $user['id']);
            $update_stmt->execute();

            echo json_encode([
                'success' => true,
                'message' => 'OTP verified successfully',
                'user_id' => $user['id']
            ]);
        } else {
            echo json_encode(['success' => false, 'message' => 'Invalid or expired OTP']);
        }
        break;

    default:
        echo json_encode(['success' => false, 'message' => 'Invalid action']);
}

$conn->close();
?> 