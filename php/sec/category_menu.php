<?php
header('Content-Type: application/json; charset=utf-8');
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

// DB 연결
$conn = new mysqli("localhost", "brant", "0505", "ykt");
$conn->set_charset("utf8mb4");

// 입력 파라미터
$restaurant = $_GET['restaurant'] ?? '';
$user_id    = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;

if ($restaurant == '') {
    echo json_encode(["error" => "restaurant parameter required"]);
    exit;
}

/*
  - user_id > 0 : 해당 유저의 알러지 기준으로 hasAllergy 계산
  - user_id = 0 : 메뉴 자체에 알러지 성분이 하나라도 있으면 true
*/

if ($user_id > 0) {

    $sql = "
    SELECT 
        m.menu_id AS id,
        m.menu_name AS name,
        m.image_url,
        m.rating,
        m.status AS is_sold_out,
        EXISTS (
            SELECT 1 
            FROM menu_allergy ma
            JOIN user_allergy ua 
              ON ua.allergy_id = ma.allergy_id
             AND ua.status = 0          -- 유저 알러지 활성
            WHERE ma.menu_id = m.menu_id
              AND ma.status = 0         -- 메뉴 알러지 활성
              AND ua.user_id = ?
        ) AS has_allergy
    FROM menu m
    JOIN restaurants r ON r.restaurant_id = m.restaurant_id
    WHERE r.name = ?
    ORDER BY m.menu_id ASC
    ";

    $stmt = $conn->prepare($sql);
    $stmt->bind_param("is", $user_id, $restaurant);

} else {
  
    $sql = "
    SELECT 
        m.menu_id AS id,
        m.menu_name AS name,
        m.image_url,
        m.rating,
        m.status AS is_sold_out,
        EXISTS (
            SELECT 1 
            FROM menu_allergy ma
            WHERE ma.menu_id = m.menu_id
              AND ma.status = 0         -- 활성만
        ) AS has_allergy
    FROM menu m
    JOIN restaurants r ON r.restaurant_id = m.restaurant_id
    WHERE r.name = ?
    ORDER BY m.menu_id ASC
    ";

    $stmt = $conn->prepare($sql);
    $stmt->bind_param("s", $restaurant);
}

$stmt->execute();
$result = $stmt->get_result();

$data = [];

while ($row = $result->fetch_assoc()) {
    $data[] = [
        "id"        => (int)$row["id"],
        "name"      => $row["name"],
        "imageURL"  => $row["image_url"] ?? "",
        "rating"    => (float)$row["rating"],
        "isSoldOut" => ((int)$row["is_sold_out"] === 1),
        "hasAllergy"=> ((int)$row["has_allergy"] === 1)
    ];
}

echo json_encode($data, JSON_UNESCAPED_UNICODE);
?>
