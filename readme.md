# AFK System

This is a plugin for shavit's bhoptimer that manages inactive players and saves their timer states. 

## Configuration / CVars

```bash
afk_punishment_type "1" - 1 = move to spectator, 2 = kick

afk_time "180" - This is the amount of time in seconds that a user needs to be inactive to get promted the AFK menu.

afk_time_to_wait "60" - Time after map start for the AFK system to start working. 

afk_update_interval "10" - How often should the plugin check for player movement?

afk_save_timer "1" - Should the players be allowed to resume to their pre-afk timer state? 0 = disabled

```


## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License
[GPL v3](https://www.gnu.org/licenses/gpl-3.0.en.html)