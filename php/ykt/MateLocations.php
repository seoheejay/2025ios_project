<?php
header("Content-Type: application/json; charset=utf-8");
header("Access-Control-Allow-Origin: *");

mysqli_report(MYSQLI_REPORT_OFF);

$servername = "localhost";
$username   = "brant";
$password   = "0505";
$dbname     = "ykt";

$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    echo json_encode([
        "status"  => "error",
        "message" => "DB 연결 실패: " . $conn->connect_error
    ], JSON_UNESCAPED_UNICODE);
    exit;
}
$conn->set_charset("utf8mb4");

$sql = "
    SELECT 
        l.location_id,
        b.name AS building_name,
        l.detailed
    FROM locations l
    JOIN buildings b ON l.building_id = b.building_id
    ORDER BY b.name, l.detailed
";

$result = $conn->query($sql);
if (!$result) {
    echo json_encode([
        "status"  => "error",
        "message" => "쿼리 실패: " . $conn->error
    ], JSON_UNESCAPED_UNICODE);
    $conn->close();
    exit;
}

$list = [];
while ($row = $result->fetch_assoc()) {
    $list[] = [
        "location_id"   => (int)$row["location_id"],
        "building_name" => $row["building_name"],
        "detailed"      => $row["detailed"]
    ];
}

echo json_encode($list, JSON_UNESCAPED_UNICODE);

$conn->close();
