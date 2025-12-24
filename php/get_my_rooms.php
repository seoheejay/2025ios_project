<?php
header("Content-Type: application/json");
$conn = new mysqli("localhost","brant","0505","ykt");

$user_id = intval($_GET["user_id"] ?? 0);

$sql = "
SELECT 
    r.room_id,
    r.title,
    r.created_at,
    l.detailed AS location_name,
    r.appointment_datetime,
    (SELECT COUNT(*) FROM meal_mate_participant WHERE room_id = r.room_id) AS participant_count
FROM meal_mate_room r
JOIN meal_mate_participant p ON r.room_id = p.room_id
LEFT JOIN locations l ON r.location_id = l.location_id
WHERE p.user_id = $user_id
GROUP BY r.room_id
";

$result = $conn->query($sql);

$rooms = [];
while($row = $result->fetch_assoc()) {
    $rooms[] = [
        "room_id" => intval($row["room_id"]),
        "title" => $row["title"],
        "created_at" => $row["created_at"],
        "location_name" => $row["location_name"],
        "appointment_datetime" => $row["appointment_datetime"],
        "participant_count" => intval($row["participant_count"])
    ];
}

echo json_encode($rooms, JSON_UNESCAPED_UNICODE);
$conn->close();
?>
