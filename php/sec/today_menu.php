<?php
header('Content-Type: application/json; charset=utf-8');
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);


$conn = new mysqli("localhost", "brant", "0505", "ykt");
$conn->set_charset("utf8mb4");

$user_id = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;


$menus = ['오늘의메뉴A', '오늘의메뉴B'];

$menuAItems = [];
$menuBItems = [];
$menuARating = 0.0;
$menuBRating = 0.0;
$menuASoldOut = false;
$menuBSoldOut = false;

foreach ($menus as $menuName) {

    $sqlMenu = "
        SELECT menu_id, rating, status
        FROM menu
        WHERE menu_name = ?
        LIMIT 1
    ";
    $stmt = $conn->prepare($sqlMenu);
    $stmt->bind_param("s", $menuName);
    $stmt->execute();
    $menuResult = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    if (!$menuResult) continue;

    $menuId      = (int)$menuResult["menu_id"];
    $menuRating  = (float)$menuResult["rating"];
    $menuSoldOut = ((int)$menuResult["status"] === 1);  

    if ($user_id > 0) {
  
        $sqlItems = "
            SELECT 
                t.today_meal_id AS id,
                mi.meal_name    AS name,
                m.status        AS is_sold_out,
                EXISTS (
                    SELECT 1 
                    FROM menu_allergy ma
                    JOIN user_allergy ua 
                      ON ua.allergy_id = ma.allergy_id
                     AND ua.status = 0         -- 유저 알러지 활성
                    WHERE ma.menu_id = m.menu_id
                      AND ma.status = 0        -- 메뉴 알러지 활성
                      AND ua.user_id = ?
                ) AS has_allergy
            FROM today_menu t
            JOIN meal_item mi ON mi.meal_item_id = t.meal_item_id
            JOIN menu m       ON m.menu_id = t.menu_id
            WHERE t.menu_id = ?
            ORDER BY t.sort_order ASC
        ";
        $stmt2 = $conn->prepare($sqlItems);
        $stmt2->bind_param("ii", $user_id, $menuId);

    } else {
        // 🔵 메뉴 알러지 여부만
        $sqlItems = "
            SELECT 
                t.today_meal_id AS id,
                mi.meal_name    AS name,
                m.status        AS is_sold_out,
                EXISTS (
                    SELECT 1 
                    FROM menu_allergy ma
                    WHERE ma.menu_id = m.menu_id
                      AND ma.status = 0
                ) AS has_allergy
            FROM today_menu t
            JOIN meal_item mi ON mi.meal_item_id = t.meal_item_id
            JOIN menu m       ON m.menu_id = t.menu_id
            WHERE t.menu_id = ?
            ORDER BY t.sort_order ASC
        ";
        $stmt2 = $conn->prepare($sqlItems);
        $stmt2->bind_param("i", $menuId);
    }

    $stmt2->execute();
    $result2 = $stmt2->get_result();
    $stmt2->close();

    $list = [];
    while ($row = $result2->fetch_assoc()) {
        $list[] = [
            "id"        => (int)$row["id"],
            "name"      => $row["name"],
            "isSoldOut" => ((int)$row["is_sold_out"] === 1),
            "hasAllergy"=> ((int)$row["has_allergy"] === 1)
        ];
    }

    if ($menuName === '오늘의메뉴A') {
        $menuAItems   = $list;
        $menuARating  = $menuRating;
        $menuASoldOut = $menuSoldOut;
    } else if ($menuName === '오늘의메뉴B') {
        $menuBItems   = $list;
        $menuBRating  = $menuRating;
        $menuBSoldOut = $menuSoldOut;
    }
}

$response = [
    "menuAItems"    => $menuAItems,
    "menuBItems"    => $menuBItems,
    "menuARating"   => $menuARating,
    "menuBRating"   => $menuBRating,
    "menuASoldOut"  => $menuASoldOut,
    "menuBSoldOut"  => $menuBSoldOut
];

echo json_encode($response, JSON_UNESCAPED_UNICODE);
?>
