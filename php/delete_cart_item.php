<?php
header("Content-Type: application/json");
error_reporting(E_ALL);
ini_set('display_errors', 0);

$conn = new mysqli("localhost", "brant", "0505", "ykt");

if ($conn->connect_error) {
    die(json_encode(["error" => "DB 연결 실패: " . $conn->connect_error]));
}

$cart_item_id = $_POST['cart_item_id'] ?? $_GET['cart_item_id'] ?? null;

if ($cart_item_id === null) {
    echo json_encode([
        "success" => false,
        "message" => "cart_item_id가 전달되지 않았습니다."
    ]);
    exit();
}

$cart_item_id = intval($cart_item_id);

$sql = "DELETE FROM cart_item WHERE cart_item_id = $cart_item_id";

if ($conn->query($sql) === TRUE) {
    echo json_encode([
        "success" => true,
        "message" => "장바구니 아이템 삭제 완료",
        "cart_item_id" => $cart_item_id
    ]);
} else {
    echo json_encode([
        "success" => false,
        "message" => "삭제 실패",
        "error" => $conn->error
    ]);
}

$conn->close();
?>
