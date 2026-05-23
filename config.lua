Config = {}

-- ============================================================================
-- GENERAL SETTINGS
-- ============================================================================

Config.Debug = false
Config.RelocationInterval = 240 -- Default: 240 (2 hours) // How often (in real minutes) Nazar relocates.
Config.NazarModel = "MP_FREEROAM_TUT_FEMALES_01" -- Gypsy/Romani style NPC; change as desired
Config.NazarHeading = 0.0
Config.Blip = {
    enabled = true,
    sprite = 187984275, -- blip_shop_fence (verified RedM hash)
    scale = 0.8,
    name = "Madam Nazar",
}
-- ============================================================================
-- NAZAR SPAWN LOCATIONS (Each location has its own props)
-- ============================================================================

Config.Locations = {
    {
        label = "Madam Nazar - Benedict Point",
        coords = vector4(-4967.2666, -3401.9023, 7.9598, 63.2981),
        props = {
            {
                model = "mp005_p_collectorwagon01",
                offset = vector3(1.0, -1.0, 0.0),
                heading = 260.0,
            },
        },
    },
    {
        label = "Madam Nazar - Roanoke Ridge",
        coords = vector4(2898.3071, 1328.6382, 47.1281, 256.2766),
        props = {
            --{
            --    model = "mp005_p_collectorwagon01",
            --    offset = vector3(2.0, -1.0, 0.0),
            --    heading = 90.0,
            --},
        },
    },
    {
        label = "Madam Nazar - Kamassa Swamps",
        coords = vector4(2579.1155, 782.7086, 82.8138, 70.7401),
        props = {
            --{
            --    model = "mp005_p_collectorwagon01",
            --    offset = vector3(2.0, -1.0, 0.0),
            --    heading = 90.0,
            --},
        },
    },
    {
        label = "Madam Nazar - Heartland",
        coords = vector4(1458.19, 811.48, 100.08, 320.41),
        props = {
            --{
            --    model = "mp005_p_collectorwagon01",
            --    offset = vector3(1.0, -1.0, 0.0),
            --    heading = 225.0,
            --},
        },
    },
    {
        label = "Madam Nazar - Cumberland Forest",
        coords = vector4(-30.2341, 1234.9790, 171.9288, 188.7564),
        props = {
            --{
            --    model = "mp005_p_collectorwagon01",
            --    offset = vector3(1.0, -1.0, 0.0),
            --    heading = 20.0,
            --},
        },
    },
    {
        label = "Madam Nazar - SW Valentine",
        coords = vector4(-616.7180, 531.6208, 93.6206, 209.5267),
        props = {
            --{
            --    model = "mp005_p_collectorwagon01",
            --    offset = vector3(1.0, -1.0, 0.0),
            --    heading = 130.0,
            --},
        },
    },
    --{
    --    label = "Big Valley",
    --    coords = vector4(-1577.58, 560.94, 143.12, 120.0),
    --    props = {
    --        {
    --            model = "mp005_p_collectorwagon01",
    --            offset = vector3(1.0, -1.0, 0.0),
    --            heading = 300.0,
    --        },
    --    },
    --},
    --{
    --    label = "Scarlett Meadows",
    --    coords = vector4(1122.73, -530.72, 71.93, 150.0),
    --    props = {
    --        {
    --            model = "mp005_p_collectorwagon01",
    --            offset = vector3(1.0, -1.0, 0.0),
    --            heading = 330.0,
    --        },
    --    },
    --},
    --{
    --    label = "Lemoyne - Rhodes Area",
    --    coords = vector4(1247.43, -258.46, 90.42, 60.0),
    --    props = {
    --        {
    --            model = "mp005_p_collectorwagon01",
    --            offset = vector3(1.0, -1.0, 0.0),
    --            heading = 240.0,
    --        },
    --    },
    --},
    --{
    --    label = "Great Plains",
    --    coords = vector4(-1070.48, -890.56, 47.88, 0.0),
    --    props = {
    --        {
    --            model = "mp005_p_collectorwagon01",
    --            offset = vector3(1.0, -1.0, 0.0),
    --            heading = 180.0,
    --        },
    --    },
    --},
    --{
    --    label = "Cumberland Forest",
    --    coords = vector4(516.82, 729.58, 115.83, 220.0),
    --    props = {
    --        {
    --            model = "mp005_p_collectorwagon01",
    --            offset = vector3(1.0, -1.0, 0.0),
    --            heading = 40.0,
    --        },
    --    },
    --},
    --{
    --    label = "Grizzlies East",
    --    coords = vector4(1098.75, 1191.16, 168.92, 330.0),
    --    props = {
    --        {
    --            model = "mp005_p_collectorwagon01",
    --            offset = vector3(1.0, -1.0, 0.0),
    --            heading = 150.0,
    --        },
    --    },
    --},
}

