# Getting Started
Check out the [example](https://github.com/teebarjunk/sooty-example) project.

- Create a `scenes` folder. These will be the main game scenes. They can be nested in folders.
- Create a scene like `area1.tscn`.
- Add a `SootScene` component to it.
- Create a `dialogue` folder. This is where all `*.soot` files need to be. They can be nested in folders.
- Create a script like `area1.soot`.

```
=== START
    Welcome to Area 1.
```

Now play your scene and the text should appear.

Check out [Writing Soot](/writing_soot.md) for more info on scripting.

# Adding Node Actions
There are two ways the `@` action works:

*Without a period:* `@action true 2.0`  
For every node in the *SceneTree* that is part of group `sa:action`, it's `func action():` will be called with `[true, 2.0]`.

*With a period:* `@group.function true 2.0`  
For every node in the *SceneTree* that is part of group `group`, it's `func function():` will be called with `[true 2.0]`.

When doing dialogue, you can include actions in `()` brackets:

```
john (jump): What was that!

// is like doing:

@john.jump
john: What was that!
```

Nodes can be part of as many groups as you like:

```
extends Node

func _init():
    add_to_group("sa:action")
    add_to_group("sa:reset")
    add_to_group("fade_in")
    add_to_group("fade_out")

func action():
    pass

func reset():
    pass

func fade_in():
    pass

func fade_out():
    pass
```

You could have group *john* and group *mary* and both are part of group *john_and_mary*:

```
@john.jump
john: What was that?

@mary.jump
mary: I heard it too!

@john_and_mary.jump
john mary: Woah!
```

# Adding State Data
State data is what will be saved from play to play. Things like score, health, character stats, achievements, unlockables...

|Type|Data that will...|Examples|Folder|Autoload|
|----|-----------|:------:|:----:|:-----------------------:|
|Temporary|Change on each playthrough.|Score<br>Health<br>Stats|`res://states`|`State`|
|Persistent|Stay the same regardless of playthrough.|Achievements<br>Unlockables|`res://states_persistent`|`Persistent`|

Simply create one or more scripts in the appropriate folder, extending any *Node*, and initialize like any other variable.  
These nodes are created at startup and added to their autoload (State or Persistent) and should only be accessed through their Autoload parent.

```
# my_states.gd
extends Node

var score := 0
var my_name := "Traveler"
var health := 100
var has_key_1 := false
var has_key_2 := false
var has_key_3 := false
var has_prize := false

func boost_score(amount := 1):
    score += amount

func has_all_keys() -> bool:
    return has_key_1 and has_key_2 and has_key_3
```

Now we can access these in a `.soot` dialogue.

```
=== the_rabbits_keys
    
    You come across the rabbit.
    
    {{has_all_keys()}}
        {{not has_prize}}
            rabbit: You got them all, [$my_name]! Good job.
            ~has_prize = true
            $boost_score 20
        {{else}}
            rabbit: Good job finding those keys.
    {{else}}
        rabbit: I need those keys!
    
    
```
