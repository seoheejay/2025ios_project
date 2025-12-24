<?php
header("Content-Type: application/json; charset=utf-8");
require_once "db_connection.php";

$sql = "SELECT location_id AS id, detailed AS name FROM ykt.locations ORDER BY name ASC";
$result = $conn->query($sql);

$list = [];

while($row = $result->fetch_assoc()) {
    $list[] = $row;
}

echo json_encode([
    "status" => "success",
    "locations" => $list
], JSON_UNESCAPED_UNICODE);

$conn->close();
?>