-- ============================================================================
-- FORTUNE TELLING
-- ============================================================================

Config.FortuneTelling = {
    enabled = true,
    cost = 5.00,   -- Cost in dollars for a fortune reading
    cooldown = 30,  -- Minutes cooldown between readings per player

    -- Fortunes - randomly selected. Some are just flavor text, others give hints.
    fortunes = {
        {
            text = "I see great riches in your future... but beware, the path is lined with thorns.",
            type = "generic",
            reward = nil,
        },
        {
            text = "The spirits whisper of a treasure buried near water... to the east, where the sun first touches the land.",
            type = "hint",
            reward = nil,
        },
        {
            text = "A dark shadow follows you, stranger. Keep your gun close and your friends closer.",
            type = "warning",
            reward = nil,
        },
        {
            text = "The cards reveal... unexpected fortune! The spirits favor you today.",
            type = "lucky",
            reward = { type = "money", amount = 2.50 },
        },
        {
            text = "I see a blizzard coming... not of snow, but of change. Prepare yourself.",
            type = "cryptic",
            reward = nil,
        },
        {
            text = "You carry the weight of the dead upon your shoulders. Perhaps it is time to lay them to rest.",
            type = "dark",
            reward = nil,
        },
        {
            text = "The stars align in your favor! Take this small token from the spirits.",
            type = "lucky",
            reward = { type = "item", item = "collectible_coin", amount = 1 },
        },
        {
            text = "A stranger watches you from afar. They mean you no harm... for now.",
            type = "mysterious",
            reward = nil,
        },
        {
            text = "I see love in your future, but also loss. Such is the way of the world.",
            type = "generic",
            reward = nil,
        },
        {
            text = "The earth hides secrets beneath your feet. You need only the right tools to uncover them.",
            type = "hint",
            reward = nil,
        },
        {
            text = "Destiny is a river, stranger. You cannot fight the current, only choose how to swim.",
            type = "philosophical",
            reward = nil,
        },
        {
            text = "The spirits are generous today! They bestow a small gift upon you.",
            type = "lucky",
            reward = { type = "money", amount = 5.00 },
        },
    },
}

-- ============================================================================
-- COLLECTOR ROLE ITEMS - Items Nazar sells
-- ============================================================================

Config.CollectorBag = {
    item = "collectors_bag",
    label = "Collector's Bag",
    price = 25.00,
    description = "Essential storage for collectibles. Required to begin the Collector path.",
}

-- ============================================================================
-- SHOP CATEGORIES
-- ============================================================================

