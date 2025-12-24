<?php
header("Content-Type: application/json; charset=UTF-8");
require_once "db_connection.php";

$user_id = $_POST['user_id'] ?? null;

if (!$user_id) {
    echo json_encode(["status" => "error", "message" => "user_id 없음"], JSON_UNESCAPED_UNICODE);
    exit;
}

$sql = "SELECT allergy_id FROM user_allergy WHERE user_id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $user_id);
stmt->execute();
$result = $stmt->get_result();

$list = [];
while ($row = $result->fetch_assoc()) {
    $list[] = $row;
}

echo json_encode([
    "status" => "success",
    "list" => $list
], JSON_UNESCAPED_UNICODE);

$stmt->close();
$conn->close();
?>

