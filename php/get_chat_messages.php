<?php
header("Content-Type: application/json");
$conn = new mysqli("localhost","brant","0505","ykt");


$room_id = intval($_GET["room_id"] ?? 0);

$sql = "
SELECT c.*, u.nickname AS sender_nickname
FROM chat_message c
JOIN users u ON c.sender_id = u.pkey
WHERE room_id = $room_id
ORDER BY created_at ASC
";

$result = $conn->query($sql);

$messages = [];  

if ($result && $result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $messages[] = [
            "message_id" => intval($row["message_id"]),
            "content" => $row["content"],
            "room_id" => intval($row["room_id"]),
            "sender_id" => intval($row["sender_id"]),
            "is_read" => intval($row["is_read"]),
            "created_at" => $row["created_at"],
            "sender_nickname" => $row["sender_nickname"]
        ];
    }
}


echo json_encode($messages, JSON_UNESCAPED_UNICODE);
$conn->close();
?>
