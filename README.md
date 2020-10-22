# onset-rpg7

### Setup
* Download the package
* Extract it in your packages
* Rename it
* Install [Particles](https://github.com/vugi99/onset-particles) (You need to load the particles package before the rpg7 package)
* Add this to your weapons.json
```
		{
			"Name": "RPG",
			"RateOfFire": 30.0,
			"Damage": 0.0,
			"Range": 0.0,
			"Recoil": 0.05,
			"MagazineSize": 1,
			"CameraShake": 0.2,
			"CameraShakeCrouching": 0.1,
			"SpreadMin": 0.1,
			"SpreadMax": 4.0,
			"SpreadMovementModifier": 0.2,
			"SpreadCrouchingModifier": -0.3
		}
```
* Config the package in the config.lua file
* Give the weapon 22 (by default) to a player
* OPTIONAL : Increase the object stream distance to ~25000 in the server_config.json