<?php
$host = "localhost";      // DB 서버 주소
$user = "brant";           // DB 사용자명
$pass = "0505";               // DB 비밀번호
$dbname = "ykt";  // 실제 DB 이름으로 수정

$conn = new mysqli($host, $user, $pass, $dbname);

if ($conn->connect_error) {
    die(json_encode([
        "status" => "error",
        "message" => "DB 연결 실패: " . $conn->connect_error
    ]));
}

$conn->set_charset("utf8");
?>

