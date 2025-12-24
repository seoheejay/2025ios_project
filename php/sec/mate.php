<?php
header('Content-Type: application/json; charset=utf-8');
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

try {
    $conn = new mysqli("localhost", "brant", "0505", "ykt");
    if ($conn->connect_errno) {
        throw new Exception("DB 연결 실패: " . $conn->connect_error);
    }
    $conn->set_charset("utf8mb4");

    $type = $_POST["type"] ?? "";

    if ($type === "join_room") {
        joinRoom($conn);
    } else {
        echo json_encode([
            "result"  => false,
            "message" => "잘못된 type 값입니다."
        ], JSON_UNESCAPED_UNICODE);
    }

} catch (Exception $e) {
    echo json_encode([
        "result"  => false,
        "message" => "서버 오류: " . $e->getMessage()
    ], JSON_UNESCAPED_UNICODE);

} finally {
    if (isset($conn) && $conn instanceof mysqli) {
        $conn->close();
    }
}


function joinRoom($conn) {

    $room_id = isset($_POST["room_id"]) ? intval($_POST["room_id"]) : 0;
    $user_id = isset($_POST["user_id"]) ? intval($_POST["user_id"]) : 0;  

    if ($room_id <= 0 || $user_id <= 0) {
        echo json_encode([
            "result"  => false,
            "message" => "room_id 또는 user_id가 잘못되었습니다."
        ], JSON_UNESCAPED_UNICODE);
        return;
    }

    $sql = "SELECT COUNT(*) AS cnt 
            FROM meal_mate_participant 
            WHERE room_id = ? AND user_id = ? AND status = 0";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("ii", $room_id, $user_id);
    $stmt->execute();
    $res = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    if ($res["cnt"] > 0) {
        echo json_encode([
            "result"               => true,
            "message"              => "이미 참여중인 방입니다.",
            "current_participants" => getCurrentParticipants($conn, $room_id)
        ], JSON_UNESCAPED_UNICODE);
        return;
    }

    // 2. 방의 최대 인원 확인 (meal_mate_room.status = 0 이 '모집중')
    $sql = "SELECT max_participants 
            FROM meal_mate_room 
            WHERE room_id = ? AND status = 0";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $room_id);
    $stmt->execute();
    $room = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    if (!$room) {
        echo json_encode([
            "result"  => false,
            "message" => "해당 방을 찾을 수 없습니다."
        ], JSON_UNESCAPED_UNICODE);
        return;
    }

    $max_participants     = intval($room["max_participants"]);
    $current_participants = getCurrentParticipants($conn, $room_id);

    if ($current_participants >= $max_participants) {
        echo json_encode([
            "result"               => false,
            "message"              => "이미 정원이 가득 찬 방입니다.",
            "current_participants" => $current_participants
        ], JSON_UNESCAPED_UNICODE);
        return;
    }


    $now = date("Y-m-d H:i:s");

    $sql = "INSERT INTO meal_mate_participant
                (room_id, user_id, created_at, updated_at, status)
            VALUES (?, ?, ?, ?, 0)";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("iiss", $room_id, $user_id, $now, $now);

    if (!$stmt->execute()) {
        $stmt->close();
        echo json_encode([
            "result"  => false,
            "message" => "참여 저장 중 오류: " . $conn->error
        ], JSON_UNESCAPED_UNICODE);
        return;
    }
    $stmt->close();


    $current_participants = getCurrentParticipants($conn, $room_id);

    echo json_encode([
        "result"               => true,
        "message"              => "참여에 성공했습니다.",
        "current_participants" => $current_participants
    ], JSON_UNESCAPED_UNICODE);
}

function getCurrentParticipants($conn, $room_id) {
    $sql = "SELECT COUNT(*) AS cnt 
            FROM meal_mate_participant 
            WHERE room_id = ? AND status = 0";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $room_id);
    $stmt->execute();
    $res = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    return intval($res["cnt"]);
}
?>
