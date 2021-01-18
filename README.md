# Respector

A Cyberpunk 2077 mod for managing player builds in the form of spec files 
containing player experience, attributes, skills, perks, and equipment.

- Transfer your character and equipment between save games
- Try different builds switching them on the fly
- Share your own builds and try others
- Create item packs (eg. "All Stash Wall Weapons")

This mod allows for a kind of New Game Plus mode. 
You can try each life path while keeping the experience gained from other playthroughs,
replay the same mission with different abilities and equipment,
etc.

## Requirements

- [CyberEngineTweaks](https://github.com/yamashi/CyberEngineTweaks) 1.8.3
- Cyberpunk 2077 1.0.6

## Installation

Drop the mod dir into `<Cyberpunk 2077>/bin/x64/plugins/cyber_engine_tweaks/mods`.

## Usage

### Specs

The main concept of the mod is the spec file. Spec defines: 

- Character Level
- Street Cred
- Attributes
- Skills and their progression
- Perks
- Unused points
- Equipment
  * Items with attachments and mods
  * Assignment to the slot
- Crafting components
- Crafting recipes

By default, specs are stored in the `specs` directory of the mod.

Spec files are human readable and designed to be created and edited manually. 
In the `samples/specs` directory you can find sample specs 
with comments explaining some details about spec features.

Currently, when saving the spec, it will only contain equipped items and not other items in the inventory.
However, there is no such limitation when loading the spec.
You can manually add to the spec items that are not assigned to any equipment slot.
All items will be added to inventory as expected.

### Packs

Every section of the spec file is optional and can be omitted. 
For example, it's possible create the spec containing only items, 
thus allowing creation a kind of item packs.

In the `samples/packs` directory you can find packs of different categories. 
To get stuff from a pack just drop it to the `specs` directory and then load the spec you want.
These packs can also be used as a reference to find the ID of item of intereset.
All items have in-game names, and many of them even have full descriptions and stats.

### Console

There are two ways to access mod functions:

1. Using global `Game` object.
2. Using `GetMod("respector")`.

#### `Game.LoadSpec(specName)`

Loads spec named `specName`.

Calling without parameters `Game.LoadSpec()` will load spec with a default name from the [configuration](#configuration) is used.

#### `Game.SaveSpec(specName, specOptions)`

Saves spec with the name `specName` and using `specOptions`.

If name is empty or `nil`, then the default name from the [configuration](#configuration) is used.

Overwrites a spec file with the same name if existing.

Available options for `specOptions` are: <a name="spec-options"></a>

| Option | Values | Default | Description |
| :--- | :---: | :---: | :--- |
| `itemFormat`       | `"auto"`,&nbsp;`"hash"` | `"auto"` | The preferred ItemID format for use in item specs:<br>`"auto"` &ndash; Use item name whenever possible.<br>`"hash"` &ndash; Always use a struct with hash and length values (eg. `{ hash = 0x026C324A, length = 27 }`). |
| `keepSeed`         | `"auto"`,&nbsp;`"always"` | `"auto"` | How to save the RNG seed in item specs:<br>`"auto"` &ndash; Save the seed only for items that can be randomized.<br>`"always"` &ndash; Always write the seed for all items. |
| `exportAllPerks`   | `bool` | `false`  | If enabled, all perks will be saved in the spec, including those not purchased. If disabled, only purchased perks will be saved. |
| `exportComponents` | `bool` | `true`   | If disabled, crafting components will not be added to the spec. |
| `exportRecipes`    | `bool` | `true`   | If disabled, crafting recipes will not be added to the spec. |
| `timestamp`        | `bool` | `false`  | If enabled, saves the spec with a name appended with the current date and time (eg. `V-201210-042037`). Useful to never overwrite existing spec files, only create new ones. |

Any particular option and `specOptions` parameter itself can be omitted. In this case, the default option values will be used. The defaults for most of the options can be changed in the [configuration](#configuration).

For example, `Game.SaveSpec("Legend", { itemFormat = "hash", exportRecipes = false, timestamp = true })`  will create a spec named `Legend-210105-142037` (assuming it's January 5, 2021, 14:20) containing everything but crafting recipes and having hash values for item IDs instead of names.

Calling without parameters `Game.SaveSpec()` will save the spec with a default name, overwriting the existing one, and using all default options.

#### `Game.SaveSpecSnap()`

Saves spec with a default name appended with the current date and time. Has the same results as `Game.SaveSpec(nil, { timestamp = true })` but is slightly shorter.

### GUI

The mod has a simple GUI that allows you to save and load specs.

![CP2077 Respector GUI](https://siberx.dev/cp2077-respector/gui-1-save-spec.png) ![CP2077 Respector GUI](https://siberx.dev/cp2077-respector/gui-2-load-spec.png)

Also, you can change where to store specs, the default spec name, and hotkeys for use with GUI.

![CP2077 Respector GUI](https://siberx.dev/cp2077-respector/gui-3-options.png)

The GUI is disabled by default. If you want to use the GUI, you need to enable it in the [configuration](#configuration).

### Configuration

The configuration is stored in the `config.lua` file in the mod directory.

| Parameter | Default | Options | Description |
| :--- | :---: | :---: | :--- |
| `specsDir`         | `""`     | `string` | The directory for storing spec files. Can be any location outside of the mod (eg. `D:\Games\Cyberpunk 2077\Specs`). If empty then the `specs` dir of the mod is used. |
| `defaultSpec`      | `"V"`    | `string` | The defalt spec name. Used when saving and loading without specifying a spec name (aka quick saving an quick loading). |
| `itemFormat`       | `"auto"` | `"auto"`,&nbsp;`"hash"` | The default value for `itemFormat` option when saving specs. See [spec options](#spec-options) for details. |
| `keepSeed`         | `"auto"` | `"auto"`,&nbsp;`"always"` | The default value for `keepSeed` option when saving specs. See [spec options](#spec-options) for details. |
| `exportAllPerks`   | `false`  | `bool` | The default value for `exportAllPerks` option when saving specs. See [spec options](#spec-options) for details. |
| `exportComponents` | `true`   | `bool` | The default value for `exportComponents` option when saving specs. See [spec options](#spec-options) for details. |
| `exportRecipes`    | `true`   | `bool` | The default value for `exportRecipes` option when saving specs. See [spec options](#spec-options) for details. |
| `useModApi`        | `true`   | `bool` | Enables API access using `GetMod()`. |
| `useGlobalApi`     | `true`   | `bool` | Enables mod functions in the global `Game` object. |
| `useGui`           | `false`  | `bool` | Enables the GUI. |
| `openGuiKey`       | `0x70`   | `int`  | Hotkey to open / close the GUI. Default is F1. You can find key codes [here](https://docs.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes). |
| `saveSpecKey`      | `0x71`   | `int`  | Hotkey to save spec with currently selected options in the GUI. Default is F2. You can find key codes [here](https://docs.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes). |

A copy of the config file with default values can be found at `samples/config/defaults.lua`.

## Known Issues

- Loading the spec in the character menu will play a sound effect for each purchased perk at the same time, 
  causing one overloaded, distorted and unpleasant sound. This depends on the number of perks acquired. 

## TODO

- More samples with comments.
- Ability to manage the individual stats of the weapon.
- Ability to export all items in the inventory.
- Ability to export vehicles owned by the player. 
- Better GUI with the list of available specs and ability to select them for saving and loading.
