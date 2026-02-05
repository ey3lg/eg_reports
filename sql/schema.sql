DROP TABLE IF EXISTS `eg_report_history`;
DROP TABLE IF EXISTS `eg_report_comments`;
DROP TABLE IF EXISTS `eg_reports`;
DROP TABLE IF EXISTS `eg_reports_archived`;

CREATE TABLE IF NOT EXISTS `eg_reports` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `reporter_identifier` VARCHAR(100) NOT NULL,
    `reporter_name` VARCHAR(100) NOT NULL,
    `category` VARCHAR(50) NOT NULL,
    `priority` VARCHAR(20) NOT NULL,
    `status` VARCHAR(20) DEFAULT 'open',
    `title` VARCHAR(255) NOT NULL,
    `description` TEXT NOT NULL,
    `location` VARCHAR(255) NULL,
    `evidence` TEXT NULL,
    `assigned_to` VARCHAR(100) NULL,
    `assigned_to_name` VARCHAR(100) NULL,
    `rating` TINYINT(1) NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `closed_at` TIMESTAMP NULL,
    INDEX `idx_status` (`status`),
    INDEX `idx_reporter` (`reporter_identifier`),
    INDEX `idx_assigned` (`assigned_to`),
    INDEX `idx_created` (`created_at`),
    INDEX `idx_category` (`category`),
    INDEX `idx_priority` (`priority`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `eg_reports_archived` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `original_report_id` INT NOT NULL,
    `reporter_identifier` VARCHAR(100) NOT NULL,
    `reporter_name` VARCHAR(100) NOT NULL,
    `category` VARCHAR(50) NOT NULL,
    `priority` VARCHAR(20) NOT NULL,
    `status` VARCHAR(20) NOT NULL,
    `title` VARCHAR(255) NOT NULL,
    `description` TEXT NOT NULL,
    `location` VARCHAR(255) NULL,
    `evidence` TEXT NULL,
    `assigned_to` VARCHAR(100) NULL,
    `assigned_to_name` VARCHAR(100) NULL,
    `rating` TINYINT(1) NULL,
    `created_at` TIMESTAMP NULL,
    `updated_at` TIMESTAMP NULL,
    `closed_at` TIMESTAMP NULL,
    `deleted_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `deleted_by` VARCHAR(100) NULL,
    `deleted_by_name` VARCHAR(100) NULL,
    INDEX `idx_assigned` (`assigned_to`),
    INDEX `idx_created` (`created_at`),
    INDEX `idx_deleted` (`deleted_at`),
    INDEX `idx_rating` (`rating`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `eg_report_comments` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `report_id` INT NOT NULL,
    `author_identifier` VARCHAR(100) NOT NULL,
    `author_name` VARCHAR(100) NOT NULL,
    `content` TEXT NOT NULL,
    `is_internal` TINYINT(1) DEFAULT 0,
    `is_staff` TINYINT(1) DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`report_id`) REFERENCES `eg_reports`(`id`) ON DELETE CASCADE,
    INDEX `idx_report` (`report_id`),
    INDEX `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `eg_report_history` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `report_id` INT NOT NULL,
    `action` VARCHAR(100) NOT NULL,
    `actor_identifier` VARCHAR(100) NOT NULL,
    `actor_name` VARCHAR(100) NOT NULL,
    `details` TEXT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (`report_id`) REFERENCES `eg_reports`(`id`) ON DELETE CASCADE,
    INDEX `idx_report` (`report_id`),
    INDEX `idx_created` (`created_at`),
    INDEX `idx_action` (`action`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
