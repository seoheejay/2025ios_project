<?php
header("Content-Type: application/json; charset=utf-8");
require_once "db_connection.php";

$review_id = isset($_POST['review_id']) ? intval($_POST['review_id']) : 0;

$sql = "
    SELECT
        r.review_id,
        r.user_id,
        r.menu_id,
        r.order_item_id,
        r.rating,
        r.title,
        r.content,
        r.price,
        r.status,
        r.created_at,
        r.updated_at,

        o.order_date,
        m.menu_name

    FROM review r
    LEFT JOIN order_item oi ON r.order_item_id = oi.order_item_id
    LEFT JOIN `order` o ON oi.order_id = o.order_id
    LEFT JOIN menu m ON r.menu_id = m.menu_id
    WHERE r.review_id = ?
";

$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $review_id);
$stmt->execute();
$result = $stmt->get_result();

if ($row = $result->fetch_assoc()) {
    echo json_encode([
        "status" => "success",
        "data" => $row
    ], JSON_UNESCAPED_UNICODE);
} else {
    echo json_encode([
        "status" => "error",
        "message" => "리뷰를 찾을 수 없습니다."
    ], JSON_UNESCAPED_UNICODE);
}

$stmt->close();
$conn->close();
?>

