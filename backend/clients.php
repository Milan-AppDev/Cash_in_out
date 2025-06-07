<?php
header('Content-Type: application/json');
$host = "localhost";
$user = "root";
$password = "";
$db = "flutter_auth";

$conn = new mysqli($host, $user, $password, $db);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database connection failed']);
    exit;
}

$method = $_SERVER['REQUEST_METHOD'];

// Helper function to get input JSON for PUT/POST
function getInputData() {
    return json_decode(file_get_contents('php://input'), true);
}

switch ($method) {
    case 'GET':
        // Fetch all clients or by id if provided as query param
        if (isset($_GET['id'])) {
            $id = $_GET['id'];
            $stmt = $conn->prepare("SELECT * FROM clients WHERE id = ?");
            $stmt->bind_param("i", $id);
        } else {
            $stmt = $conn->prepare("SELECT * FROM clients");
        }
        $stmt->execute();
        $result = $stmt->get_result();
        $clients = $result->fetch_all(MYSQLI_ASSOC);
        echo json_encode(['success' => true, 'data' => $clients]);
        break;

    case 'POST':
        // Add new client
        $data = getInputData();
        if (!isset($data['name'], $data['phone'], $data['address'])) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Missing required fields']);
            exit;
        }
        $name = $data['name'];
        $phone = $data['phone'];
        $address = $data['address'];

        $stmt = $conn->prepare("INSERT INTO clients (name, phone, address) VALUES (?, ?, ?)");
        $stmt->bind_param("sss", $name, $phone, $address);
        if ($stmt->execute()) {
            echo json_encode(['success' => true, 'message' => 'Client added successfully', 'id' => $stmt->insert_id]);
        } else {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Failed to add client']);
        }
        break;

    case 'PUT':
        // Update client
        $data = getInputData();
        if (!isset($data['id'], $data['name'], $data['phone'], $data['address'])) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Missing required fields']);
            exit;
        }
        $id = $data['id'];
        $name = $data['name'];
        $phone = $data['phone'];
        $address = $data['address'];

        $stmt = $conn->prepare("UPDATE clients SET name = ?, phone = ?, address = ? WHERE id = ?");
        $stmt->bind_param("sssi", $name, $phone, $address, $id);
        if ($stmt->execute()) {
            echo json_encode(['success' => true, 'message' => 'Client updated successfully']);
        } else {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Failed to update client']);
        }
        break;

    case 'DELETE':
        // Delete client by id passed as query param
        if (!isset($_GET['id'])) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Missing client ID']);
            exit;
        }
        $id = $_GET['id'];
        $stmt = $conn->prepare("DELETE FROM clients WHERE id = ?");
        $stmt->bind_param("i", $id);
        if ($stmt->execute()) {
            echo json_encode(['success' => true, 'message' => 'Client deleted successfully']);
        } else {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Failed to delete client']);
        }
        break;

    default:
        http_response_code(405);
        echo json_encode(['success' => false, 'message' => 'Method not allowed']);
        break;
}

$conn->close();
?>
