<?php
header("Content-Type: application/json; charset=utf-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

mysqli_report(MYSQLI_REPORT_OFF);

$servername = "localhost";
$username   = "brant";
$password   = "0505";
$dbname     = "ykt";

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    echo json_encode([
        "status"  => "error",
        "message" => "DB 연결 실패: " . $conn->connect_error
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

$conn->set_charset("utf8mb4");

function send_json($data, $code = 200) {
    global $conn;
    http_response_code($code);
    echo json_encode($data, JSON_UNESCAPED_UNICODE);
    if ($conn instanceof mysqli) {
        $conn->close();
    }
    exit;
}

$action = isset($_GET['action']) ? $_GET['action'] : '';

if ($action !== 'list') {
    send_json([
        "status"  => "error",
        "message" => "유효하지 않은 action 입니다. (list)"
    ], 400);
}

$menu_id = isset($_GET['menu_id']) ? intval($_GET['menu_id']) : 0;
if ($menu_id <= 0) {
    send_json([
        "status"  => "error",
        "message" => "menu_id가 필요합니다."
    ], 400);
}

$sql = "
    SELECT
        review_id,
        user_id,
        menu_id,
        order_item_id,
        rating,
        title,
        content,
        price,
        status,
        created_at,
        updated_at
    FROM review
    WHERE menu_id = ?
    ORDER BY rating DESC, created_at DESC
";

$stmt = $conn->prepare($sql);
if (!$stmt) {
    send_json([
        "status"  => "error",
        "message" => "쿼리 준비 실패: " . $conn->error
    ], 500);
}

$stmt->bind_param("i", $menu_id);
$stmt->execute();
$res = $stmt->get_result();

$reviews = [];
$totalRating = 0.0;
$count = 0;

while ($row = $res->fetch_assoc()) {
    $rating = (float)$row["rating"];
    $totalRating += $rating;
    $count++;

    $reviews[] = [
        "review_id"     => (int)$row["review_id"],
        "user_id"       => (int)$row["user_id"],
        "menu_id"       => (int)$row["menu_id"],
        "order_item_id" => isset($row["order_item_id"]) ? (int)$row["order_item_id"] : null,
        "rating"        => $rating,
        "title"         => $row["title"],
        "content"       => $row["content"],
        "price"         => isset($row["price"]) ? (int)$row["price"] : null,
        "status"        => (int)$row["status"],
        "created_at"    => $row["created_at"],
        "updated_at"    => $row["updated_at"]
    ];
}

$res->free();
$stmt->close();

$average = 0.0;
if ($count > 0) {
    $average = round($totalRating / $count, 1);
}

send_json([
    "status" => "success",
    "data" => [
        "average_rating" => $average,
        "review_count"   => $count,
        "reviews"        => $reviews
    ]
]);
