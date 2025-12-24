<?php
header("Content-Type: application/json; charset=utf-8");
require_once "db_connection.php";

$room_id = isset($_POST['room_id']) ? intval($_POST['room_id']) : 0;

if ($room_id <= 0) {
    echo json_encode(["status" => "fail", "message" => "invalid room_id"], JSON_UNESCAPED_UNICODE);
    exit;
}

$sql = "
SELECT
    r.*,
    l.detailed AS location_name
FROM ykt.meal_mate_room AS r
LEFT JOIN ykt.locations AS l
    ON r.location_id = l.location_id
WHERE r.room_id = ?
";

$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $room_id);
$stmt->execute();
$result = $stmt->get_result();

if ($row = $result->fetch_assoc()) {

    echo json_encode([
        "status" => "success",
        "room" => [
            "room_id"              => intval($row["room_id"]),
            "title"                => $row["title"],
            "content"              => $row["content"],
            "location_id"          => intval($row["location_id"]),
            "location_name"        => $row["location_name"],
            "appointment_datetime" => $row["appointment_datetime"],
            "max_participants"     => intval($row["max_participants"])
        ]
    ], JSON_UNESCAPED_UNICODE);

} else {
    echo json_encode([
        "status" => "fail",
        "message" => "room not found"
    ], JSON_UNESCAPED_UNICODE);
}

$stmt->close();
$conn->close();
?>

