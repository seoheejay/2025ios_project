<?php
header('Content-Type: application/json; charset=utf-8');
include 'db_connection.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $nickname = $_POST['nickname'] ?? '';

    if (empty($nickname)) {
        echo json_encode(["status" => "error", "message" => "닉네임이 비어 있습니다."]);
        exit;
    }

    $stmt = $conn->prepare("SELECT pkey FROM users WHERE nickname = ?");
    $stmt->bind_param("s", $nickname);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        echo json_encode(["status" => "unavailable", "message" => "이미 사용 중인 닉네임입니다."]);
    } else {
        echo json_encode(["status" => "available", "message" => "사용 가능한 닉네임입니다."]);
    }

    $stmt->close();
}
$conn->close();
?>

