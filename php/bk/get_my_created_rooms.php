<?php
header("Content-Type: application/json; charset=utf-8");
require_once "db_connection.php";

$user_id = isset($_POST['user_id']) ? intval($_POST['user_id']) : 0;

if ($user_id <= 0) {
    echo json_encode([
        "status" => "success",
        "rooms"  => []
    ], JSON_UNESCAPED_UNICODE);
    exit;
}


$sql = "
SELECT
    r.room_id AS id,
    r.title,
    r.content,
    l.detailed AS location_name,
    r.appointment_datetime AS appointment,
    r.max_participants,
    r.status,
    (
        SELECT COUNT(*)
        FROM ykt.meal_mate_participant p
        WHERE p.room_id = r.room_id
    ) AS current_participants,
    1 AS isMine
FROM ykt.meal_mate_room r
LEFT JOIN ykt.locations l ON l.location_id = r.location_id
WHERE r.creator_id = ?
  AND r.status = 0
ORDER BY r.appointment_datetime DESC
";

$stmt = $conn->prepare($sql);
if (!$stmt) {
    echo json_encode([
        "status"  => "error",
        "message" => "쿼리 준비 실패: " . $conn->error
    ], JSON_UNESCAPED_UNICODE);
    $conn->close();
    exit;
}

$stmt->bind_param("i", $user_id);
$stmt->execute();
$res = $stmt->get_result();

$rooms = [];
while ($row = $res->fetch_assoc()) {
    $rooms[] = [
        "id"                   => (int)$row["id"],
        "title"                => $row["title"],
        "content"              => $row["content"],
        "location_name"        => $row["location_name"],
        "appointment"          => $row["appointment"],
        "max_participants"     => (int)$row["max_participants"],
        "status"               => (int)$row["status"],
        "current_participants" => (int)$row["current_participants"],
        "isMine"               => (int)$row["isMine"]   // 항상 1
    ];
}

$stmt->close();
$conn->close();

echo json_encode([
    "status" => "success",
    "rooms"  => $rooms
], JSON_UNESCAPED_UNICODE);
