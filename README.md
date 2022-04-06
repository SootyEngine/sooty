# Sooty `0.1` `Godot4`
A dialogue engine for Godot4 (alpha5).

`WARNING: Currently under **heavy** construction.`

- *Visual Novel* template [here](https://github.com/teebarjunk/sooty-visual_novel).  
- Example visual novel [here](https://github.com/teebarjunk/sooty-visual_novel-example).  

![](https://raw.githubusercontent.com/teebarjunk/sooty-example/main/README/preview.png)

![](readme/code_preview.png)

# Features
- Scripting language with highlighter.
- `BBCode Evolved®` with Markdown features.
- Advanced text animation system.
- Built with modding support in mind.
- Built with localization in mind.

# Check Out:
- [Getting Started](readme/getting_started.md)
- [Writing Soot](readme/writing_soot.md)

# Text and BBCode
Checkout the BBCode section of [Writing Soot](readme/writing_soot.md#bbcode).

![](readme/bbcode.png)

# Actions
![](readme/actions.png)

|Char|Description|Example|
|----|-----------|-------|
|`~`|State expression.|`~score += pow(20, 2)` == `State.score += pow(20, 2)`|
|`$`|State call.|`$player.damage 10 type:water` == `State.player.damage(10, {"type":"water"})`|
|`@`|Group call.|`@camera.shake false y:0.5` == `get_nodes_in_group("camera").shake(false, {"y":0.5})`|

Action calls are bracket-less `()` and comma-less `,` except for arrays: `$reset player,john,mary 100 health,exp` == `State.reset(["player", "john", "mary"], 100, ["health", "exp"])`

## Operator Overloads

State has basic support for operation overloads.

Look at the *VStat* class `VStat.gd`:
```
var value = 0

func _operator_get():
	return value

func _operator_set(x):
	value = x
```
This allows us to do `stat += 1` instead of `stat.value += 1`

# Conditionals
![](readme/ifelse.png)

# The State System - Saving, Loading, and Modding.
Create a script in `res://states` that extends any `Node`.  
On startup, Sooty will add all scripts in this folder as children of the `State` node.  
All of their properties and functions are now accessible to the scripting system.

```
# state.gd
extends Node

var score := 0

func my_score():
    return "[b]%s[]" % score

func boost_score(amount := 1):
    score += amount


# story.soot
My score is [$my_score].
$boost_score 1234567
My score plus 1,234,567 is [$score].
```

Sooty will automatically save any values that changed, and only values that changed.

*WARNING:* Properties across scripts should be unique, as only the first property with a name will ever be returned.

```
# If you do this, only one of these properties will be saved, and accessible through State.

#characters.gd
var fields := Character.new({name="Mr. Fields"})

#locations.gd
var fields := Location.new({name="The Fields"})
```

The `State` class has signals you may find useful:  

|Signal|Desc|
|------|----|
|changed(property: String)|Property that was changed.|
|changed_to(property: String, to: Variant)|Property that was changed and what it was changed to.|
|changed_from_to(property: String, from: Variant, to: Variant)|Property that was changed, it's old value, and it's new value.|

*WARNING:* Property string may be "paths": `"player.stat.STR"`

## Save System

Any kind of property can be saved, including built in Godot types like Vector2 and Color, and even complex Objects and Resources.  
For each Object/Resource, a dictionary of properties (only those that have changed) will be saved.  
Arrays of Objects/Resource aren't currently savable.

If you add a property `var save_caption := "Save Name"` it will be shown on the save screen. This could be used to indicate to the player what location, mission, or progress, the slot's data contains. It could contain BBCode.

## Modding
The state system was entirely designed with modding/expansions/patches in mind.  

User mods can have their own folder in `user://mods`.  
Notice the [Visual Novel](https://github.com/teebarjunk/sooty-visual_novel) system treats itself as a "mod".

Inside that directory can be directories for:

|Folder|File type(s)|Desc|
|:-----|-----------:|:---|
|`dialogue/`| `*.soot`|Dialogue files.|
|`states/`| `*.gd`|Node scripts contain state data.|
|`persistent/`| `*gd`|Node scripts containing persistent state data.|
|`scenes/`| `.tscn` `.scn`|Scenes accessed by name.|
|`audio/music/`| `.wav` `.mp3`, `.ogg`|Music.|
|`audio/sfx/`| `.wav` `.mp3`, `.ogg`|Sound effects.|

# Soot Script

Script names are used internally as the `Dialogue` id. They contain *Flows*, which start with `===`.
- `=>` Goes to a chapter.
- `==` Goes to a chapter, then returns to this line when completed.
- `><` Ends the flow.

```
// my_story.soot
=== START
    Once upon a time.
    => chapter_1

=== chapter_1
    There lived a dog.
    => other_chapters.chapter_2


// other_chapters.soot
=== chapter_2
    The dog was a fast runner.
```

# Localization Files `.sola`  
You can generate `.sola` files for translating text.  
It's getting robust.  
It can handle replacing multiple lines with 1 or 1 line with mutiple.

|`res://test.soot`|`res://test-fr.soot`|
|--|--|
|![](readme/lang_1.png) | ![](readme/lang_2.png)|

# Data Files `.soda`
Sooty has a custom file format based on YAML, but designed for Godot.  
It has a built in highlighter, and works in Godot's main editor.  
Store the files in `states` or `persistent` to have them autoload.
- From Godot `State.characters.paul.name`.
- From Sooty `$characters.paul.name`

Shortcuts take the form `$name: path.to.object.or.property.or.function`, and allow accessing nested data more easily.  
So instead of `Hey [$characters.bill.name].`, just `[$bname]` or whatever.  

![](readme/data_1.png)
![](readme/data_2.png)

# Building/Exporting
Make sure to include `*.soot,*.soda,*.sola` files when building.
