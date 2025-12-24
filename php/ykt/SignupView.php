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

$action = isset($_POST['action']) ? $_POST['action'] : "signup";

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    echo json_encode([
        "status"  => "fail",
        "message" => "DB 접속 실패: " . $conn->connect_error
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

$conn->set_charset("utf8mb4");


if ($action === "check_nickname") {
    $nickname = isset($_POST['nickname']) ? trim($_POST['nickname']) : "";

    if ($nickname === "") {
        $conn->close();
        echo json_encode([
            "status"  => "fail",
            "message" => "닉네임을 입력해주세요."
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    $sql  = "SELECT pkey FROM $table WHERE nickname = ? LIMIT 1";
    $stmt = $conn->prepare($sql);

    if (!$stmt) {
        $conn->close();
        echo json_encode([
            "status"  => "fail",
            "message" => "쿼리 준비 실패"
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    $stmt->bind_param("s", $nickname);
    $stmt->execute();
    $stmt->store_result();

    if ($stmt->num_rows > 0) {
        $stmt->close();
        $conn->close();
        echo json_encode([
            "status"  => "fail",
            "message" => "이미 사용 중인 닉네임입니다."
        ], JSON_UNESCAPED_UNICODE);
        exit;
    } else {
        $stmt->close();
        $conn->close();
        echo json_encode([
            "status"  => "success",
            "message" => "사용 가능한 닉네임입니다."
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
}

$email      = isset($_POST['email'])      ? trim($_POST['email'])      : "";
$name       = isset($_POST['name'])       ? trim($_POST['name'])       : "";
$nickname   = isset($_POST['nickname'])   ? trim($_POST['nickname'])   : "";
$student_id = isset($_POST['student_id']) ? trim($_POST['student_id']) : "";
$pwd_plain  = isset($_POST['password'])   ? $_POST['password']         : "";

if ($email === "" || $name === "" || $nickname === "" || $student_id === "" || $pwd_plain === "") {
    $conn->close();
    echo json_encode([
        "status"  => "fail",
        "message" => "모든 필드를 입력해주세요."
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

if (!preg_match('/@duksung\.ac\.kr$/', $email)) {
    $conn->close();
    echo json_encode([
        "status"  => "fail",
        "message" => "덕성 이메일(@duksung.ac.kr)만 가능합니다."
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

if (!preg_match('/^\d{8}$/', $student_id)) {
    $conn->close();
    echo json_encode([
        "status"  => "fail",
        "message" => "학번은 숫자 8자리여야 합니다."
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

$sql_dup  = "SELECT pkey FROM $table WHERE email = ? OR nickname = ? OR student_id = ? LIMIT 1";
$stmt_dup = $conn->prepare($sql_dup);

if (!$stmt_dup) {
    $conn->close();
    echo json_encode([
        "status"  => "fail",
        "message" => "중복 체크 쿼리 준비 실패"
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

$stmt_dup->bind_param("sss", $email, $nickname, $student_id);
$stmt_dup->execute();
$stmt_dup->store_result();

if ($stmt_dup->num_rows > 0) {
    $stmt_dup->close();
    $conn->close();
    echo json_encode([
        "status"  => "fail",
        "message" => "이미 가입된 이메일/닉네임/학번이 존재합니다."
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

$stmt_dup->close();


$pwd_hash          = password_hash($pwd_plain, PASSWORD_BCRYPT);
$certificate_email = 0;
$status            = 1;

$sql_ins  = "INSERT INTO $table
            (student_id, password, name, nickname, email,
             certificate_email, status, created_at, update_at)
            VALUES (?,?,?,?,?,?,?,NOW(),NOW())";

$stmt_ins = $conn->prepare($sql_ins);

if (!$stmt_ins) {
    $conn->close();
    echo json_encode([
        "status"  => "fail",
        "message" => "회원가입 쿼리 준비 실패"
    ], JSON_UNESCAPED_UNICODE);
    exit;
}

$stmt_ins->bind_param(
    "sssssii",
    $student_id,
    $pwd_hash,
    $name,
    $nickname,
    $email,
    $certificate_email,
    $status
);

$ok = $stmt_ins->execute();

if ($ok) {
    $new_id = $conn->insert_id;
    $stmt_ins->close();
    $conn->close();

    echo json_encode([
        "status"  => "success",
        "user_id" => (int)$new_id,
        "message" => "회원가입 성공"
    ], JSON_UNESCAPED_UNICODE);
    exit;
} else {
    $stmt_ins->close();
    $conn->close();

    echo json_encode([
        "status"  => "fail",
        "message" => "회원가입 처리 중 오류가 발생했습니다."
    ], JSON_UNESCAPED_UNICODE);
    exit;
}
?>
