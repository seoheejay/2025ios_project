<?php
header('Content-Type: application/json; charset=utf-8');
include 'db_connection.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $pkey = $_POST['pkey'] ?? '';
    $new_nickname = $_POST['new_nickname'] ?? '';

    if (empty($pkey) || empty($new_nickname)) {
        echo json_encode(["status" => "error", "message" => "필수 정보가 누락되었습니다."]);
        exit;
    }

    $check = $conn->prepare("SELECT pkey FROM users WHERE nickname = ?");
    $check->bind_param("s", $new_nickname);
    $check->execute();
    $result = $check->get_result();

    if ($result->num_rows > 0) {
        echo json_encode(["status" => "error", "message" => "이미 사용 중인 닉네임입니다."]);
        $check->close();
        exit;
    }
    $check->close();

    $stmt = $conn->prepare("UPDATE users SET nickname = ? WHERE pkey = ?");
    $stmt->bind_param("si", $new_nickname, $pkey);

    if ($stmt->execute()) {
        echo json_encode(["status" => "success", "message" => "닉네임이 성공적으로 변경되었습니다."]);
    } else {
        echo json_encode(["status" => "error", "message" => "닉네임 변경 중 오류가 발생했습니다."]);
    }

    $stmt->close();
}
$conn->close();
?>

