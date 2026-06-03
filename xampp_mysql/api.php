<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

$host = "localhost";
$db_name = "edu_app";
$username = "root";
$password = "";

try {
    $db = new PDO("mysql:host=" . $host . ";dbname=" . $db_name . ";charset=utf8mb4", $username, $password);
    $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $db->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
} catch (PDOException $exception) {
    echo json_encode(["error" => "Database connection error: " . $exception->getMessage()]);
    exit();
}

$input = json_decode(file_get_contents("php://input"), true);
$action = isset($_GET['action']) ? $_GET['action'] : '';

switch ($action) {
    case 'create_user':
        // Check if name already exists
        $stmt = $db->prepare("SELECT COUNT(*) as count FROM users WHERE name = :name");
        $stmt->execute([':name' => $input['name']]);
        $count = (int)$stmt->fetch()['count'];
        if ($count > 0) {
            echo json_encode(["error" => "name_exists"]);
            break;
        }

        $stmt = $db->prepare("INSERT INTO users (name, phone, password, avatarId, score, createdAt) VALUES (:name, :phone, :password, :avatarId, :score, :createdAt)");
        $stmt->execute([
            ':name' => $input['name'],
            ':phone' => $input['phone'],
            ':password' => $input['password'],
            ':avatarId' => isset($input['avatarId']) ? (int)$input['avatarId'] : 1,
            ':score' => isset($input['score']) ? (int)$input['score'] : 0,
            ':createdAt' => isset($input['createdAt']) ? $input['createdAt'] : date('c')
        ]);
        $newId = $db->lastInsertId();
        echo json_encode(["id" => (int)$newId]);
        break;

    case 'read_all_users':
        $stmt = $db->query("SELECT * FROM users ORDER BY id ASC");
        echo json_encode($stmt->fetchAll());
        break;

    case 'read_user':
        $stmt = $db->prepare("SELECT * FROM users WHERE id = :id");
        $stmt->execute([':id' => (int)$_GET['id']]);
        $user = $stmt->fetch();
        echo json_encode($user ? $user : null);
        break;

    case 'update_user':
        // Check if another user has the same name
        $stmt = $db->prepare("SELECT COUNT(*) as count FROM users WHERE name = :name AND id != :id");
        $stmt->execute([':name' => $input['name'], ':id' => (int)$input['id']]);
        $count = (int)$stmt->fetch()['count'];
        if ($count > 0) {
            echo json_encode(["error" => "name_exists"]);
            break;
        }

        $stmt = $db->prepare("UPDATE users SET name = :name, phone = :phone, password = :password, avatarId = :avatarId, score = :score WHERE id = :id");
        $result = $stmt->execute([
            ':id' => (int)$input['id'],
            ':name' => $input['name'],
            ':phone' => $input['phone'],
            ':password' => $input['password'],
            ':avatarId' => isset($input['avatarId']) ? (int)$input['avatarId'] : 1,
            ':score' => isset($input['score']) ? (int)$input['score'] : 0
        ]);
        echo json_encode($result ? 1 : 0);
        break;

    case 'delete_user':
        $stmt = $db->prepare("DELETE FROM users WHERE id = :id");
        $result = $stmt->execute([':id' => (int)$_GET['id']]);
        echo json_encode($result ? 1 : 0);
        break;

    case 'get_all_lessons':
        $stmt = $db->query("SELECT * FROM lessons ORDER BY id ASC");
        echo json_encode($stmt->fetchAll());
        break;

    case 'create_lesson':
        $stmt = $db->prepare("INSERT INTO lessons (grade, subject, title, total_stars) VALUES (:grade, :subject, :title, :total_stars)");
        $stmt->execute([
            ':grade' => $input['grade'],
            ':subject' => $input['subject'],
            ':title' => $input['title'],
            ':total_stars' => (int)$input['totalStars']
        ]);
        $newId = $db->lastInsertId();
        echo json_encode(["id" => (int)$newId]);
        break;

    case 'delete_lesson':
        $stmt = $db->prepare("DELETE FROM lessons WHERE id = :id");
        $result = $stmt->execute([':id' => (int)$_GET['id']]);
        echo json_encode($result ? 1 : 0);
        break;

    case 'save_progress':
        $userId = (int)$input['userId'];
        $lessonId = (int)$input['lessonId'];
        $starsEarned = (int)$input['starsEarned'];

        // Check if progress already exists
        $stmt = $db->prepare("SELECT * FROM progress WHERE user_id = :userId AND lesson_id = :lessonId");
        $stmt->execute([':userId' => $userId, ':lessonId' => $lessonId]);
        $existing = $stmt->fetch();

        if (!$existing) {
            $stmt = $db->prepare("INSERT INTO progress (user_id, lesson_id, stars_earned, is_completed, last_played) VALUES (:userId, :lessonId, :stars, :isCompleted, :lastPlayed)");
            $stmt->execute([
                ':userId' => $userId,
                ':lessonId' => $lessonId,
                ':stars' => $starsEarned,
                ':isCompleted' => $starsEarned === 3 ? 1 : 0,
                ':lastPlayed' => date('c')
            ]);
        } else {
            $currentStars = (int)$existing['stars_earned'];
            if ($starsEarned > $currentStars) {
                $stmt = $db->prepare("UPDATE progress SET stars_earned = :stars, is_completed = :isCompleted, last_played = :lastPlayed WHERE user_id = :userId AND lesson_id = :lessonId");
                $stmt->execute([
                    ':stars' => $starsEarned,
                    ':isCompleted' => $starsEarned === 3 ? 1 : 0,
                    ':lastPlayed' => date('c'),
                    ':userId' => $userId,
                    ':lessonId' => $lessonId
                ]);
            }
        }

        // Recalculate user score
        $stmt = $db->prepare("SELECT SUM(stars_earned) as total FROM progress WHERE user_id = :userId");
        $stmt->execute([':userId' => $userId]);
        $row = $stmt->fetch();
        $totalScore = (int)$row['total'];

        $stmt = $db->prepare("UPDATE users SET score = :score WHERE id = :userId");
        $stmt->execute([':score' => $totalScore, ':userId' => $userId]);

        echo json_encode(["status" => "success"]);
        break;

    case 'get_lesson_progress_stars':
        $stmt = $db->prepare("SELECT stars_earned FROM progress WHERE user_id = :userId AND lesson_id = :lessonId");
        $stmt->execute([':userId' => (int)$_GET['userId'], ':lessonId' => (int)$_GET['lessonId']]);
        $row = $stmt->fetch();
        echo json_encode($row ? (int)$row['stars_earned'] : 0);
        break;

    case 'get_rewards_for_user':
        $userId = (int)$_GET['userId'];
        $stmt = $db->prepare("SELECT * FROM rewards WHERE user_id = :userId");
        $stmt->execute([':userId' => $userId]);
        $rewards = $stmt->fetchAll();
        echo json_encode($rewards);
        break;

    case 'check_and_unlock_rewards':
        $userId = (int)$_GET['userId'];
        // Ensure default 9 rewards exist for user
        $stmt = $db->prepare("SELECT COUNT(*) as count FROM rewards WHERE user_id = :userId");
        $stmt->execute([':userId' => $userId]);
        $count = (int)$stmt->fetch()['count'];

        if ($count === 0) {
            $defaultRewards = [
                ['reward_name' => 'ຍອດນັກອ່ານ ປ.1', 'image_path' => '📚'],
                ['reward_name' => 'ຍອດນັກອ່ານ ປ.2', 'image_path' => '📖'],
                ['reward_name' => 'ນັກຄິດໄວ ປ.1', 'image_path' => '🍎'],
                ['reward_name' => 'ນັກຄິດໄວ ປ.2', 'image_path' => '🧮'],
                ['reward_name' => 'ດາວເດັ່ນຮຽນເກັ່ງ', 'image_path' => '⭐'],
                ['reward_name' => 'ແຊມປ້ຽນຫຼຽນທອງ', 'image_path' => '🥉'],
                ['reward_name' => 'ແຊມປ້ຽນຫຼຽນເງິນ', 'image_path' => '🥈'],
                ['reward_name' => 'ແຊມປ້ຽນຫຼຽນຄຳ', 'image_path' => '🥇'],
                ['reward_name' => 'ອັດສະລິຍະຕົວນ້ອຍ', 'image_path' => '🏆']
            ];
            foreach ($defaultRewards as $r) {
                $stmt = $db->prepare("INSERT INTO rewards (user_id, reward_name, image_path, is_unlocked) VALUES (:userId, :name, :path, 0)");
                $stmt->execute([
                    ':userId' => $userId,
                    ':name' => $r['reward_name'],
                    ':path' => $r['image_path']
                ]);
            }
        }

        // Auto unlock logic based on stars/completed progress
        $stmt = $db->prepare("SELECT SUM(stars_earned) as totalStars, COUNT(CASE WHEN stars_earned > 0 THEN 1 END) as completedCount FROM progress WHERE user_id = :userId");
        $stmt->execute([':userId' => $userId]);
        $summary = $stmt->fetch();
        $totalStars = (int)$summary['totalStars'];
        $completedCount = (int)$summary['completedCount'];

        $stmt = $db->prepare("SELECT p.stars_earned, l.grade, l.subject FROM progress p JOIN lessons l ON p.lesson_id = l.id WHERE p.user_id = :userId");
        $stmt->execute([':userId' => $userId]);
        $details = $stmt->fetchAll();

        $laoG1Stars = 0; $laoG2Stars = 0; $mathG1Stars = 0; $mathG2Stars = 0;
        foreach ($details as $row) {
            $stars = (int)$row['stars_earned'];
            if ($row['grade'] === 'P1' && ($row['subject'] === 'ພາສາລາວ' || $row['subject'] === 'ການອ່ານ')) {
                $laoG1Stars += $stars;
            } else if ($row['grade'] === 'P1' && $row['subject'] === 'ຄະນິດສາດ') {
                $mathG1Stars += $stars;
            } else if ($row['grade'] === 'P2' && $row['subject'] === 'ພາສາລາວ') {
                $laoG2Stars += $stars;
            } else if ($row['grade'] === 'P2' && $row['subject'] === 'ຄະນິດສາດ') {
                $mathG2Stars += $stars;
            }
        }

        $toUnlock = [];
        if ($laoG1Stars >= 3) $toUnlock[] = 'ຍອດນັກອ່ານ ປ.1';
        if ($laoG2Stars >= 3) $toUnlock[] = 'ຍອດນັກອ່ານ ປ.2';
        if ($mathG1Stars >= 3) $toUnlock[] = 'ນັກຄິດໄວ ປ.1';
        if ($mathG2Stars >= 3) $toUnlock[] = 'ນັກຄິດໄວ ປ.2';
        if ($totalStars >= 10) $toUnlock[] = 'ດາວເດັ່ນຮຽນເກັ່ງ';
        if ($totalStars >= 15) $toUnlock[] = 'ແຊມປ້ຽນຫຼຽນທອງ';
        if ($totalStars >= 25) $toUnlock[] = 'ແຊມປ້ຽນຫຼຽນເງິນ';
        if ($totalStars >= 35) $toUnlock[] = 'ແຊມປ້ຽນຫຼຽນຄຳ';
        if ($completedCount >= 25) $toUnlock[] = 'ອັດສະລິຍະຕົວນ້ອຍ';

        if (count($toUnlock) > 0) {
            $placeholders = implode(',', array_fill(0, count($toUnlock), '?'));
            $sql = "UPDATE rewards SET is_unlocked = 1 WHERE user_id = ? AND reward_name IN ($placeholders)";
            $stmt = $db->prepare($sql);
            $stmt->execute(array_merge([$userId], $toUnlock));
        }

        echo json_encode(["status" => "success"]);
        break;

    case 'update_reward_unlock_status':
        $stmt = $db->prepare("UPDATE rewards SET is_unlocked = :status WHERE user_id = :userId AND reward_name = :name");
        $result = $stmt->execute([
            ':status' => (int)$input['isUnlocked'],
            ':userId' => (int)$input['userId'],
            ':name' => $input['rewardName']
        ]);
        echo json_encode($result ? 1 : 0);
        break;

    case 'get_user_progress_detailed':
        $userId = (int)$_GET['userId'];
        $sql = "SELECT p.id as progress_id, p.stars_earned, p.is_completed, p.last_played,
                       l.id as lesson_id, l.grade, l.subject, l.title, l.total_stars as max_stars
                FROM lessons l
                LEFT JOIN progress p ON l.id = p.lesson_id AND p.user_id = :userId";
        $stmt = $db->prepare($sql);
        $stmt->execute([':userId' => $userId]);
        echo json_encode($stmt->fetchAll());
        break;

    case 'reset_user_progress':
        $stmt = $db->prepare("DELETE FROM progress WHERE user_id = :userId AND lesson_id = :lessonId");
        $stmt->execute([':userId' => (int)$_GET['userId'], ':lessonId' => (int)$_GET['lessonId']]);

        $userId = (int)$_GET['userId'];
        $stmt = $db->prepare("SELECT SUM(stars_earned) as total FROM progress WHERE user_id = :userId");
        $stmt->execute([':userId' => $userId]);
        $row = $stmt->fetch();
        $totalScore = (int)$row['total'];

        $stmt = $db->prepare("UPDATE users SET score = :score WHERE id = :userId");
        $stmt->execute([':score' => $totalScore, ':userId' => $userId]);

        echo json_encode(["status" => "success"]);
        break;

    default:
        echo json_encode(["error" => "Invalid action specified."]);
        break;
}
?>
