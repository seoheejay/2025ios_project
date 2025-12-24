<?php
header("Content-Type: application/json");
$conn = new mysqli("localhost", "brant", "0505", "ykt");

$user_id = intval($_POST['user_id'] ?? $_GET['user_id'] ?? 0);
$new_password = $_POST['new_password'] ?? $_GET['new_password'] ?? "";

$sql = "UPDATE users SET password = '$new_password' WHERE pkey = $user_id";

if ($conn->query($sql)) {
    echo json_encode(["success"=>true]);
} else {
    echo json_encode(["success"=>false]);
}

$conn->close();
?>
