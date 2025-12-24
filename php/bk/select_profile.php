<?php
header('Content-Type: application/json; charset=utf-8');
include 'db_connection.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $pkey = $_POST['pkey'] ?? '';

    if (empty($pkey)) {
        echo json_encode(["status" => "error", "message" => "pkey 값이 누락되었습니다."]);
        exit;
    }

    $stmt = $conn->prepare("SELECT name, student_id, nickname FROM users WHERE pkey = ?");
    $stmt->bind_param("i", $pkey);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($row = $result->fetch_assoc()) {
        echo json_encode([
            "status" => "success",
            "name" => $row['name'],
            "studentId" => $row['student_id'],
            "nickname" => $row['nickname']
        ]);
    } else {
        echo json_encode(["status" => "error", "message" => "사용자 정보를 찾을 수 없습니다."]);
    }

    $stmt->close();
}
$conn->close();
?>

