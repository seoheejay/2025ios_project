<?php
header("Content-Type: application/json; charset=utf-8");
require_once "db_connection.php";

$user_id = isset($_POST['user_id']) ? intval($_POST['user_id']) : 0;

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
    WHERE r.user_id = ?
    ORDER BY r.created_at DESC
";

$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $user_id);
$stmt->execute();
$result = $stmt->get_result();

$reviews = [];
while ($row = $result->fetch_assoc()) {
    $reviews[] = $row;
}

echo json_encode(["review" => $reviews], JSON_UNESCAPED_UNICODE);

$stmt->close();
$conn->close();
?>

