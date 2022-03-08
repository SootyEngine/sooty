# Sooty (0.1) (Godot4)
`WARNING: Currently under heavy construction.`
A dialogue engine for Godot4.

# Features
- Scripting language.
- Redesigned BBCode like system with Markdown features.
- Text animation system.
- Built with modding support in mind.

# Script
It's been rewritten multiple times, and may again in future.
```
// A comment.
=== start
	Dialogue without a speaker.
	
	john: Dialogue with a speaker.
	: This text continues with John as the speaker.
	This text has no speaker.
	: This text is John again, since he spoke last.
	"Mysterious Stranger": This name will be presented as is, without checking for a character class.
	
	Markdown like *italic*, **bold**, and ***bold italics*** can be used.
	As well as an [b;cyan;sparkle]Evolved BBCode System[] that aims to minimize typing and clutter.
	
	@score += 10 // '@' is for StringActions.
	
	@camera shake 10 // StringActions can be used to call object functions.
	
	// The following is equivalent to
	// State.day_of_week = pick({ "monday"=0, "tuesday"=1, "wednesday"=1, "thursday"=1, "friday"=5, "saturday"=10, "sunday"=10 })
	@day_of_week = pick monday:0 tuesday:1 wednesday:1 thursday:1 friday:5 saturday:10 sunday:10
	
	Dialogue with some options.
		<> Yes. [[@choice = yes]]
			Dialogue that occurs when 'Yes' is chosen.
			@score += 20
		<> No. [[@choice = no]]
		<> Take me to the options flow. => options_example
		<> Nevermind.
	
	// Conditionals
	{{score > 10}}
		Wow, nice score.
		Keep it up!
	
	Wow, nice score. {{score > 10}} // Or on a per line basis.
	
	// Match/switch statements.
	// Start with a '*'.
	{{*$day_of_week}}
		{{monday}} Monday funday.
		{{tuesday}} Tuesday shmusday.
		{{wednesday}} Wednesday shmednesday.
		{{thursday}} Thorsday boresday.
		{{friday}} Friday bye-day.
		{{saturday}} mary: Saturday caturday.
			paul: I can't wait for sunday.
		{{sunday}} paul: It's finally sunday!
			mary: I prefer saturdays.
	
	// Let's go to another node.
	>> conditionals

=== next_node
	
	// Lines can be skipped if they don't pass a condition.
	Thanks for choosing yes. {{choice == yes}}
	
	// Or you can do an if/elif/else ('if' keyword is optional)
	{{choice == yes}}
		You chose yes!
		@score += 10
	{{elif choice == no}}
		You chose no!
		@score += 1
	{{else}}
		You didn't make a choice!
		@score += 5
	
	// To call a flow's steps, and return back, we can use ::
	:: call_example
	
	// Access flows in other dialogues like so:
	:: other_dialogue.call
	
	// To call all flows starting with 'call_' use the '*'.
	:: call_*
	:: *_options // Or at the start, to call all flows ending with something.
	// Why would you do this? To make it easier to hook into mods, for one thing.
	// Check out the 'options_example'
	
	call_example is finished.
	
	>> properties_example

=== call_example
	Here is a call, that will return when complete.
	@score += 10

=== properties_example
	// Flows and lines can contain properties.
	// Either on the same line.
	// { text="Here is some text.", properties={ color="blue", offset=[16, 16] } }
	Here is some text. ((color:blue offset:16,16))
	
	// Or on the following lines by tabbing and using '|'.
	Maybe we want to temporarilly adjust some position.
		|color:blue
		|offset:16,16
		|x:0 y:-16 type:flash // Multiple properties can be on the same line.

=== options_example
	// Can call StringActions on the same line.
	// These two choices would play the same.
	Are you sure?
		<> Yes [[@play ding; @choice = yes]] >> next_node
			Okay then, let's go.
		<> Yes
			@play ding
			@choice = yes
			Okay then, let's go.
			>> next_node
	
	// Options can have conditionals, like any other line.
	Greetings stranger.
		<> I'm here for the gold. {{mission_started}}
		<> I've got what you needed. {{player.apples > 10}}
		<> I'm looking for a quest. {{not mission_started}}
		<> What's on the menu?
		<> Actually, nevermind.
	
	// They can take '>>' to control flow.
	guide: Where to?
		<> West. >> west
			guide: All right, westward ho.
		<> East. >> east
			guide: To the east we go then.
		<> Take me the secret route. {{heard_of_secret_route}} >> north
			guide: Hmm, how'd you hear of that?
	// The flow will change at the end of the options lines.
	
	// Anything can go inside the '<>', and will be passed to the game as a 'flag'.
	// You may find it useful to mark options with commonly used features.
	goon: Looking to fight?
		<STR> I'll pummel you. {{strength > 10}}
		<CHR> I'd rather not. {{charisma > 10}}
		<> Look, isn't their some other way?
		<> Hey, ugh, whats over there?
	
	// Options can be imported from other flows.
	// Why? For making modding tie ins easier.
	What will you choose?
		:: other_options_* // This will take the options from 'other_options_1' and 'other_options_2'
		<> The Apple
		<> The Pear

=== other_options_1
	<> The Grapefruit
	<> The Cantelope

=== other_options_2
	<> The Blueberries

// BBCode Evolved.
=== bbcode
	// Close tags with [].
	The [b]King[] has spoken.
	
	// Use any color as a tag and combine tags with ';'.
	Those [tomato;i]apples[] and [deep_sky_blue;i]blueberries[] look good.
	
	// Include a State variable with '$'. These tags are self closing, but can still fit others.
	My name is [$strangers_name;b;green_yellow]. What is yours?
	// Variables can be nested: '$player.stats.wisdom'
	// Variables can be piped to functions with '|': '$player.coins|commas' will call 'commas(player.coins)'.
	// Add pipes to StringAction.pipes: StringAction.pipes[id] = my_function
	
	// Include StringActions that will be called only when the text comes up.
	Hey... wait a minute![@camera zoom 1.25;wait] I thought you said... [wait][@camera zoom 1.5;@camera tilt 15]You lied to me!
	
	// Wait with [wait] or [w]. (Self closing.)
	Let me think[wait].[w].[w].[w=2] Okay, i've got it!
	
	// Change pace with [pace] or [p] (Self closing.)
	[pace=0.25]I'm getting tired... why is the room spinning.
	
	// Skip the animation forward, so entire words are faded in at once.
	I said [skip]DONT[][w] [skip]WASTE[][w] [skip]MY[][w] [SKIP]TIME![]
	
	// Hold the animation till the user presses something. (Self closing.)
	He knelt down to the body.[hold] Cold. It had been here a while.[hold] The killer was long gone.
	
=== string_actions
	// String actions can be used to change State variables or call functions.
	// They attempt to minimize typing, by using spaces as seperators, and not using brackets.
	
	// The following is equivalent to camera("shake", 1.0, { "time": 3, "pixels": 16 })
	@camera shake 1.0 time:3 pixels:16
	
	// The following is equivalent to camera.shake(1.0, { "time": 1 })
	@camera.shake 1.0 time:1
	
	// The following is equivalent to State.score += 1
	@score++
	// Or
	@score += 1
	
```

# BBCode

# Modding
todo: At bootup, show list of discovered mods, with toggles. Save state to config.
	After clicking accept, selected mods are loaded.
	Need to reboot to uninstall mods.
