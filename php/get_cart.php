<?php
header("Content-Type: application/json");
error_reporting(E_ALL);
ini_set('display_errors', 0);

$conn = new mysqli("localhost", "brant", "0505", "ykt");
if ($conn->connect_error) {
    die(json_encode(["error" => "DB 연결 실패"]));
}

$user_id = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;

$sql = "
    SELECT
        C.cart_id,
        C.user_id,
        C.status,
        C.created_at AS cart_created_at,
        C.updated_at AS cart_updated_at,

        CI.cart_item_id,
        CI.menu_id,
        M.menu_name,
        M.food_category_id as category,
        FC.name AS category_name,
        CI.price,
        CI.promotion,
        CI.quantity,
        CI.created_at AS item_created_at,
        CI.updated_at AS item_updated_at
    FROM cart C
    JOIN cart_item CI ON C.cart_id = CI.cart_id
    JOIN menu M ON CI.menu_id = M.menu_id
    JOIN food_category FC ON M.food_category_id = FC.food_category_id
    WHERE C.user_id = $user_id
    ORDER BY C.cart_id DESC, CI.cart_item_id DESC
";

$result = $conn->query($sql);

$carts = [];

if ($result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {

        $cart_id = intval($row['cart_id']);

        if (!isset($carts[$cart_id])) {
            $carts[$cart_id] = [
                "cart_id" => $cart_id,
                "user_id" => intval($row['user_id']),
                "status" => intval($row['status']),
                "created_at" => $row['cart_created_at'],
                "updated_at" => $row['cart_updated_at'],
                "items" => []
            ];
        }


        $carts[$cart_id]["items"][] = [
            "cart_item_id" => intval($row['cart_item_id']),
            "menu_id" => intval($row['menu_id']),
            "menu_name" => $row['menu_name'],
            "category" => intval($row['category']),
            "category_name" => $row['category_name'],
            "price" => intval($row['price']),
            "promotion" => intval($row['promotion']),
            "quantity" => intval($row['quantity']),
            "created_at" => $row['item_created_at'],
            "updated_at" => $row['item_updated_at']
        ];
    }
}

echo json_encode(array_values($carts), JSON_UNESCAPED_UNICODE);
$conn->close();
?>
