<?php
header("Content-Type: application/json; charset=utf-8");
require_once "db_connection.php";

$room_id  = isset($_POST['room_id']) ? intval($_POST['room_id']) : 0;
$title    = $_POST['title'] ?? "";
$content  = $_POST['content'] ?? "";
$location_id = isset($_POST['location_id']) ? intval($_POST['location_id']) : 0;
$appointment = $_POST['appointment'] ?? "";
$max_count   = isset($_POST['max_participants']) ? intval($_POST['max_participants']) : 0;

if ($room_id <= 0) {
    echo json_encode(["status"=>"fail","message"=>"invalid room_id"], JSON_UNESCAPED_UNICODE);
    exit;
}

$sql = "
UPDATE ykt.meal_mate_room
SET
    title = ?,
    content = ?,
    location_id = ?,
    appointment_datetime = ?,
    max_participants = ?
WHERE room_id = ?
";

$stmt = $conn->prepare($sql);
$stmt->bind_param("ssissi", $title, $content, $location_id, $appointment, $max_count, $room_id);

if ($stmt->execute()) {
    echo json_encode(["status"=>"success"], JSON_UNESCAPED_UNICODE);
} else {
    echo json_encode(["status"=>"fail","message"=>"update failed"], JSON_UNESCAPED_UNICODE);
}

$stmt->close();
$conn->close();
?>

