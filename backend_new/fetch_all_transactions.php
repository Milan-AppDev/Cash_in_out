<?php
header('Content-Type: application/json');

// Database connection parameters
$servername = "localhost";
$username = "root"; // Replace with your database username
$password = ""; // Replace with your database password
$dbname = "flutter_auth_new"; // Replace with your database name

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    // Output JSON error response instead of HTML
    echo json_encode(['success' => false, 'message' => 'Database Connection failed: ' . $conn->connect_error]);
    exit();
}

// Get parameters from the request
$userId = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;
$clientId = isset($_GET['client_id']) ? intval($_GET['client_id']) : 0;
$startDate = isset($_GET['start_date']) ? $_GET['start_date'] : null;
$endDate = isset($_GET['end_date']) ? $_GET['end_date'] : null;

// Check if user_id is provided
if ($userId <= 0) {
    echo json_encode(['success' => false, 'message' => 'User ID not provided']);
    exit();
}

$transactions = [];
$clientBalance = 0.0;
$clientTotalGot = 0.0;
$clientTotalGiven = 0.0;

// Build the base SQL query for transactions
$sqlTransactions = "SELECT t.id, t.client_id, t.type, t.amount, t.description, t.date, c.name as client_name
                    FROM transactions t
                    JOIN clients c ON t.client_id = c.id
                    WHERE c.user_id = ?";

// Build the SQL query for client-specific summaries if client_id is provided
$sqlClientSummary = "";
if ($clientId > 0) {
    $sqlTransactions .= " AND t.client_id = ?";
    $sqlClientSummary = "SELECT
                              SUM(CASE WHEN type = 'got' THEN amount ELSE 0 END) as total_got,
                              SUM(CASE WHEN type = 'given' THEN amount ELSE 0 END) as total_given,
                              SUM(CASE WHEN type = 'got' THEN amount ELSE -amount END) as balance
                           FROM transactions
                           WHERE client_id = ?";
}

// Add date range conditions if provided
if ($startDate !== null) {
    $sqlTransactions .= " AND DATE(t.date) >= ?";
}
if ($endDate !== null) {
    $sqlTransactions .= " AND DATE(t.date) <= ?";
}

// Add ordering
$sqlTransactions .= " ORDER BY t.date DESC";

// Prepare and execute the SQL statement for transactions
$stmtTransactions = $conn->prepare($sqlTransactions);

if ($stmtTransactions === false) {
    echo json_encode(['success' => false, 'message' => 'Database query prepare failed (transactions): ' . $conn->error]);
    exit();
}

// Bind parameters for transactions dynamically
$paramTypesTransactions = 'i'; // 'i' for user_id
$paramsTransactions = [&$userId];

if ($clientId > 0) {
    $paramTypesTransactions .= 'i'; // 'i' for client_id
    $paramsTransactions[] = &$clientId;
}
if ($startDate !== null) {
    $paramTypesTransactions .= 's'; // 's' for string date
    $paramsTransactions[] = &$startDate;
}
if ($endDate !== null) {
    $paramTypesTransactions .= 's'; // 's' for string date
    $paramsTransactions[] = &$endDate;
}

call_user_func_array([$stmtTransactions, 'bind_param'], array_merge([$paramTypesTransactions], $paramsTransactions));

$stmtTransactions->execute();
$resultTransactions = $stmtTransactions->get_result();

if ($resultTransactions) {
    while ($row = $resultTransactions->fetch_assoc()) {
        $transactions[] = $row;
    }
} else {
    echo json_encode(['success' => false, 'message' => 'Failed to fetch transactions: ' . $stmtTransactions->error]);
    $stmtTransactions->close();
    $conn->close();
    exit();
}

// Fetch client summary if client_id is provided
if ($clientId > 0 && $sqlClientSummary !== "") {
    $stmtClientSummary = $conn->prepare($sqlClientSummary);

    if ($stmtClientSummary === false) {
        echo json_encode(['success' => false, 'message' => 'Database query prepare failed (client summary): ' . $conn->error]);
        $stmtTransactions->close();
        $conn->close();
        exit();
    }

    $stmtClientSummary->bind_param('i', $clientId);
    $stmtClientSummary->execute();
    $resultClientSummary = $stmtClientSummary->get_result();

    if ($resultClientSummary && $row = $resultClientSummary->fetch_assoc()) {
        $clientBalance = $row['balance'] ?? 0.0;
        $clientTotalGot = $row['total_got'] ?? 0.0;
        $clientTotalGiven = $row['total_given'] ?? 0.0;
    } else {
        // Handle error or no summary found
        // Continue with transactions if possible, maybe log a warning
        error_log("Could not fetch client summary for client ID: " . $clientId); // Log warning
    }
    $stmtClientSummary->close();
}

$stmtTransactions->close();
$conn->close();

// Prepare the final response data
$responseData = ['success' => true, 'transactions' => $transactions];

// Add client summary data if fetched
if ($clientId > 0) {
    $responseData['client_balance'] = $clientBalance;
    $responseData['client_total_got'] = $clientTotalGot;
    $responseData['client_total_given'] = $clientTotalGiven;
}

echo json_encode($responseData);