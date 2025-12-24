<?php
header("Content-Type: application/json");
$conn = new mysqli("localhost", "brant", "0505", "ykt");

$room_id = intval($_POST["room_id"] ?? 0);
$user_id = intval($_POST["user_id"] ?? 0);
$content = $_POST["content"] ?? "";

$sql = "
INSERT INTO chat_message (room_id, sender_id, content, is_read, created_at)
VALUES ($room_id, $user_id, '$content', 0, NOW())
";

$conn->query($sql);

echo json_encode(["success" => true]);
$conn->close();
?>
