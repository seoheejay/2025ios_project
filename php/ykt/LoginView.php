<?php
header("Content-Type: application/json; charset=utf-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode([
        "status"  => "fail",
        "message" => "POST 요청만 허용됩니다."
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

mysqli_report(MYSQLI_REPORT_OFF);

$servername = "localhost";
$username   = "brant";
$password   = "0505";
$dbname     = "ykt";
$table      = "users";

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    echo json_encode([
        "status"  => "error",
        "message" => "DB 연결 실패: " . $conn->connect_error
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

$conn->set_charset("utf8mb4");

$studentID     = isset($_POST['studentID']) ? trim($_POST['studentID']) : '';
$inputPassword = isset($_POST['password'])  ? $_POST['password']        : '';

if ($studentID === '' || $inputPassword === '') {
    $conn->close();
    echo json_encode([
        "status"  => "fail",
        "message" => "학번과 비밀번호를 모두 입력해주세요."
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

$sql  = "SELECT pkey, student_id, password, name, email
         FROM $table
         WHERE student_id = ?
         LIMIT 1";

$stmt = $conn->prepare($sql);
if (!$stmt) {
    $conn->close();
    echo json_encode([
        "status"  => "error",
        "message" => "SQL 준비 실패: " . $conn->error
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

$stmt->bind_param("s", $studentID);
$stmt->execute();
$stmt->store_result();

if ($stmt->num_rows === 0) {
    $stmt->close();
    $conn->close();
    echo json_encode([
        "status"  => "fail",
        "message" => "존재하지 않는 학번입니다."
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

$stmt->bind_result($pkey, $db_student_id, $db_password, $name, $email);
$stmt->fetch();

if (!password_verify($inputPassword, $db_password)) {
    $stmt->close();
    $conn->close();
    echo json_encode([
        "status"  => "fail",
        "message" => "비밀번호가 올바르지 않습니다."
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

$stmt->close();
$conn->close();

echo json_encode([
    "status"    => "success",
    "message"   => "로그인 성공",
    "user_id"   => (int)$pkey,
    "name"      => $name,
    "email"     => $email,
    "studentID" => $db_student_id
], JSON_UNESCAPED_UNICODE);
?>
