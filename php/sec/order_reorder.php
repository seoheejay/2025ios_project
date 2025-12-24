<?php
header('Content-Type: application/json; charset=utf-8');
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

$mysqli = new mysqli("localhost", "brant", "0505", "ykt");
$mysqli->set_charset("utf8mb4");


$user_id  = isset($_POST['user_id']) ? intval($_POST['user_id']) : 0;
$order_id = isset($_POST['order_id']) ? intval($_POST['order_id']) : 0;

if ($user_id <= 0 || $order_id <= 0) {
    echo json_encode([
        "status"  => "error",
        "message" => "잘못된 파라미터",
        "debug"   => [
            "user_id"  => $user_id,
            "order_id" => $order_id
        ]
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

try {
    $mysqli->begin_transaction();


    $sqlFindCart = "SELECT cart_id FROM cart WHERE user_id = ? LIMIT 1";
    $stmt = $mysqli->prepare($sqlFindCart);
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $res = $stmt->get_result();

    if ($res->num_rows > 0) {
        $cart_id = intval($res->fetch_assoc()['cart_id']);
    } else {
        $sqlCreateCart = "
            INSERT INTO cart (user_id, status, created_at, updated_at)
            VALUES (?, 0, NOW(), NOW())
        ";
        $stmt2 = $mysqli->prepare($sqlCreateCart);
        $stmt2->bind_param("i", $user_id);
        $stmt2->execute();
        $cart_id = $stmt2->insert_id;
        $stmt2->close();
    }
    $stmt->close();


    $sqlOrderItems = "
        SELECT oi.menu_id, oi.quantity, oi.price 
        FROM order_item oi
        WHERE oi.order_id = ?
    ";
    $stmt = $mysqli->prepare($sqlOrderItems);
    $stmt->bind_param("i", $order_id);
    $stmt->execute();
    $resItems = $stmt->get_result();

    $added = 0;
    $itemDebug = [];

    while ($row = $resItems->fetch_assoc()) {
        $menu_id  = intval($row['menu_id']);
        $quantity = intval($row['quantity']);
        $price    = intval($row['price']);

        $itemDebug[] = [
            "menu_id"  => $menu_id,
            "quantity" => $quantity,
            "price"    => $price
        ];

        $sqlInsertItem = "
            INSERT INTO cart_item (cart_id, menu_id, quantity, price, promotion, created_at, updated_at)
            VALUES (?, ?, ?, ?, 0, NOW(), NOW())
            ON DUPLICATE KEY UPDATE 
                quantity = quantity + VALUES(quantity),
                updated_at = NOW()
        ";

        $stmt2 = $mysqli->prepare($sqlInsertItem);
        $stmt2->bind_param("iiii", $cart_id, $menu_id, $quantity, $price);
        $stmt2->execute();
        $stmt2->close();

        $added++;
    }

    $stmt->close();
    $mysqli->commit();

    echo json_encode([
        "status"      => "success",
        "message"     => "장바구니에 담기 완료",
        "added_items" => $added,
        "cart_id"     => $cart_id,
        "debug"       => [
            "user_id"      => $user_id,
            "order_id"     => $order_id,
            "itemsFetched" => count($itemDebug),
            "items"        => $itemDebug
        ]
    ], JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    $mysqli->rollback();
    echo json_encode([
        "status"  => "error",
        "message" => "서버 오류: " . $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}

$mysqli->close();
exit;
?>
