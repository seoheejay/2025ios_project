<?php
header("Content-Type: application/json; charset=utf-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
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

$action = isset($_REQUEST['action']) ? $_REQUEST['action'] : '';

switch ($action) {
    case 'detail':
        get_menu_detail($conn);
        break;
    case 'toggle_like':
        toggle_like($conn);
        break;
    case 'add_to_cart':
        add_to_cart($conn);
        break;
    default:
        send_json([
            "status"  => "error",
            "message" => "유효하지 않은 action 입니다. (detail | toggle_like | add_to_cart)"
        ], 400);
}

function get_menu_detail($conn) {
    $menu_id = isset($_GET['menu_id']) ? intval($_GET['menu_id']) : 0;
    $user_id = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;

    if ($menu_id <= 0) {
        send_json([
            "status"  => "error",
            "message" => "menu_id가 필요합니다."
        ], 400);
    }

    $sql = "
        SELECT 
            m.menu_id,
            m.restaurant_id,
            m.food_category_id,
            m.menu_name,
            m.menu_details,
            m.price,
            m.calorie,
            m.status,
            m.image_url,
            m.promotion,
            m.created_at,
            m.updated_at,
            IFNULL(ROUND(AVG(r.rating), 1), 0.0) AS rating,
            COUNT(r.review_id) AS review_count
        FROM menu m
        LEFT JOIN review r ON m.menu_id = r.menu_id
        WHERE m.menu_id = ?
        GROUP BY m.menu_id
    ";

    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        send_json(["status" => "error", "message" => "쿼리 준비 실패: " . $conn->error], 500);
    }

    $stmt->bind_param("i", $menu_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $menu   = $result->fetch_assoc();
    $result->free();
    $stmt->close();

    if (!$menu) {
        send_json(["status" => "error", "message" => "해당 메뉴를 찾을 수 없습니다."], 404);
    }

    $like_count = 0;
    $like_sql = "
        SELECT COUNT(*) AS cnt
        FROM user_likes
        WHERE menu_id = ? AND status = 1
    ";

    $stmt2 = $conn->prepare($like_sql);
    if (!$stmt2) {
        send_json(["status" => "error", "message" => "좋아요 수 쿼리 준비 실패: " . $conn->error], 500);
    }

    $stmt2->bind_param("i", $menu_id);
    $stmt2->execute();
    $res2 = $stmt2->get_result();

    if ($row = $res2->fetch_assoc()) {
        $like_count = (int)$row['cnt'];
    }
    $res2->free();
    $stmt2->close();

    $is_liked = false;
    if ($user_id > 0) {
        $like_check_sql = "
            SELECT 1
            FROM user_likes
            WHERE user_id = ? AND menu_id = ? AND status = 1
            LIMIT 1
        ";

        $stmt3 = $conn->prepare($like_check_sql);
        if (!$stmt3) {
            send_json(["status" => "error", "message" => "좋아요 여부 쿼리 준비 실패: " . $conn->error], 500);
        }

        $stmt3->bind_param("ii", $user_id, $menu_id);
        $stmt3->execute();
        $res3 = $stmt3->get_result();
        $is_liked = $res3->num_rows > 0;

        $res3->free();
        $stmt3->close();
    }

    $allergies = [];
    $allergy_sql = "
        SELECT 
            a.allergy_id,
            a.allergy_name,
            ma.status AS menu_status,
            IF(ua.allergy_id IS NULL, 0, 1) AS is_user_allergic
        FROM menu_allergy ma
        JOIN allergy a ON ma.allergy_id = a.allergy_id
        LEFT JOIN user_allergy ua
            ON ua.allergy_id = a.allergy_id
            AND ua.user_id = ?
            AND ua.status = 1
        WHERE ma.menu_id = ?
          AND ma.status = 1
        ORDER BY a.allergy_id
    ";

    $stmt4 = $conn->prepare($allergy_sql);
    if (!$stmt4) {
        send_json(["status" => "error", "message" => "알레르기 쿼리 준비 실패: " . $conn->error], 500);
    }

    $stmt4->bind_param("ii", $user_id, $menu_id);
    $stmt4->execute();
    $res4 = $stmt4->get_result();

    while ($row4 = $res4->fetch_assoc()) {
        $allergies[] = [
            "allergy_id"       => (int)$row4["allergy_id"],
            "allergy_name"     => $row4["allergy_name"],
            "status"           => (int)$row4["menu_status"],
            "is_user_allergic" => (int)$row4["is_user_allergic"]
        ];
    }

    $res4->free();
    $stmt4->close();

    send_json([
        "status" => "success",
        "data"   => [
            "menu" => [
                "menu_id"          => (int)$menu["menu_id"],
                "restaurant_id"    => (int)$menu["restaurant_id"],
                "food_category_id" => (int)$menu["food_category_id"],
                "menu_name"        => $menu["menu_name"],
                "menu_details"     => $menu["menu_details"],
                "price"            => (int)$menu["price"],
                "calorie"          => isset($menu["calorie"]) ? (int)$menu["calorie"] : null,
                "status"           => (int)$menu["status"],
                "image_url"        => $menu["image_url"],
                "rating"           => (float)$menu["rating"],
                "review_count"     => (int)$menu["review_count"],
                "promotion"        => $menu["promotion"],
                "created_at"       => $menu["created_at"],
                "updated_at"       => $menu["updated_at"],
                "like_count"       => $like_count,
                "is_liked"         => $is_liked
            ],
            "allergies" => $allergies
        ]
    ]);
}

function toggle_like($conn) {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        send_json([
            "status"  => "error",
            "message" => "POST 메서드만 허용됩니다."
        ], 405);
    }

    $menu_id = isset($_POST['menu_id']) ? intval($_POST['menu_id']) : 0;
    $user_id = isset($_POST['user_id']) ? intval($_POST['user_id']) : 0;

    if ($menu_id <= 0 || $user_id <= 0) {
        send_json([
            "status"  => "error",
            "message" => "menu_id와 user_id는 필수입니다."
        ], 400);
    }

    $sql = "SELECT pkey, status FROM user_likes WHERE user_id = ? AND menu_id = ? LIMIT 1";
    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        send_json(["status" => "error", "message" => "좋아요 조회 쿼리 준비 실패: " . $conn->error], 500);
    }

    $stmt->bind_param("ii", $user_id, $menu_id);
    $stmt->execute();
    $res = $stmt->get_result();
    $row = $res->fetch_assoc();

    $res->free();
    $stmt->close();

    $conn->begin_transaction();

    try {
        if ($row) {
            $pkey = (int)$row['pkey'];
            $old  = (int)$row['status'];
            $new  = ($old === 1) ? 0 : 1;

            $sql2 = "UPDATE user_likes SET status = ?, created_at = NOW() WHERE pkey = ?";
            $stmt2 = $conn->prepare($sql2);
            if (!$stmt2) {
                throw new Exception("좋아요 업데이트 쿼리 준비 실패: " . $conn->error);
            }

            $stmt2->bind_param("ii", $new, $pkey);
            $stmt2->execute();
            $stmt2->close();

            $is_liked = ($new === 1);
        } else {
            $sql2 = "
                INSERT INTO user_likes (user_id, menu_id, status, created_at)
                VALUES (?, ?, 1, NOW())
            ";
            $stmt2 = $conn->prepare($sql2);
            if (!$stmt2) {
                throw new Exception("좋아요 추가 쿼리 준비 실패: " . $conn->error);
            }

            $stmt2->bind_param("ii", $user_id, $menu_id);
            $stmt2->execute();
            $stmt2->close();

            $is_liked = true;
        }

        $sql3 = "SELECT COUNT(*) AS cnt FROM user_likes WHERE menu_id = ? AND status = 1";
        $stmt3 = $conn->prepare($sql3);
        if (!$stmt3) {
            throw new Exception("좋아요 개수 쿼리 준비 실패: " . $conn->error);
        }

        $stmt3->bind_param("i", $menu_id);
        $stmt3->execute();
        $res3 = $stmt3->get_result();
        $count = $res3->fetch_assoc();

        $res3->free();
        $stmt3->close();

        $like_count = (int)$count['cnt'];

        $conn->commit();

        send_json([
            "status" => "success",
            "data"   => [
                "is_liked"   => $is_liked,
                "like_count" => $like_count
            ]
        ]);
    } catch (Exception $e) {
        $conn->rollback();
        send_json([
            "status"  => "error",
            "message" => "좋아요 처리 중 오류: " . $e->getMessage()
        ], 500);
    }
}

