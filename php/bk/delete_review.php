<?php
header("Content-Type: application/json; charset=utf-8");
require_once "db_connection.php";

$review_id = isset($_POST['review_id']) ? intval($_POST['review_id']) : 0;

if ($review_id <= 0) {
    echo json_encode(["status" => "error", "message" => "잘못된 review_id"], JSON_UNESCAPED_UNICODE);
    exit;
}

$sql = "DELETE FROM review WHERE review_id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $review_id);

if ($stmt->execute()) {
    echo json_encode(["status" => "success", "message" => "리뷰가 삭제되었습니다
."], JSON_UNESCAPED_UNICODE);
} else {
    echo json_encode(["status" => "error", "message" => "삭제 실패"], JSON_UNESCAPED_UNICODE);
}

$stmt->close();
$conn->close();
?>

