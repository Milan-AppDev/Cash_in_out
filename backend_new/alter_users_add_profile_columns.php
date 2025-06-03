<?php
header('Content-Type: text/plain'); // Use plain text for output of this script

$servername = "localhost";
$username = "root";
$password = "";
$dbname = "flutter_auth_new"; // Your database name

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

$alterations = [
    'address' => 'VARCHAR(255) DEFAULT NULL',
    'gender' => 'VARCHAR(10) DEFAULT NULL',
    'email' => 'VARCHAR(255) DEFAULT NULL UNIQUE (email(191))',
    'city' => 'VARCHAR(100) DEFAULT NULL',
    'state' => 'VARCHAR(100) DEFAULT NULL',
    'date_of_birth' => 'DATE DEFAULT NULL',
];

$messages = [];

foreach ($alterations as $columnName => $columnDefinition) {
    $sql = "ALTER TABLE users ADD COLUMN $columnName $columnDefinition";

    if ($conn->query($sql) === TRUE) {
        $messages[] = "Column '$columnName' added to table 'users' successfully.";
    } else {
        // Check if the error is because the column already exists
        if ($conn->errno == 1060) {
            $messages[] = "Column '$columnName' already exists in table 'users'. No changes made.";
        } else {
            $messages[] = "Error altering table (column '$columnName'): " . $conn->error;
        }
    }
}

$conn->close();

foreach ($messages as $msg) {
    echo $msg . "\n";
}
?> 