Config.ShopCategories = {
    {
        id = "tools",
        label = "Collector Tools",
        icon = "🔧",
        items = {
            {
                item = "metal_detector",
                label = "Metal Detector",
                price = 50.00,
                description = "Detects buried metal objects and treasures nearby.",
                requiredItem = "collectors_bag",
            },
            {
                item = "refined_binoculars",
                label = "Refined Binoculars",
                price = 30.00,
                description = "High-quality binoculars for spotting collectibles at a distance.",
                requiredItem = "collectors_bag",
            },
            {
                item = "shovel",
                label = "Pennington Field Shovel",
                price = 20.00,
                description = "A sturdy shovel for digging up buried treasures.",
                requiredItem = "collectors_bag",
            },
            {
                item = "collectors_lantern",
                label = "Collector's Lantern",
                price = 15.00,
                description = "A specially modified lantern that reveals hidden markings.",
                requiredItem = "collectors_bag",
            },
        },
    },
    {
        id = "maps",
        label = "Treasure Maps",
        icon = "🗺️",
        items = {
            {
                item = "map_coins",
                label = "Coin Collection Map",
                price = 8.00,
                description = "Reveals the locations of rare coins in the area.",
                requiredItem = "collectors_bag",
            },
            {
                item = "map_arrowheads",
                label = "Arrowhead Collection Map",
                price = 8.00,
                description = "Points to locations of ancient arrowheads.",
                requiredItem = "collectors_bag",
            },
            {
                item = "map_jewelry",
                label = "Lost Jewelry Map",
                price = 10.00,
                description = "Leads to valuable lost jewelry pieces.",
                requiredItem = "collectors_bag",
            },
            {
                item = "map_bottles",
                label = "Antique Bottles Map",
                price = 6.00,
                description = "Reveals locations of rare antique bottles.",
                requiredItem = "collectors_bag",
            },
            {
                item = "map_fossils",
                label = "Fossil Collection Map",
                price = 12.00,
                description = "Points to locations of rare fossils.",
                requiredItem = "collectors_bag",
            },
            {
                item = "map_heirlooms",
                label = "Family Heirlooms Map",
                price = 10.00,
                description = "Reveals locations of valuable family heirlooms.",
                requiredItem = "collectors_bag",
            },
        },
    },
    {
        id = "supplies",
        label = "Supplies & Tonics",
        icon = "🧪",
        items = {
            {
                item = "health_tonic",
                label = "Health Tonic",
                price = 3.00,
                description = "Restores a portion of your health.",
                requiredItem = nil,
            },
            {
                item = "stamina_tonic",
                label = "Stamina Tonic",
                price = 3.00,
                description = "Restores a portion of your stamina.",
                requiredItem = nil,
            },
            {
                item = "deadeye_tonic",
                label = "Dead Eye Tonic",
                price = 4.00,
                description = "Restores a portion of your Dead Eye.",
                requiredItem = nil,
            },
            {
                item = "horse_medicine",
                label = "Horse Medicine",
                price = 5.00,
                description = "Heals your horse.",
                requiredItem = nil,
            },
        },
    },
    {
        id = "rare",
        label = "Rare Curiosities",
        icon = "💎",
        items = {
            {
                item = "tarot_card_pack",
                label = "Tarot Card Pack",
                price = 15.00,
                description = "A mysterious pack of tarot cards. What secrets do they hold?",
                requiredItem = nil,
            },
            {
                item = "crystal_ball_trinket",
                label = "Crystal Ball Trinket",
                price = 25.00,
                description = "A small crystal ball said to bring luck to its owner.",
                requiredItem = nil,
            },
            {
                item = "romani_charm",
                label = "Romani Protection Charm",
                price = 20.00,
                description = "An ancient charm said to ward off evil spirits.",
                requiredItem = nil,
            },
        },
    },
}

-- ============================================================================
-- COLLECTIBLES - Items players can sell TO Nazar
-- ============================================================================

