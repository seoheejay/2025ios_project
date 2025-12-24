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

$sql = "
    SELECT
        r.room_id,
        r.title,
        r.content,
        r.created_at,
        r.appointment_datetime,
        r.max_participants AS participants_max,
        l.detailed AS location_name,
        IFNULL(COUNT(p.participant_id), 0) AS participant_count
    FROM meal_mate_room r
    JOIN locations l ON r.location_id = l.location_id
    LEFT JOIN meal_mate_participant p ON p.room_id = r.room_id
    WHERE r.status = 0
    GROUP BY
        r.room_id,
        r.title,
        r.content,
        r.created_at,
        r.appointment_datetime,
        r.max_participants,
        l.detailed
    ORDER BY r.appointment_datetime ASC
";

$stmt = $conn->prepare($sql);
if (!$stmt) {
    send_json([
        "status"  => "error",
        "message" => "쿼리 준비 실패: " . $conn->error
    ], 500);
}

$stmt->execute();
$result = $stmt->get_result();

if (!$result) {
    $stmt->close();
    send_json([
        "status"  => "error",
        "message" => "쿼리 실행 실패: " . $conn->error
    ], 500);
}

$rooms = [];

while ($row = $result->fetch_assoc()) {
    $rooms[] = [
        "room_id"              => (int)$row["room_id"],
        "title"                => $row["title"],
        "content"              => $row["content"],
        "created_at"           => $row["created_at"],
        "location_name"        => $row["location_name"],
        "appointment_datetime" => $row["appointment_datetime"],
        "participant_count"    => (int)$row["participant_count"],
        "participants_max"     => (int)$row["participants_max"]
    ];
}

$result->free();
$stmt->close();

send_json([
    "status" => "success",
    "data"   => $rooms
]);