function add_to_cart($conn) {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        send_json(["status" => "error", "message" => "POST 메서드만 허용됩니다."], 405);
    }

    $menu_id  = isset($_POST['menu_id']) ? intval($_POST['menu_id']) : 0;
    $user_id  = isset($_POST['user_id']) ? intval($_POST['user_id']) : 0;
    $quantity = isset($_POST['quantity']) ? intval($_POST['quantity']) : 1;

    if ($menu_id <= 0 || $user_id <= 0) {
        send_json(["status" => "error", "message" => "menu_id와 user_id는 필수입니다."], 400);
    }
    if ($quantity <= 0) {
        $quantity = 1;
    }

    $cart_id = null;
    $cart_sql = "
        SELECT cart_id
        FROM cart
        WHERE user_id = ? AND status = 0
        LIMIT 1
    ";

    $stmt = $conn->prepare($cart_sql);
    if (!$stmt) {
        send_json(["status" => "error", "message" => "cart 조회 쿼리 준비 실패: " . $conn->error], 500);
    }

    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $res = $stmt->get_result();

    if ($row = $res->fetch_assoc()) {
        $cart_id = (int)$row['cart_id'];
    }

    $res->free();
    $stmt->close();

    if ($cart_id === null) {
        $insert_cart_sql = "
            INSERT INTO cart (user_id, status, created_at, updated_at)
            VALUES (?, 0, NOW(), NOW())
        ";
        $stmt2 = $conn->prepare($insert_cart_sql);
        if (!$stmt2) {
            send_json(["status" => "error", "message" => "cart 생성 쿼리 준비 실패: " . $conn->error], 500);
        }

        $stmt2->bind_param("i", $user_id);
        $stmt2->execute();
        $cart_id = $stmt2->insert_id;
        $stmt2->close();
    }

    $menu_sql = "
        SELECT price, promotion
        FROM menu
        WHERE menu_id = ?
        LIMIT 1
    ";
    $stmt3 = $conn->prepare($menu_sql);
    if (!$stmt3) {
        send_json(["status" => "error", "message" => "메뉴 조회 쿼리 준비 실패: " . $conn->error], 500);
    }

    $stmt3->bind_param("i", $menu_id);
    $stmt3->execute();
    $res3 = $stmt3->get_result();
    $menu_row = $res3->fetch_assoc();

    $res3->free();
    $stmt3->close();

    if (!$menu_row) {
        send_json(["status" => "error", "message" => "존재하지 않는 메뉴입니다."], 404);
    }

    $price     = (int)$menu_row['price'];
    $promotion = $menu_row['promotion'];
    if ($promotion === null || $promotion === "") {
        $promotion = "none";
    }

    $check_sql = "
        SELECT cart_item_id, quantity
        FROM cart_item
        WHERE cart_id = ? AND menu_id = ?
        LIMIT 1
    ";
    $stmt4 = $conn->prepare($check_sql);
    if (!$stmt4) {
        send_json(["status" => "error", "message" => "cart_item 조회 쿼리 준비 실패: " . $conn->error], 500);
    }

    $stmt4->bind_param("ii", $cart_id, $menu_id);
    $stmt4->execute();
    $res4 = $stmt4->get_result();
    $row4 = $res4->fetch_assoc();

    $res4->free();
    $stmt4->close();

    if ($row4) {
        $cart_item_id = (int)$row4['cart_item_id'];
        $old_qty      = (int)$row4['quantity'];
        $new_qty      = $old_qty + $quantity;

        $update_sql = "
            UPDATE cart_item
            SET quantity = ?, updated_at = NOW()
            WHERE cart_item_id = ?
        ";
        $stmt5 = $conn->prepare($update_sql);
        if (!$stmt5) {
            send_json(["status" => "error", "message" => "cart_item 수정 쿼리 준비 실패: " . $conn->error], 500);
        }

        $stmt5->bind_param("ii", $new_qty, $cart_item_id);
        $stmt5->execute();
        $stmt5->close();

        send_json([
            "status"  => "success",
            "message" => "장바구니에 추가됐습니다.",
            "data"    => [
                "cart_id"      => $cart_id,
                "cart_item_id" => $cart_item_id,
                "quantity"     => $new_qty
            ]
        ]);
    } else {
        $insert_item_sql = "
            INSERT INTO cart_item (cart_id, menu_id, price, promotion, quantity, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, NOW(), NOW())
        ";
        $stmt5 = $conn->prepare($insert_item_sql);
        if (!$stmt5) {
            send_json(["status" => "error", "message" => "cart_item 추가 쿼리 준비 실패: " . $conn->error], 500);
        }

        $stmt5->bind_param("iiisi", $cart_id, $menu_id, $price, $promotion, $quantity);
        $stmt5->execute();
        $cart_item_id = $stmt5->insert_id;
        $stmt5->close();

        send_json([
            "status"  => "success",
            "message" => "장바구니에 추가되었습니다.",
            "data"    => [
                "cart_id"      => $cart_id,
                "cart_item_id" => $cart_item_id,
                "quantity"     => $quantity
            ]
        ]);
    }
}
