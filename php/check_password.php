<?php
header("Content-Type: application/json");

$conn = new mysqli("localhost", "brant", "0505", "ykt");
if ($conn->connect_error)
    die(json_encode(["success" => false, "message" => "DB 연결 실패"]));

$user_id = intval($_POST['user_id'] ?? 0);
$password = $_POST['password'] ?? "";

if ($user_id <= 0) {
    echo json_encode(["success" => false, "message" => "user_id 없음"]);
    exit;
}

$sql = "SELECT password FROM users WHERE pkey = $user_id LIMIT 1";
$result = $conn->query($sql);

if (!$result || $result->num_rows == 0) {
    echo json_encode(["success" => false, "message" => "유저 없음"]);
    exit;
}

$row = $result->fetch_assoc();
$hashedPassword = $row["password"];

if (password_verify($password, $hashedPassword)) {
    echo json_encode(["success" => true]);
} else {
    echo json_encode(["success" => false, "message" => "비밀번호 불일치"]);
}

$conn->close();
?>
