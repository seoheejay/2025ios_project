<?php
header('Content-Type: application/json; charset=utf-8');
mysqli_report(MYSQLI_REPORT_OFF);

$mysqli = new mysqli("localhost", "brant", "0505", "ykt");
$mysqli->set_charset("utf8mb4");

$user_id       = isset($_POST['user_id'])       ? intval($_POST['user_id'])       : 0;
$order_item_id = isset($_POST['order_item_id']) ? intval($_POST['order_item_id']) : 0;
$menu_id       = isset($_POST['menu_id'])       ? intval($_POST['menu_id'])       : 0;
$price         = isset($_POST['price'])         ? intval($_POST['price'])         : 0;

$rating  = isset($_POST['rating'])  ? floatval($_POST['rating']) : 0.0;
$title   = isset($_POST['title'])   ? trim($_POST['title'])      : "";
$content = isset($_POST['content']) ? trim($_POST['content'])    : "";

if ($mysqli->connect_errno) {
    echo json_encode(["status" => "error", "message" => "DB 연결 실패: " . $mysqli->connect_error], JSON_UNESCAPED_UNICODE);
    exit;
}

if ($user_id <= 0 || $order_item_id <= 0) {
    echo json_encode([
        "status" => "error",
        "message" => "필수 ID 누락 (user, order_item)",
        "debug" => [
            "user_id" => $user_id,
            "order_item_id" => $order_item_id,
            "menu_id" => $menu_id,
            "price" => $price
        ]
    ], JSON_UNESCAPED_UNICODE);
    $mysqli->close();
    exit;
}

if ($rating <= 0.0 || $title === "" || $content === "") {
    echo json_encode([
        "status" => "error",
        "message" => "내용을 입력해주세요."
    ], JSON_UNESCAPED_UNICODE);
    $mysqli->close();
    exit;
}

try {

    if ($menu_id <= 0 || $price <= 0) {
        $fixSql = "SELECT IFNULL(menu_id, 0) AS menu_id, IFNULL(price, 0) AS price FROM order_item WHERE order_item_id = ? LIMIT 1";
        $fixStmt = $mysqli->prepare($fixSql);
        if (!$fixStmt) {
            echo json_encode(["status" => "error", "message" => "보정 쿼리 prepare 실패: " . $mysqli->error], JSON_UNESCAPED_UNICODE);
            $mysqli->close();
            exit;
        }

        $fixStmt->bind_param("i", $order_item_id);
        $fixStmt->execute();
        $fixRes = $fixStmt->get_result()->fetch_assoc();
        $fixStmt->close();

        if (!$fixRes) {
            echo json_encode(["status" => "error", "message" => "order_item을 찾을 수 없습니다."], JSON_UNESCAPED_UNICODE);
            $mysqli->close();
            exit;
        }

        if ($menu_id <= 0) $menu_id = intval($fixRes["menu_id"]);
        if ($price <= 0)   $price  = intval($fixRes["price"]);
    }

   
    if ($menu_id <= 0) {
        echo json_encode([
            "status" => "error",
            "message" => "menu_id를 찾을 수 없습니다. 주문 아이템(menu_id)이 비어있습니다.",
            "debug" => [
                "order_item_id" => $order_item_id,
                "menu_id" => $menu_id,
                "price" => $price
            ]
        ], JSON_UNESCAPED_UNICODE);
        $mysqli->close();
        exit;
    }


    $checkSql = "SELECT review_id FROM review WHERE order_item_id = ? LIMIT 1";
    $checkStmt = $mysqli->prepare($checkSql);
    if (!$checkStmt) {
        echo json_encode(["status" => "error", "message" => "중복 체크 prepare 실패: " . $mysqli->error], JSON_UNESCAPED_UNICODE);
        $mysqli->close();
        exit;
    }

    $checkStmt->bind_param("i", $order_item_id);
    $checkStmt->execute();
    $checkRes = $checkStmt->get_result();
    $checkStmt->close();

    if ($checkRes->num_rows > 0) {
        echo json_encode([
            "status" => "already_reviewed",
            "message" => "이미 작성한 리뷰가 존재합니다."
        ], JSON_UNESCAPED_UNICODE);
        $mysqli->close();
        exit;
    }

 
    $sql = "
        INSERT INTO review (user_id, order_item_id, menu_id, price, rating, title, content, status, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, 0, NOW())
    ";

    $stmt = $mysqli->prepare($sql);
    if (!$stmt) {
        echo json_encode([
            "status" => "error",
            "message" => "INSERT prepare 실패: " . $mysqli->error
        ], JSON_UNESCAPED_UNICODE);
        $mysqli->close();
        exit;
    }

  
    $stmt->bind_param("iiiidss", $user_id, $order_item_id, $menu_id, $price, $rating, $title, $content);
    $stmt->execute();
    $stmt->close();

    echo json_encode([
        "status" => "success",
        "message" => "리뷰 등록 완료"
    ], JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    echo json_encode([
        "status" => "error",
        "message" => "서버 오류: " . $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);
}

$mysqli->close();
exit;
?>
