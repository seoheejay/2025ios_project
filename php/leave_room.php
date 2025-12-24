<?php
header("Content-Type: application/json");
$conn = new mysqli("localhost","brant","0505","ykt");

$room_id = intval($_POST["room_id"]);
$user_id = intval($_POST["user_id"]);

$sql = "DELETE FROM meal_mate_participant WHERE room_id = $room_id AND user_id = $user_id";
$conn->query($sql);

echo json_encode(["success" => true]);
$conn->close();
?>
