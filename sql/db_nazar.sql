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

-- ============================================================================
-- ITEMS - Add these to your RSG Core shared items
-- You will need to add these items to your rsg-core/shared/items.lua
-- ============================================================================

-- Example items to add to rsg-core shared items:
-- ['collectors_bag']           = { name = 'collectors_bag',           label = "Collector's Bag",           weight = 500,  type = 'item', image = 'collectors_bag.png',           unique = true,  useable = true,  shouldClose = true,  description = 'Essential storage for collectibles.' },
-- ['metal_detector']           = { name = 'metal_detector',           label = 'Metal Detector',            weight = 1000, type = 'item', image = 'metal_detector.png',           unique = true,  useable = true,  shouldClose = true,  description = 'Detects buried metal objects.' },
-- ['refined_binoculars']       = { name = 'refined_binoculars',       label = 'Refined Binoculars',        weight = 500,  type = 'item', image = 'refined_binoculars.png',       unique = true,  useable = true,  shouldClose = true,  description = 'High-quality binoculars for spotting collectibles.' },
-- ['shovel']                   = { name = 'shovel',                   label = 'Pennington Field Shovel',   weight = 1500, type = 'item', image = 'shovel.png',                   unique = true,  useable = true,  shouldClose = true,  description = 'A sturdy shovel for digging.' },
-- ['collectors_lantern']       = { name = 'collectors_lantern',       label = "Collector's Lantern",       weight = 300,  type = 'item', image = 'collectors_lantern.png',       unique = true,  useable = true,  shouldClose = true,  description = 'Reveals hidden markings.' },
-- ['map_coins']                = { name = 'map_coins',                label = 'Coin Collection Map',       weight = 50,   type = 'item', image = 'map_coins.png',                unique = false, useable = true,  shouldClose = true,  description = 'Reveals rare coin locations.' },
-- ['map_arrowheads']           = { name = 'map_arrowheads',           label = 'Arrowhead Collection Map',  weight = 50,   type = 'item', image = 'map_arrowheads.png',           unique = false, useable = true,  shouldClose = true,  description = 'Points to ancient arrowheads.' },
-- ['map_jewelry']              = { name = 'map_jewelry',              label = 'Lost Jewelry Map',          weight = 50,   type = 'item', image = 'map_jewelry.png',              unique = false, useable = true,  shouldClose = true,  description = 'Leads to valuable lost jewelry.' },
-- ['map_bottles']              = { name = 'map_bottles',              label = 'Antique Bottles Map',       weight = 50,   type = 'item', image = 'map_bottles.png',              unique = false, useable = true,  shouldClose = true,  description = 'Reveals rare antique bottles.' },
-- ['map_fossils']              = { name = 'map_fossils',              label = 'Fossil Collection Map',     weight = 50,   type = 'item', image = 'map_fossils.png',              unique = false, useable = true,  shouldClose = true,  description = 'Points to rare fossils.' },
-- ['map_heirlooms']            = { name = 'map_heirlooms',            label = 'Family Heirlooms Map',      weight = 50,   type = 'item', image = 'map_heirlooms.png',            unique = false, useable = true,  shouldClose = true,  description = 'Reveals valuable family heirlooms.' },
-- ['health_tonic']             = { name = 'health_tonic',             label = 'Health Tonic',              weight = 200,  type = 'item', image = 'health_tonic.png',             unique = false, useable = true,  shouldClose = true,  description = 'Restores health.' },
-- ['stamina_tonic']            = { name = 'stamina_tonic',            label = 'Stamina Tonic',             weight = 200,  type = 'item', image = 'stamina_tonic.png',            unique = false, useable = true,  shouldClose = true,  description = 'Restores stamina.' },
-- ['deadeye_tonic']            = { name = 'deadeye_tonic',            label = 'Dead Eye Tonic',            weight = 200,  type = 'item', image = 'deadeye_tonic.png',            unique = false, useable = true,  shouldClose = true,  description = 'Restores Dead Eye.' },
-- ['horse_medicine']           = { name = 'horse_medicine',           label = 'Horse Medicine',            weight = 300,  type = 'item', image = 'horse_medicine.png',           unique = false, useable = true,  shouldClose = true,  description = 'Heals your horse.' },
-- ['tarot_card_pack']          = { name = 'tarot_card_pack',          label = 'Tarot Card Pack',           weight = 100,  type = 'item', image = 'tarot_card_pack.png',          unique = false, useable = true,  shouldClose = true,  description = 'Mysterious tarot cards.' },
-- ['crystal_ball_trinket']     = { name = 'crystal_ball_trinket',     label = 'Crystal Ball Trinket',      weight = 200,  type = 'item', image = 'crystal_ball_trinket.png',     unique = true,  useable = true,  shouldClose = true,  description = 'Said to bring luck.' },
-- ['romani_charm']             = { name = 'romani_charm',             label = 'Romani Protection Charm',   weight = 50,   type = 'item', image = 'romani_charm.png',             unique = true,  useable = true,  shouldClose = true,  description = 'Wards off evil spirits.' },
-- ['collectible_coin']         = { name = 'collectible_coin',         label = 'Miscellaneous Coin',        weight = 10,   type = 'item', image = 'collectible_coin.png',         unique = false, useable = false, shouldClose = false, description = 'A collectable coin.' },
-- ... (add all collectible items similarly)
