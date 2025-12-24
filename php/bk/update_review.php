<?php
header("Content-Type: application/json; charset=utf-8");
require_once "db_connection.php";

$review_id = isset($_POST['review_id']) ? intval($_POST['review_id']) : 0;
$title     = isset($_POST['title']) ? trim($_POST['title']) : "";
$content   = isset($_POST['content']) ? trim($_POST['content']) : "";
$rating    = isset($_POST['rating']) ? floatval($_POST['rating']) : 0;

if ($review_id <= 0) {
    echo json_encode(["status" => "error", "message" => "잘못된 review_id"]);
    exit;
}

$sql = "
    UPDATE review
    SET title = ?, content = ?, rating = ?, updated_at = NOW()
    WHERE review_id = ?
";

$stmt = $conn->prepare($sql);
$stmt->bind_param("ssdi", $title, $content, $rating, $review_id);

if ($stmt->execute()) {
    echo json_encode(["status" => "success", "message" => "리뷰가 수정되었습니다."], JSON_UNESCAPED_UNICODE);
} else {
    echo json_encode(["status" => "error", "message" => "리뷰 수정 실패"], JSON_UNESCAPED_UNICODE);

$stmt->close();
$conn->close();
}

