<?php
header("Content-Type: application/json; charset=UTF-8");
require_once "db_connection.php";

$user_id = $_POST['user_id'] ?? null;
$allergy_ids = $_POST['allergy_ids'] ?? "";  // "1,2,3"

if (!$user_id) {
    echo json_encode(["status" => "error", "message" => "user_id 없음"], JSON_UNESCAPED_UNICODE);
    exit;
}

// 기존 삭제
$del = $conn->prepare("DELETE FROM user_allergy WHERE user_id = ?");
$del->bind_param("i", $user_id);
$del->execute();

// 새롭게 저장
if (!empty($allergy_ids)) {
    $ids = explode(",", $allergy_ids);

    $sql = "INSERT INTO user_allergy (user_id, allergy_id, status, created_at)
            VALUES (?, ?, 1, NOW())";
    $stmt = $conn->prepare($sql);

    foreach ($ids as $aid) {
        $aid = intval($aid);
        $stmt->bind_param("ii", $user_id, $aid);
        $stmt->execute();
    }
}

echo json_encode([
    "status" => "success",
    "message" => "알레르기 정보가 저장되었습니다."
], JSON_UNESCAPED_UNICODE);

$conn->close();
?>

