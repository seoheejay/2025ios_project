<?php
header("Content-Type: application/json; charset=utf-8");
require_once "db_connection.php";

$room_id = intval($_POST['room_id'] ?? 0);

if ($room_id <= 0) {
    echo json_encode(["status" => "fail", "message" => "invalid room_id"], JSON_UNESCAPED_UNICODE);
    exit;
}

$conn->begin_transaction();

try {
    $conn->query("DELETE FROM ykt.meal_mate_participant WHERE room_id = $room_id");
    $conn->query("DELETE FROM ykt.meal_mate_room WHERE room_id = $room_id");

    $conn->commit();
    echo json_encode(["status" => "success"], JSON_UNESCAPED_UNICODE);

} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(["status" => "fail", "message" => "delete failed"], JSON_UNESCAPED_UNICODE);
}

$conn->close();
?>

