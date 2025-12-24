<?php
header("Content-Type: application/json");
$conn = new mysqli("localhost","brant","0505","ykt");

$room_id = intval($_GET["room_id"] ?? 0);

$sql = "
SELECT 
    r.room_id,
    r.title,
    r.content,
    r.created_at,
    l.detailed AS location_name,
    r.appointment_datetime,
    (SELECT COUNT(*) FROM meal_mate_participant WHERE room_id = r.room_id) AS participant_count
FROM meal_mate_room r
LEFT JOIN locations l ON r.location_id = l.location_id
WHERE r.room_id = $room_id
";

$result = $conn->query($sql);
$row = $result->fetch_assoc();

if ($row) {
    echo json_encode([
        "room_id"             => (int)$row["room_id"],
        "title"               => $row["title"],
        "content"             => $row["content"],
        "created_at"          => $row["created_at"],
        "location_name"       => $row["location_name"],
        "appointment_datetime"=> $row["appointment_datetime"],
        "participant_count"   => (int)$row["participant_count"]
    ], JSON_UNESCAPED_UNICODE);
} else {
    echo json_encode([
        "error" => "room not found"
    ], JSON_UNESCAPED_UNICODE);
}

$conn->close();
?>
