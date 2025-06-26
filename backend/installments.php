<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");

$host = "localhost";
$user = "root";
$password = "";
$db = "flutter_auth";

$conn = new mysqli($host, $user, $password, $db);
if ($conn->connect_error) {
    echo json_encode(["success" => false, "message" => "Connection failed"]);
    exit();
}

$method = $_SERVER['REQUEST_METHOD'];

// ====================== POST: Create a Plan + Monthly Installments ======================
if ($method === 'POST') {
    $data = json_decode(file_get_contents("php://input"), true);

    if (!isset($data['client_id'], $data['amount'], $data['months'], $data['start_date'])) {
        echo json_encode(["success" => false, "message" => "Missing fields"]);
        exit();
    }

    $client_id = intval($data['client_id']);
    $amount = floatval($data['amount']);
    $months = intval($data['months']);
    $start_date = new DateTime($data['start_date']);
    $monthly_amount = round($amount / $months, 2);

    // Insert into installment_plans
    $planStmt = $conn->prepare("INSERT INTO installment_plans (client_id, total_amount, months, start_date) VALUES (?, ?, ?, ?)");
    $planStmt->bind_param("iids", $client_id, $amount, $months, $data['start_date']);
    $planStmt->execute();

    if ($planStmt->error) {
        echo json_encode(["success" => false, "message" => "Plan insert failed: " . $planStmt->error]);
        exit();
    }

    $plan_id = $planStmt->insert_id;

    // Insert monthly installments
    $stmt = $conn->prepare("INSERT INTO installments (plan_id, month_year, amount, status) VALUES (?, ?, ?, 'Pending')");
    for ($i = 0; $i < $months; $i++) {
        $monthYear = $start_date->format('Y-m');
        $stmt->bind_param("isd", $plan_id, $monthYear, $monthly_amount);
        $stmt->execute();
        $start_date->modify('+1 month');
    }

    echo json_encode(["success" => true, "message" => "Installment plan created"]);
    exit;
}

// ====================== GET: Fetch Plans or Monthly Installments ======================
if ($method === 'GET') {
    $type = $_GET['type'] ?? null;

    // ✅ Fetch installment plans (all or filtered by client)
    if ($type === 'plans') {
        if (isset($_GET['client_id'])) {
            $client_id = intval($_GET['client_id']);
            $stmt = $conn->prepare("SELECT * FROM installment_plans WHERE client_id = ?");
            $stmt->bind_param("i", $client_id);
        } else {
            $stmt = $conn->prepare("SELECT * FROM installment_plans");
        }

        $stmt->execute();
        $result = $stmt->get_result();

        $plans = [];
        while ($row = $result->fetch_assoc()) {
            $plans[] = $row;
        }

        echo json_encode(["success" => true, "data" => $plans]);
        exit;
    }

    // ✅ Fetch monthly installments by plan_id
    if ($type === 'installments' && isset($_GET['plan_id'])) {
        $plan_id = intval($_GET['plan_id']);
        $stmt = $conn->prepare("SELECT * FROM installments WHERE plan_id = ?");
        $stmt->bind_param("i", $plan_id);
        $stmt->execute();

        $result = $stmt->get_result();
        $installments = [];

        while ($row = $result->fetch_assoc()) {
            $installments[] = $row;
        }

        echo json_encode(["success" => true, "data" => $installments]);
        exit;
    }

    // ✅ Fetch pending installments by client_id (for AddPaymentPage)
    if ($type === 'pending' && isset($_GET['client_id'])) {
        $client_id = intval($_GET['client_id']);
        $stmt = $conn->prepare("
            SELECT i.id, i.month_year, i.amount 
            FROM installments i
            JOIN installment_plans p ON i.plan_id = p.id
            WHERE i.status = 'Pending' AND p.client_id = ?
            ORDER BY i.month_year ASC
        ");
        $stmt->bind_param("i", $client_id);
        $stmt->execute();

        $result = $stmt->get_result();
        $pending = [];

        while ($row = $result->fetch_assoc()) {
            $pending[] = $row;
        }

        echo json_encode(["success" => true, "data" => $pending]);
        exit;
    }

    echo json_encode(["success" => false, "message" => "Invalid GET request"]);
    exit;
}

echo json_encode(["success" => false, "message" => "Invalid request method"]);
$conn->close();