Config.Collectibles = {
    -- Collections are worth more when sold as complete sets
    collections = {
        {
            id = "coins",
            label = "Coin Collection",
            icon = "🪙",
            setBonus = 1.5, -- 50% bonus for complete set
            items = {
                { item = "collectible_coin_1792_quarter", label = "1792 Quarter", sellPrice = 5.00 },
                { item = "collectible_coin_1797_half_eagle", label = "1797 Half Eagle", sellPrice = 8.00 },
                { item = "collectible_coin_1800_gold_dollar", label = "1800 Gold Dollar", sellPrice = 10.00 },
                { item = "collectible_coin_morgan_dollar", label = "Morgan Dollar", sellPrice = 6.00 },
                { item = "collectible_coin_liberty_seated", label = "Liberty Seated Half", sellPrice = 7.00 },
            },
        },
        {
            id = "arrowheads",
            label = "Arrowhead Collection",
            icon = "🏹",
            setBonus = 1.5,
            items = {
                { item = "collectible_arrow_agate", label = "Agate Arrowhead", sellPrice = 4.00 },
                { item = "collectible_arrow_bone", label = "Bone Arrowhead", sellPrice = 3.00 },
                { item = "collectible_arrow_obsidian", label = "Obsidian Arrowhead", sellPrice = 5.00 },
                { item = "collectible_arrow_quartz", label = "Quartz Arrowhead", sellPrice = 4.50 },
                { item = "collectible_arrow_raw_flint", label = "Raw Flint Arrowhead", sellPrice = 3.50 },
            },
        },
        {
            id = "jewelry",
            label = "Lost Jewelry Collection",
            icon = "💍",
            setBonus = 1.75,
            items = {
                { item = "collectible_jewel_emerald_ring", label = "Emerald Ring", sellPrice = 12.00 },
                { item = "collectible_jewel_gold_necklace", label = "Gold Necklace", sellPrice = 15.00 },
                { item = "collectible_jewel_ruby_bracelet", label = "Ruby Bracelet", sellPrice = 14.00 },
                { item = "collectible_jewel_sapphire_earring", label = "Sapphire Earring", sellPrice = 10.00 },
                { item = "collectible_jewel_diamond_brooch", label = "Diamond Brooch", sellPrice = 20.00 },
            },
        },
        {
            id = "bottles",
            label = "Antique Bottle Collection",
            icon = "🍾",
            setBonus = 1.5,
            items = {
                { item = "collectible_bottle_cognac", label = "Old Cognac Bottle", sellPrice = 3.00 },
                { item = "collectible_bottle_bourbon", label = "Aged Bourbon Bottle", sellPrice = 3.50 },
                { item = "collectible_bottle_gin", label = "London Gin Bottle", sellPrice = 2.50 },
                { item = "collectible_bottle_rum", label = "Caribbean Rum Bottle", sellPrice = 4.00 },
                { item = "collectible_bottle_absinthe", label = "Absinthe Bottle", sellPrice = 5.00 },
            },
        },
        {
            id = "fossils",
            label = "Fossil Collection",
            icon = "🦴",
            setBonus = 2.0,
            items = {
                { item = "collectible_fossil_tooth", label = "Fossilized Tooth", sellPrice = 8.00 },
                { item = "collectible_fossil_claw", label = "Fossilized Claw", sellPrice = 9.00 },
                { item = "collectible_fossil_shell", label = "Ancient Shell", sellPrice = 6.00 },
                { item = "collectible_fossil_bone", label = "Petrified Bone", sellPrice = 7.00 },
                { item = "collectible_fossil_amber", label = "Amber Specimen", sellPrice = 12.00 },
            },
        },
        {
            id = "heirlooms",
            label = "Family Heirlooms Collection",
            icon = "🏺",
            setBonus = 1.75,
            items = {
                { item = "collectible_heir_pocketwatch", label = "Antique Pocket Watch", sellPrice = 10.00 },
                { item = "collectible_heir_locket", label = "Gold Locket", sellPrice = 8.00 },
                { item = "collectible_heir_compass", label = "Brass Compass", sellPrice = 7.00 },
                { item = "collectible_heir_music_box", label = "Music Box", sellPrice = 12.00 },
                { item = "collectible_heir_war_medal", label = "Civil War Medal", sellPrice = 15.00 },
            },
        },
    },

    -- Individual rare items (not part of sets)
    individual = {
        { item = "collectible_coin", label = "Miscellaneous Coin", sellPrice = 2.00 },
        { item = "collectible_antique", label = "Antique Trinket", sellPrice = 3.00 },
        { item = "collectible_gemstone", label = "Raw Gemstone", sellPrice = 5.00 },
    },
}

