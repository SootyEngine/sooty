# Sooty `0.1_unstable` `Godot4`
A dialogue engine for Godot4.

`WARNING: Currently under **heavy** construction.`

![](readme/code_preview.png)

# Features
- Scripting language with highlighter.
- `BBCode Evolved®` with Markdown features.
- Advanced text animation system.
- Built with modding support in mind.
- Built with localization in mind.

# Screenshots

## Text and BBCode
![](readme/bbcode.png)

Tags:
Any number of tags can be housed together in the same brackets: `[b;tomato]Bold Red Text[]`

Calling `[]` closes the last tag chain. `[/]` closes all open tags chains.

Some tags are self closing.

|tag|desc|options|
|---|----|-------|
|*color_name*|Use any built in Godot color name: `[deep_sky_blue]Blue Text[]` ||
|(n,n,n,n)|RGBA color. For use with format: `"[%s]text[]" % Color.TEAL`||
|*number*|Any number will be added/subtracted to the font size.||
|`wait`|Pause the animation.|`[w]` `[wait]` `[w=2]`|
|`hold`|Hold animation till user action.|`[h]` `[hold]`|
|`pace`|Change pace of animation.|`[p]` `[pace]` `[p=2]`|
|`~action`|Can call any [action](#action) at that point in the animation.||
|`$property`|Inserts the value of a state.<br>Can be piped to a function. `[$player.coins\|commas]`||
|`[lb]` `[rb]`|Insert brackets *[]*||

Along with typical: `b` `i` `bi` `u`

## Actions
![](readme/actions.png)

Starting with a `~` actions can do a number of things.

Actions are bracket-less `()` and comma-less `,` except for arrays.
```
// for node in get_tree().get_nodes_in_group("camera"):
//		node.camera("shake", 10, { "rotate": true })
~camera shake 10 rotate:true

// State.player.damage("fire", 10, { "rand": [2, 3 ] })
~$player.damage fire 10 rand:2,3

// for strings with spaces, use ""
// State.player.set_name("The Lone Wanderer")
~$player.set_name "The Lone Wanderer"

// to state variables inside a function, use $
// State.enemy.damage("head", 2, 10)
~$enemy.damage $player.target $damage_modifier 10
```

Modify state variables, and call state functions, with `$`
```
~$score += 20
~$player.damage 10
```

## Conditionals
![](readme/ifelse.png)

# Modding
todo: At bootup, show list of discovered mods, with toggles. Save state to config.
	After clicking accept, selected mods are loaded.
	Need to reboot to uninstall mods.

# Localization
todo

# State and Persistent Data
Initialize state variables in "res://state.gd".
- Characters
- World states

Initialize persistent variables in "res://persistent.gd"
- Achievements
- Unlockables

# Exporting
Make sure to include "*.soot,*.cfg" files when exporting.
