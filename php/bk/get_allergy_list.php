<?php
header("Content-Type: application/json; charset=utf-8");
require_once "db_connection.php";

$sql = "SELECT allergy_id AS id, allergy_name, 0 AS checked FROM allergy ORDER BY allergy_id ASC";
$result = $conn->query($sql);

$items = [];
while ($row = $result->fetch_assoc()) {
    $items[] = $row;
}

echo json_encode([
    "status" => "success",
    "allergy" => $items
], JSON_UNESCAPED_UNICODE);

$conn->close();
?>

