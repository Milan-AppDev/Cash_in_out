<?php
// get_transactions.php
// Allow requests from any origin (for development)
header("Access-Control-Allow-Origin: *");
// Allow specific methods like GET, POST, OPTIONS
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
// Allow specific headers
header("Access-Control-Allow-Headers: Origin, Content-Type, Accept");
header('Content-Type: application/json'); // Tell client we're sending JSON

require 'db.php'; // Include your database connection file

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $client_id = $_GET['client_id'] ?? null;

    if (empty($client_id)) {
        echo json_encode([
            'success' => false,
            'message' => 'Client ID is required.'
        ]);
        exit();
    }

    try {
        $stmt = $pdo->prepare("SELECT * FROM transactions WHERE client_id = ? ORDER BY transaction_date DESC, created_at DESC");
        $stmt->execute([$client_id]);
        $transactions = $stmt->fetchAll();

        echo json_encode([
            'success' => true,
            'transactions' => $transactions
        ]);

    } catch (\PDOException $e) {
        // Log the error for debugging
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