-- 1. Create Database if not exists
CREATE DATABASE IF NOT EXISTS edu_app CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE edu_app;

-- 2. Create Users Table (Simplified - only Name, Phone, Password, Avatar, Score, CreatedAt)
CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  phone VARCHAR(100) NOT NULL,
  password VARCHAR(255) DEFAULT '',
  avatarId INT DEFAULT 1,
  score INT DEFAULT 0,
  createdAt VARCHAR(100) DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Create Lessons Table
CREATE TABLE IF NOT EXISTS lessons (
  id INT AUTO_INCREMENT PRIMARY KEY,
  grade VARCHAR(50) DEFAULT '',
  subject VARCHAR(255) DEFAULT '',
  title VARCHAR(255) DEFAULT '',
  total_stars INT DEFAULT 3
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Create Progress Table
CREATE TABLE IF NOT EXISTS progress (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  lesson_id INT NOT NULL,
  stars_earned INT DEFAULT 0,
  is_completed INT DEFAULT 0,
  last_played VARCHAR(100) DEFAULT '',
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (lesson_id) REFERENCES lessons(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. Create Rewards Table
CREATE TABLE IF NOT EXISTS rewards (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  reward_name VARCHAR(255) NOT NULL,
  image_path VARCHAR(255) DEFAULT '',
  is_unlocked INT DEFAULT 0,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
