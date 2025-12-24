<?php
header("Content-Type: application/json; charset=utf-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode([
        "status"  => "error",
        "message" => "POST 요청만 허용됩니다."
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

mysqli_report(MYSQLI_REPORT_OFF);

$servername = "localhost";
$username   = "root";
$password   = "00000000";
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

$title      = isset($_POST["room_title"]) ? trim($_POST["room_title"]) : "";
$content    = isset($_POST["content"]) ? trim($_POST["content"]) : "";
$place      = isset($_POST["place"]) ? trim($_POST["place"]) : "";
$date       = isset($_POST["date"]) ? trim($_POST["date"]) : "";
$time       = isset($_POST["time"]) ? trim($_POST["time"]) : "";
$max_people = isset($_POST["max_people"]) ? (int)$_POST["max_people"] : 0;

$creator_id = 1;

if ($title === "" || $content === "" || $place === "" ||
    $date === "" || $time === "" || $max_people <= 0) {
    send_json([
        "status"  => "error",
        "message" => "필수 값이 누락되었습니다."
    ], 400);
}

$appointment_datetime = $date . " " . $time . ":00";

$location_id = null;

$sql_loc = "
    SELECT location_id
    FROM locations
    WHERE detailed = ?
    LIMIT 1
";

$stmt = $conn->prepare($sql_loc);
if (!$stmt) {
    send_json([
        "status"  => "error",
        "message" => "location 쿼리 준비 실패: " . $conn->error
    ], 500);
}
$stmt->bind_param("s", $place);
$stmt->execute();
$stmt->bind_result($location_id);

if ($stmt->fetch()) {
    $stmt->close();
} else {
    $stmt->close();
    send_json([
        "status"  => "error",
        "message" => "장소를 찾을 수 없습니다: " . $place
    ], 400);
}

$sql_room = "
    INSERT INTO meal_mate_room
        (title, content, location_id, appointment_datetime, max_participants, created_at, creator_id, status)
    VALUES
        (?, ?, ?, ?, ?, NOW(), ?, 0)
";

$stmt2 = $conn->prepare($sql_room);
if (!$stmt2) {
    send_json([
        "status"  => "error",
        "message" => "room 쿼리 준비 실패: " . $conn->error
    ], 500);
}

$stmt2->bind_param(
    "ssisii",
    $title,
    $content,
    $location_id,
    $appointment_datetime,
    $max_people,
    $creator_id
);

if (!$stmt2->execute()) {
    $err = $stmt2->error;
    $stmt2->close();
    send_json([
        "status"  => "error",
        "message" => "방 저장 실패: " . $err
    ], 500);
}

$room_id = $stmt2->insert_id;
$stmt2->close();

$sql_part = "
    INSERT INTO meal_mate_participant
        (room_id, user_id, created_at, updated_at, status)
    VALUES
        (?, ?, NOW(), NOW(), 1)
";

$stmt3 = $conn->prepare($sql_part);
if (!$stmt3) {
    send_json([
        "status"  => "error",
        "message" => "참여자 쿼리 준비 실패: " . $conn->error
    ], 500);
}

$stmt3->bind_param("ii", $room_id, $creator_id);

if (!$stmt3->execute()) {
    $err = $stmt3->error;
    $stmt3->close();
    send_json([
        "status"  => "error",
        "message" => "참여자 저장 실패: " . $err
    ], 500);
}

$stmt3->close();

send_json([
    "status" => "success",
    "data"   => ["room_id" => (int)$room_id]
]);
