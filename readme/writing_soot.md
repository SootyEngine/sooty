# Writing Soot

To get syntax highligting in Godot, open the file in editor and select `Edit > Syntax Highlighter > Soot`

![](highlighter.png)

|Pattern|About|Example|
|-----|-----|-------|
|`// comment`|These are just for you, and are ignored by the system.|`// TODO: Rewrite these lines.`|
|`=== flow id`|The start of a flow; a series of steps to run through.|`=== chapter_1`|
|`text`|Text to show the user.|`Once upon a time...`|
|`name: text`|Text with a speaker.|`robot: Are you sure about this?`|
|`- option text`|An option for a menu.|`- Yes, take me there.`|
|`=> flow_id`|Goto a flow.|`=> chapter_2`|
|`=> soot_id.flow_id`|Goto a flow in a different file.|`=> day_2.morning`|
|`== flow_id`|Call a flow, then return back to this line.|`== describe_scene`|
|`== soot_id.flow_id`|Call a flow in a different file, then return back to this line.|`== funcs.reset_stats`|
|`@action`|Call's a node group function.|`@damage player 20 fire:true`|
|`$action`|Call's a state function.|`$player.damage 20 fire:true`|
|`~state evaluation`|Evaluates an expression on state data.|`~score += 20 * score_multiplier(player.stats)`
|`{{condition}}`|For only displaying lines that pass.|`mary: Oh wow, you brought it. {{talked_to_mary and player.item_count("spoon") > 1}}`|

# Flow Control

To go to another flow in the file, use `=> other_flow`.

To call another flow, and then return to where we are, use `== other_flow`.  
This is useful for having common lines:

```
=== monday
    == start_of_day
    Time to get to class.
    // do a bunch of stuff here
    == end_of_day
    
=== tuesday
    == start_of_day
    Today is the big day.
    // do a bunch of stuff here
    == end_of_day

=== start_of_day
    ~money_at_start = money
    Today is {{time.day_of_week}}.

=== end_of_day
```~money_earned = money - money_at_start
    {{money_earned > 0}}
        I earned [~money_earned] today.
    {{elif money_earned < 0}}
        I lost [~-money_earned] today.
    {{else}}
        I didn't make any money today.
```

# Dialogue

```
Text without a speaker. 

// Speakers.
john: Text spoken by John.
: Text spoken by last speaker, John.

// Markdown formatting.
Some *italic*, **bold** and ***bold italic*** text.

// BBCode.
Some [b;tomato]bold red text[] and some [i;deep_sky_blue]italic blue text.[]

// Inserting state values to text.
The current score is [$score;b;cyan].

// Effecting the animation.
We can pause[wait] the text.
We can hold until the user presses something.[hold] And then show some more text.
We can [pace=2]speed up the speed of the speaker.[pace=0.25] Or slow it down.

// Calling actions at points in the animation.
Actions can be called at a point [!@camera zoom 2.0]. Got it?
Like any other tag [!@camera zoom;!@camera shake;!~score += 20] you can combine multiple in one.

// Multiline text.
""""
You can place *lots* of formatted text in one block.
        *Tabs*
            will
                be
                    preserved.

As will **whitespace**.
""""

// Multiline with a speaker and condition.
paul: """" {{score > 20}}
I don't care what [b]they[] say, it's not happening.

    (He turned to look at the shore.)

Not now, not ever.
""""
```

# Speakers
Text with a `:` before it will have a speaker tag: `mary: What year is it?`

Multiple speakers can be included with a space: `john mary jane paul: We all agree!`

Speaker names will be auto styled with state data:
```
# my_state.gd

var john := Character.new({name="John", color=Color.DEEP_SKY_BLUE})
```

But you can wrap a name in `"` to have it as is: `"[b;gray]Mysterious Stranger[]": Howdy.`

If you want a `:` in a users name, escape it with a `\:`.

# BBCode Evolved

Tags:  
Any number of tags can be chained together with `;` in the same brackets: `[b;tomato]Bold Red Text[]`

Calling `[]` closes the last tag chain. `[/]` closes all open tags chains.

Some tags are self closing.

|Tag|Description|Options|
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
||||
|`cuss`|||
|`heart`|||
|`jit` `jit2`|||
|`jump` `jump2`|||
|`l33t`|||
|`off`|||
|`rain`|||
|`sin`|||
|`sparkle`|||
|`uwu`|||
|`wave`|||
|`woo`|||

