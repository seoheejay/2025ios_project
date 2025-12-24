<?php
header("Content-Type: application/json");
$conn = new mysqli("localhost", "brant", "0505", "ykt");

$user_id = intval($_POST['user_id'] ?? 0);

$sql = "UPDATE users SET status = 3 WHERE pkey = $user_id";

if ($conn->query($sql)) {
    echo json_encode(["success"=>true]);
} else {
    echo json_encode(["success"=>false]);
}

$conn->close();
?>
