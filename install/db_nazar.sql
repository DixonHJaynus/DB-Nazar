-- ============================================================================
-- DB-Nazar Database Tables
-- ============================================================================

CREATE TABLE IF NOT EXISTS `db_nazar_state` (
    `id` INT(11) NOT NULL DEFAULT 1,
    `location_index` INT(11) NOT NULL DEFAULT 1,
    `last_relocation` BIGINT(20) NOT NULL DEFAULT 0,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Insert default row
INSERT IGNORE INTO `db_nazar_state` (`id`, `location_index`, `last_relocation`) VALUES (1, 1, 0);

CREATE TABLE IF NOT EXISTS `db_nazar_transactions` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `citizenid` VARCHAR(50) NOT NULL,
    `transaction_type` VARCHAR(50) NOT NULL COMMENT 'purchase, sell, sell_collection, fortune',
    `item` VARCHAR(100) NOT NULL,
    `amount` INT(11) NOT NULL DEFAULT 1,
    `price` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_citizenid` (`citizenid`),
    INDEX `idx_transaction_type` (`transaction_type`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