Along with typical: `b` `i` `bi` `u`

*Animation specific tags.*

|Tag|Description|Options|
|---|----|-------|
|`wait`|Pause the animation.|`[w]` `[wait]` `[w=2]`|
|`hold`|Hold animation till user action.|`[h]` `[hold]`|
|`jump`|Jump animation forward. So entire word or phrase can pop in.<br>`I already told you [jump]NO[][w] [jump]MORE[][w] [jump]LEAVING MY THINGS OUT![][w]`
|`pace`|Change pace of animation.|`[p]` `[pace]` `[p=2]`|
|`!@group call` `!$state call` `!~expression`|Call any [action](#actions) at that point in the animation.||

*Custom fade ins*<br>**TODO**

|Tag|Description|Options|
|`back`|||
|`console`|||
|`fader`|||
|`focus`|||
|`prickle`|||
|`redact`|||
|`wfc`|||

*Custom text effects*<br>**TODO**

Try combining emojis and animations: `Press the [2.0;sin;:arrow_up:;] key!`<br>
This will double the scale, play the sin wave animation, show the up arrow emoji, and then close.

## Pipes
Values can be piped through functions that you've defined in any `res://states` class: `You have [$apples|commas] apples.` -> `You have 1,234,567 apples.`

So can text: `I have [|commas]1234567[] apples.` -> `I have 1,234,567,apples.`

You can spread functions across multiple scripts/nodes, but if there are multiple with the same name, only the first will be used.

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

# Options

To add options to dialogue, tab lines below, starting with a `-`.

```
Are you sure about that?
    - Yes.
    - No.
    - Maybe.
```

Options can have `{{conditionals}}`

```
guard: Sorry, can't let you in without the password.
    - Doop a doop. {{has_password}}
        guard: Hmm.
        @sfx door_clanking_open
        => enter_the_club
    - Uhm... err... quack-quack?
        guard: Get the hell out of here.
        => back_to_street
    - Oh, well, I don't know it.
        => back_to_street
```

You can write dialogue underneath these lines, so long as it's tabbed.

```
journey_man: Where to, traveler?
    - East.
        We go eastward.
        @sfx wind_002
        => east
    - West.
        We go westward.
        @sfx dust_storm
        => west
    - North.
        journey_man: The cost north is extra. Will you pay?
            - Yes, here you go. {{money >= 5}}
                $money -= 5
            - I don't have money, but I need to get there. {{money < 5}}
                journey_man: Meh, all right, let's go.
                => north
            - Hmm, nevermind.
                journey_man: Suit yourself.
        
```

You can place a `=>` on the same line, for convenience.  
If there are tabbed lines, the `=>` will be called last.

```
Where to?
    - East => east
    - West => west
    - North => north
        All right, north we go.
```

While not advisable, as it's hard to read, you can use `(())` and `;;` to write tabbed lines on the same line.

```
Where to?
    - East. ((man: All right, east we go. ;; @sfx east ;; $dir = "east" )) => east
    - North. ((man: Okay, north it is. ;; @sfx north ;; $dir = "north")) => north
```

# Conditionals

|Condition|Description|Example|
|---------|-----------|-------|
|`{{if}}`|The classic *if* statement. You don't need to type *if* though.|`{{if apples > oranges}}` `{{apples > oranges}}`|
|`{{elif}}`|If the previous condition failed, this one will be checked.|`{{elif apples > pears}}`|
|`{{else}}`|If all other conditions failed, this will occur.`{{else}}`|
|`{{match}}`|A condensed pattern.||


## Match

Check out the Godot [tutorial](https://docs.godotengine.org/en/latest/tutorials/scripting/gdscript/gdscript_basics.html#match).

Sometimes they can be a lot nicer/neater that if-else statements.

```
{{*time.weekday}}
    {{MONDAY}} @sfx sad_audio
    {{TUESDAY}} john: Glad [b]mondays[] over.
    {{WEDNESDAY}} It's the middle of the week.
    {{THURSDAY}}
        john: The whole vibe shifts on thursday!
    {{FRIDAY}} @sfx happy_audio
        john: Aw yeah, friday!
    {{_}} It's the weekend.
```
