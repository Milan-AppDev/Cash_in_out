<?php
// add_transaction.php
// Allow requests from any origin (for development)
header("Access-Control-Allow-Origin: *");
// Allow specific methods like GET, POST, OPTIONS
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
// Allow specific headers
header("Access-Control-Allow-Headers: Origin, Content-Type, Accept");
header('Content-Type: application/json'); // Tell client we're sending JSON

require 'db.php';// Include your database connection file

$data = json_decode(file_get_contents("php://input"), true);

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $client_id = $data['client_id'] ?? null;
    $amount = $data['amount'] ?? null;
    $description = $data['description'] ?? null;
    $category = $data['category'] ?? 'Other'; // Default category if not provided
    $transaction_date = $data['transaction_date'] ?? null;
    $type = $data['type'] ?? null; // 'got' or 'given'

    // Validate input
    if (empty($client_id) || empty($amount) || empty($transaction_date) || empty($type)) {
        echo json_encode([
            'success' => false,
            'message' => 'Missing required fields: client_id, amount, transaction_date, type.'
        ]);
        exit();
    }

    if (!is_numeric($amount) || $amount <= 0) {
        echo json_encode([
            'success' => false,
            'message' => 'Amount must be a positive number.'
        ]);
        exit();
    }

    if (!in_array($type, ['got', 'given'])) {
        echo json_encode([
            'success' => false,
            'message' => 'Invalid transaction type. Must be "got" or "given".'
        ]);
        exit();
    }

    try {
        $stmt = $pdo->prepare("INSERT INTO transactions (client_id, amount, description, category, transaction_date, type) VALUES (?, ?, ?, ?, ?, ?)");
        $stmt->execute([$client_id, $amount, $description, $category, $transaction_date, $type]);

        if ($stmt->rowCount() > 0) {
            echo json_encode([
                'success' => true,
                'message' => 'Transaction added successfully.'
            ]);
        } else {
            echo json_encode([
                'success' => false,
                'message' => 'Failed to add transaction.'
            ]);
        }
    } catch (\PDOException $e) {
        // Log the error for debugging (e.g., error_log($e->getMessage());)
        echo json_encode([
            'success' => false,
            'message' => 'Database error: ' . $e->getMessage()
        ]);
    }
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Invalid request method.'
    ]);
}
?>