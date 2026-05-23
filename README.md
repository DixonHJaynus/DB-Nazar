# DB-Nazar - Madam Nazar Travelling Merchant

A fully featured Madam Nazar travelling merchant script for RedM (RSG Core Framework).

## Features

- **Travelling NPC**: Madam Nazar moves to a new location every 24 hours (configurable)
- **12+ Spawn Locations**: Scattered across the map for variety
- **Collector's Shop**: Buy tools, maps, supplies, and rare curiosities
- **Sell Collectibles**: Sell individual items or complete collections for bonus rewards
- **Fortune Telling**: Pay for a fortune reading with random outcomes (some give rewards!)
- **Beautiful NUI**: Dark mystical themed UI with smooth animations
- **ox_target Integration**: Clean interaction system
- **Transaction Logging**: All purchases and sales logged to database
- **Admin Commands**: Teleport, force relocate, check location
- **Anti-Cheat**: Server-side price validation
- **Performance Optimized**: Distance-based NPC spawning/despawning

## Dependencies

- [rsg-core](https://github.com/Starter-Store/rsg-core)
- [ox_target](https://github.com/overextended/ox_target)
- [oxmysql](https://github.com/overextended/oxmysql)

## Installation

1. Place `DB-Nazar` folder in your resources directory
2. Import `sql/db_nazar.sql` into your database
3. Add items from the SQL file comments to your `rsg-core/shared/items.lua`
4. Add `ensure DB-Nazar` to your `server.cfg`
5. Configure `config.lua` to your liking

## Admin Commands

| Command | Description | Permission |
|---------|-------------|------------|
| `/nazarteleport` | Teleport to Nazar's current location | admin |
| `/nazarrelocate` | Force Nazar to move to a new location | admin |
| `/DBNazar.blip` | Display Nazar's current location | admin |

## Configuration

All settings are in `config.lua`:
- Relocation interval (default: 24 hours)
- Spawn locations (add/remove as needed)
- Shop items and prices
- Collectible collections and set bonuses
- Fortune telling text and rewards
- Dialogue lines
- Blip settings
- NPC model

## Notes

- NPC models and prop models may need adjustment based on your server's available assets
- Collectible items need to be added to your RSG Core shared items
- Coordinates may need fine-tuning based on your map
- The NUI uses Google Fonts (Cinzel & Crimson Text) — ensure your server allows external font loading

## License

Free to use and modify. Credit appreciated but not required.
