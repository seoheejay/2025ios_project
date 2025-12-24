<?php

error_reporting(E_ALL);


header('Content-Type: application/json; charset=utf-8');
mysqli_report(MYSQLI_REPORT_OFF); 


ob_start();

$mysqli = new mysqli("localhost", "brant", "0505", "ykt"); 
$mysqli->set_charset("utf8mb4");

if ($mysqli->connect_errno) {
    ob_clean(); 
    echo json_encode(["error" => "DB 연결 실패: " . $mysqli->connect_error]);
    exit;
}

$userId = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;
if ($userId <= 0) {
    ob_clean();
    echo json_encode([]);
    exit;
}


$sqlOrders = "
    SELECT 
        o.order_id,
        o.order_date,
        o.receipt_number,
        SUM(oi.price * oi.quantity) AS total_price
    FROM `order` o
    JOIN `order_item` oi ON oi.order_id = o.order_id
    WHERE o.user_id = ? AND o.status != 5
    GROUP BY o.order_id
    ORDER BY o.order_date DESC
";

$stmt = $mysqli->prepare($sqlOrders);
if (!$stmt) {
    ob_clean();
    echo json_encode(["error" => "쿼리 준비 실패(Orders): " . $mysqli->error]);
    exit;
}

$stmt->bind_param("i", $userId);
$stmt->execute();
$result = $stmt->get_result();

$orders = [];

while ($row = $result->fetch_assoc()) {
    $orderId = (int)$row["order_id"];

    $sqlItems = "
        SELECT 
            oi.order_item_id,
            IFNULL(oi.menu_id, 0) as menu_id,
            IFNULL(m.menu_name, '이름 없음') as menu_name,
            oi.quantity,
            IFNULL(oi.price, 0) as price,
            IF(r.review_id IS NULL, 0, 1) AS isReviewed
        FROM order_item oi
        LEFT JOIN menu m ON m.menu_id = oi.menu_id
        LEFT JOIN review r ON r.order_item_id = oi.order_item_id
        WHERE oi.order_id = ?
        ORDER BY oi.order_item_id ASC
    ";

    $stmt2 = $mysqli->prepare($sqlItems);
    if ($stmt2) {
        $stmt2->bind_param("i", $orderId);
        $stmt2->execute();
        $resItems = $stmt2->get_result();

        $items = [];
        while ($item = $resItems->fetch_assoc()) {

            $items[] = [
                "orderItemId" => (int)$item["order_item_id"],
                "menuId"      => (int)$item["menu_id"],
                "menuName"    => $item["menu_name"],
                "quantity"    => (int)$item["quantity"],
                "price"       => (int)$item["price"],
                "isReviewed"  => (int)$item["isReviewed"]
            ];
        }
        $stmt2->close();
    }

    $orders[] = [
        "orderId"       => $orderId,
        "orderDate"     => $row["order_date"],
        "receiptNumber" => $row["receipt_number"],
        "totalPrice"    => (int)$row["total_price"],
        "items"         => $items
    ];
}


ob_clean(); 
echo json_encode($orders, JSON_UNESCAPED_UNICODE);
$mysqli->close();
exit;
?>