-- ============================================================================
-- DIALOGUE LINES
-- ============================================================================

Config.Dialogue = {
    greeting = {
        "Ah, another soul drawn to the mysteries of the world... Welcome.",
        "I have been expecting you, stranger. The cards told me you would come.",
        "Step closer... I can see the curiosity burning in your eyes.",
        "The spirits guided you here. You are wise to follow them.",
        "Welcome, traveler. What brings you to old Nazar's camp?",
        "I sense a collector's spirit within you. Am I wrong?",
        "Come, come... I have wares that no other merchant can offer.",
        "The wind whispers your name to me. You seek something, yes?",
    },
    farewell = {
        "Until the spirits bring us together again...",
        "Safe travels, stranger. And remember — the dead see everything.",
        "Go now, but keep your eyes open. Treasures hide in plain sight.",
        "The cards will guide your path. Trust in them.",
        "Farewell. I shall be elsewhere when next you seek me.",
        "May the spirits watch over you on your journey.",
    },
    noBag = {
        "You need a Collector's Bag before you can truly begin this path.",
        "First, you must acquire my Collector's Bag. Then we can talk business.",
        "Without the Bag, you cannot carry what you find. Shall I sell you one?",
    },
    noMoney = {
        "The spirits demand payment, and so do I. Come back with more coin.",
        "Your pockets are as empty as a ghost town. Return when you have funds.",
        "I cannot give away my wares for free, stranger.",
    },
    purchase = {
        "A wise purchase. May it serve you well.",
        "Excellent choice. The spirits approve.",
        "Use it wisely, and it will reveal wonders to you.",
    },
    sellItem = {
        "Interesting... I shall add this to my collection.",
        "A fine specimen. Here is your payment.",
        "The spirits told me you would bring this. Well done.",
    },
    sellCollection = {
        "A complete collection! Magnificent! You have earned a generous reward.",
        "All pieces assembled... the spirits are most pleased. Here is your bonus.",
        "Remarkable work, collector! A full set deserves a full reward.",
    },
}

-- ============================================================================
-- NUI SETTINGS
-- ============================================================================

Config.NUI = {
    title = "Madam Nazar",
    subtitle = "Travelling Fortune Teller & Collector's Merchant",
    currencySymbol = "$",
}

-- ============================================================================
-- NOTIFICATION SETTINGS
-- ============================================================================

Config.Notifications = {
    duration = 5000,  -- milliseconds
}

-- ============================================================================
-- AMBIENT SETTINGS
-- ============================================================================

Config.Ambient = {
    music = true,
    campfireSmoke = true,
    firefliesAtNight = true,
}

-- ============================================================================
-- TREASURE HUNTING SYSTEM
-- ============================================================================

Config.TreasureHunting = {
    blip = {
        sprite = 2119977580,
        scale = 0.2,
        name = "Treasure Location",
    },
    digRadius = 3.0,
    digDuration = 5000,
    requireShovel = true,
    shovelItem = "shovel",
    mapUsedMessage = "You study the map carefully... A location has been marked.",

    -- Dig animation settings (verified working)
    dig = {
        shovel = "p_shovel02x",
        anim = { "amb_work@world_human_gravedig@working@male_b@idle_a", "idle_a" },
        bone = "skel_r_hand",
        pos = { 0.06, -0.06, -0.03, 270.0, 165.0, 150.0 },
    },
}

-- ============================================================================
-- MAP -> COLLECTION LINK
-- ============================================================================

