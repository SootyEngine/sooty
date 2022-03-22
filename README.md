# Sooty `0.1_unstable` `Godot4`
A dialogue engine for Godot4.

`WARNING: Currently under **heavy** construction.`

Example project [here](https://github.com/teebarjunk/sooty-example).
![](https://raw.githubusercontent.com/teebarjunk/sooty-example/main/README/preview.png)

![](readme/code_preview.png)

# Features
- Scripting language with highlighter.
- `BBCode Evolved®` with Markdown features.
- Advanced text animation system.
- Built with modding support in mind.
- Built with localization in mind.

# Text and BBCode
![](readme/bbcode.png)

Tags:
Any number of tags can be housed together in the same brackets: `[b;tomato]Bold Red Text[]`

Calling `[]` closes the last tag chain. `[/]` closes all open tags chains.

Some tags are self closing.

|tag|desc|options|
|---|----|-------|
|*color_name*|Use any built in Godot color name: `[deep_sky_blue]Blue Text[]` ||
|(n,n,n,n)|RGBA color. For use with format: `"[%s]text[]" % Color.TEAL`||
|*float*|Multiply current font size: `Speak [i;0.8]very quietly[].`||
|*int*|Add to current font size: `Speak [i;4]very loudly[].`||
|`dim`|Dims color by 33%.||
|`lit`|Lightens color by 33%.||
|`hue` `sat` `val`|Modify hue/sat/val of color.||
|`:emoji_name:` `:)`|Tags wrapped in `::` will use the emoji.<br>Some old fashioned emojis are supported. `[:)]`,||
|`\|pipe`|Will pipe text through a function.||
|`@group call` `$state call` `~expression`|Inserts returned value at this position.<br>Will auto close any style it's wrapped with:<br>`The [$stranger;b;red] looks at you.`<br>Can be piped to a function. `[$player.coins\|commas]`||
|`lb` `rb`|Insert brackets *[]*||

Along with typical: `b` `i` `bi` `u`

*Animation specific tags.*

|tag|desc|options|
|---|----|-------|
|`wait`|Pause the animation.|`[w]` `[wait]` `[w=2]`|
|`hold`|Hold animation till user action.|`[h]` `[hold]`|
|`jump`|Jump animation forward. So entire word or phrase can pop in.<br>`I already told you [jump]NO[][w] [jump]MORE[][w] [jump]LEAVING MY THINGS OUT![][w]`
|`pace`|Change pace of animation.|`[p]` `[pace]` `[p=2]`|
|`!@group call` `!$state call` `!~expression`|Call any [action](#actions) at that point in the animation.||

*Custom text effects*<br>**TODO**

Try combining emojis and animations: `Press the [2.0;sin;:arrow_up:;] key!`<br>
This will double the scale, play the sin wave animation, show the up arrow emoji, and then close.

## Pipes
Values can be piped through functions: `You have [$apples|commas] apples.` -> `You have 1,234,567 apples.`

So can text: `I have [|commas]1234567[] apples.` -> `I have 1,234,567,apples.`

Any function defined in a node in the `states` folder will be accessible. You can spread functions across multiple scripts/nodes, but if there are multiple with the same name, only the first will be used.

## Shortcuts
In `config.cfg` you can set shortcuts for complex actions and custom colors:

```cfg
[rich_text_shortcuts]
cam1="!@camera shake 2.0;!@camera zoom 2.0;wait=0.5"
cam_reset="!@camera shake 0.0;!@camera zoom 1.0
highlight="cherry;b;u"
pscore="$player.score|commas;b;greeny

[rich_text_colors]
cherry="#FF9053"
greeny="#BBEE32"
```

Now use them like any other BBCode.

```
My score\: [pscore] points.
john: These [cherry]cherries[] sure look good. [cam1]Wait, these aren't cherries.[cam_reset] They're blueberries.
```

# Actions
![](readme/actions.png)

|Char|Description|Example|
|----|-----------|-------|
|`~`|State expression.|`~score += pow(20, 2)` == `State.score += pow(20, 2)`|
|`$`|State call.|`$player.damage 10 type:water` == `State.player.damage(10, {"type":"water"})`|
|`@`|Group call.|`@camera.shake false y:0.5` == `get_nodes_in_group("camera").shake(false, {"y":0.5})`|

Action calls are bracket-less `()` and comma-less `,` except for arrays.

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

*WARNING:* Properties across scripts should be unique, as they are accessed on a first come first serve basis.

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

*WARNING:* Property string may be "nested": `"player.stat.STR"`

## Save System

Any kind of property can be saved, including built in Godot types like Vector2 and Color, and even complex Objects and Resources.  
For each Object/Resource, a dictionary of properties (only those that have changed) will be saved.  
Arrays of Objects/Resource aren't currently savable.

If you add a property `var save_caption := "Save Name"` it will be shown on the save screen. This could be used to indicate to the player what location, mission, or progress, the slot's data contains. It could contain BBCode.

## Modding
**TODO**  
The state system was entirely designed with modding/expansions/patches in mind.  

Mods should each have their own folder in `user://mods`.

Inside that directory can be directories for:

|Folder|File type(s)|Desc|
|:-----|-----------:|:---|
|`dialogues/`| `*.soot`|Dialogue files.|
|`states/`| `*.gd`|Node scripts contain state data.|
|`states_persistent/`| `*gd`|Node scripts containing persistent state data.|
|`scenes/`| `.tscn` `.scn`|Scenes accessed by name.|

# Localization
**TODO**  
End of line comment of form `//#unique_line_id`<br>
These can be auto generated.


# Building/Exporting
Make sure to include `*.soot,*.cfg` files when building.
