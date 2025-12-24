<?php
header("Content-Type: application/json");
$conn = new mysqli("localhost", "brant", "0505", "ykt");

if ($conn->connect_error) {
    echo json_encode(["success"=>false, "message"=>"DB 연결 실패: ".$conn->connect_error]);
    exit();
}

$user_id = intval($_POST["user_id"] ?? 0);

$items_raw = $_POST["items"] ?? "[]";
$items_json = urldecode($items_raw);
$items = json_decode($items_json, true);


$sql_next = "SELECT COALESCE(MAX(receipt_number),0)+1 AS next_num FROM `order`";
$res_next = $conn->query($sql_next);
$row_next = $res_next ? $res_next->fetch_assoc() : ["next_num" => 1];
$receipt_number = intval($row_next["next_num"]);


$sql = "
    INSERT INTO `order` (user_id, receipt_number, status, order_date)
    VALUES ($user_id, $receipt_number, 1, NOW())
";

if (!$conn->query($sql)) {
    echo json_encode(["success" => false, "message" => "order 생성 실패: ".$conn->error]);
    exit();
}

$order_id = $conn->insert_id;


foreach ($items as $item) {
    $menu_id  = intval($item["menu_id"]);
    $price    = intval($item["price"]);
    $quantity = intval($item["quantity"]);

    $sql_item = "
        INSERT INTO order_item (order_id, menu_id, price, quantity)
        VALUES ($order_id, $menu_id, $price, $quantity)
    ";

    if (!$conn->query($sql_item)) {
        echo json_encode(["success"=>false, "message"=>"order_item 실패: ".$conn->error]);
        exit();
    }
}


echo json_encode([
    "success"        => true,
    "order_id"       => $order_id,
    "receipt_number" => $receipt_number
], JSON_UNESCAPED_UNICODE);

$conn->close();
?>