Config.MapRewards = {
    ["map_coins"] = {
        collectionId = "coins",
        possibleRewards = {
            "collectible_coin_1792_quarter",
            "collectible_coin_1797_half_eagle",
            "collectible_coin_1800_gold_dollar",
            "collectible_coin_morgan_dollar",
            "collectible_coin_liberty_seated",
        },
    },
    ["map_arrowheads"] = {
        collectionId = "arrowheads",
        possibleRewards = {
            "collectible_arrow_agate",
            "collectible_arrow_bone",
            "collectible_arrow_obsidian",
            "collectible_arrow_quartz",
            "collectible_arrow_raw_flint",
        },
    },
    ["map_jewelry"] = {
        collectionId = "jewelry",
        possibleRewards = {
            "collectible_jewel_emerald_ring",
            "collectible_jewel_gold_necklace",
            "collectible_jewel_ruby_bracelet",
            "collectible_jewel_sapphire_earring",
            "collectible_jewel_diamond_brooch",
        },
    },
    ["map_bottles"] = {
        collectionId = "bottles",
        possibleRewards = {
            "collectible_bottle_cognac",
            "collectible_bottle_bourbon",
            "collectible_bottle_gin",
            "collectible_bottle_rum",
            "collectible_bottle_absinthe",
        },
    },
    ["map_fossils"] = {
        collectionId = "fossils",
        possibleRewards = {
            "collectible_fossil_tooth",
            "collectible_fossil_claw",
            "collectible_fossil_shell",
            "collectible_fossil_bone",
            "collectible_fossil_amber",
        },
    },
    ["map_heirlooms"] = {
        collectionId = "heirlooms",
        possibleRewards = {
            "collectible_heir_pocketwatch",
            "collectible_heir_locket",
            "collectible_heir_compass",
            "collectible_heir_music_box",
            "collectible_heir_war_medal",
        },
    },
}

-- ============================================================================
-- TREASURE DIG LOCATIONS
-- ============================================================================

Config.DigLocations = {
    vector3(400.9716, -1089.1300, 39.6279),
    vector3(456.6655, -1060.0736, 40.1778),
    vector3(521.3398, -988.9603, 39.9069),
    vector3(332.0839, -1284.9904, 42.8829),
    vector3(306.0123, -1293.4287, 43.3907),
    vector3(389.2981, -1252.4507, 39.8041),
    vector3(399.8220, -1253.8732, 39.8638),
    vector3(415.9579, -1262.3043, 39.6323),
    vector3(433.3168, -1294.8688, 39.9062),
    vector3(457.0831, -1274.1443, 40.2743),
    vector3(479.0607, -1320.9944, 40.9439),
    vector3(457.7410, -1363.1381, 43.3328),
    vector3(-1415.5463, -2158.3967, 41.5676),
    vector3(-1427.3551, -2194.8308, 41.3072),
    vector3(-1437.5967, -2216.2686, 41.0826),
    vector3(-1416.9313, -2240.8579, 10.7863),
    vector3(-1493.4634, -2111.3467, 54.2768),
    vector3(-1647.0840, -2438.6460, 40.3107),
    vector3(-1643.7906, -2430.2659, 39.7767),
    vector3(-1636.2517, -2419.2061, 39.8836),
    vector3(-1633.1461, -2405.7727, 42.3190),
    vector3(-3397.6997, -3314.5122, -7.2574),
    vector3(-3494.0442, -3220.0200, -11.6980),
    vector3(-3503.5828, -3195.9153, -11.4470),
    vector3(-3490.2715, -3179.5439, -11.6193),
    vector3(-4171.3525, -3443.6321, 35.0879),
    vector3(-4399.3755, -3880.1877, -26.2332),
    vector3(-3919.8567, -3925.3140, -18.3491),
    vector3(-3846.4736, -3929.9780, -24.0135),
    vector3(-3487.2002, -3463.8704, -2.1341),
}
