- [ ] Toggle private/public flows visibiliy in chapter view.
- [ ] ~~`../` for going up a path, not `..`~~
/   = Root directory
.   = This location
..  = Up a directory
./  = Current directory
../ = Parent of current directory
../../ = Two directories backwards
- `Goal` should get a `/states/_goals/` folder that can store `.soot` for more advanced goals
- [x] `~` highlighting not working
- [ ] Chapter list `#.rank:` for sorting
- [ ] Chapter list `>` `v` for toggling subflow visibility
- [ ] Chapter list copy highlighter colors for tabs (yellow for top, then purple...)
- [ ] Chapter list tags, for filtering
- [ ] `{{else}}` below options menu, for if they have no options to show
- [x] Highlighter in match case works weird
- [x] Richtext tab view
- [x] Only load VisualNovelUI when `~` is pressed, to save on startup load time.
- [x] Fix `.flow` in dialogues.
- [x] Auto load `config`
- [ ] Signal that `config` can fire if it was reloaded.
- [ ] Use `^` for `self`
- [ ] Conditions are evals and assume `$` unless `@` or `^` is used.

# Shrinking database use
- [ ] Only load flow paths at first? Then lazy load rest?
- [ ] Store lines by speaker, and as arrays?

# Bugs
- [ ] .soot multiline strings `""""` have an issue with tabs.
- [x] Caption name showsup a second before hiding.
- [x] ~~temp_save tries to save on editor quit.~~
- [x] Changing scenes ends the stack.
- [x] Reloading dialogue stopped working.
- [x] Quitting doesn't hide captions.

# Bad Design
- [ ] Use Godots built in filesystem to detect file changes for reloading mods.
- [ ] New `soot` file creation isn't detected.
- [ ] Come up with seperate system for runteim, that manages all subfolders at once.
- [ ] Optional obfuscation/encrypt for `soot` `soda` and save data?
- [x] Persistent data loaded before mods loaded.

# Docs
- [x] Create gitpages docs.
- [x] Move .md to gitpages.

# Sooty
- [ ] Agnosticize dialogue system so it can be used for Quests and States instead of just dialogue.
    - [ ] Seperate DialogueStack into FlowStack and DialogueStack.
    - [ ] Agnosticize Choices system so it can be used for other types of user input, like popups.
    - [x] Change `text` lines to `keyval`.
    - [x] Handle DialogueLine in VisualNovel.
- ~~[ ] Swap how `@:` is for objects and `@.` for functions, the other way around.~~
- [x] Remove `.` from `EXT_*` properties.
- [x] Rename Achievement to Award.
- [x] Data parser.
- [x] Container Awards, Tasks, and other things in collections, rather than state.
- [x] Move UI/console and fonts to `VisualNovel` addon.

# RichTextLabel
- [ ] Font tag should check if any bold/italic state is set, if it has an `_i.tres` `_b.tres` `_bi.tres` available.
- [ ] Font image folder, for images that can be shown in fonts with a quick tag.
- [ ] Effects based on mouse position
- [ ] Hint effect that fades on mouse over

# State
- [ ] `Mods` add signal `collect_mods` which will request paths, instead of current system.
- [x] Custom `Bool` class for managing a single state bool.

# Inspector
- [x] Show an inspector with chapter overview
- [ ] Add `sort` option for chapter overview
    - [ ] progress
    - [ ] words/length
- [ ] Use chapter meta data to contain color info for side panel
- [ ] Show meta in side panel, if toggle is active

# *.soot Dialogue Files
- [ ] Somehow show emojis in autocomplete?
- [ ] Define step types in Soot
- [ ] Inserts for choices
- [ ] Inserts for actions?
- [x] Seperate editors from plugin script.
- [x] Don't be file bound.
    - [x] Let multiple files contribute to the same dialogue.
    - [x] And let a single file contribute to multiple dialogues.
- [x] `>>>` as 'option' head
- [x] `+>>` as 'add options' head
- [x] `||` as 'underline' divider
- [ ] List type `flow` which pulls lines from a flow.
- [x] `{<array_type>}` list pattern
    - [x] line array pattern
        ```
        {<>}
            line 1
            line 2
            line 3
            ==||lineset line 1
                lineset line 2
                lineset line 3
        ```
    - [x] text array pattern (multiple may exist in one text.)
        ```
        text line <array_type | option1 | option2 | option 3> other text. <array_type|option 1|option2|option3>.
        ```
    - [ ] text selector pattern nesting (DO LATER.)
- [x] `==` same line pattern
    ```
    my text
    ==
        my flow in line
        line 2
    back outside
    ```
- [x] Match arrays pattern.
- [ ] Match dict pattern.
- [ ] Make flags work on nested data.
- [ ] ~~meta pattern should be processed as `soda`?~~
- [x] `#.` meta pattern.
- [x] ~~`IGNORE` flag to skip files.~~ Changed to `#.IGNORE`
- [x] Flags for ignoring lines.
- [x] Multi file loading from mods. (not tested)
- [x] Reimplement `+` as a dialogue option for merging external options.
- [x] Change comments from `// ` to `# `.

## Flow
- [ ] move 'if' and 'match' to custom functions 
## DialogueStack
- [x] `><` Should only end one flow.
- [x] `>><<` For ending dialogue.
- [x] `__` For pass/do nothing. (Useful for inserting lines later with `#id=insert_here`)

# *.sola Language Files
- [x] Keep old data even if it's line was removed.
- [x] Generate `.sola` files with previous data, so nothing is lost.
- [x] Only merge as a `== flow call` if there are more than one.
- [x] Multiline id's.
- [x] Load and merge langs files.
- [x] Generate `.sola` files, for writing translations.

# *.soda Data Files
- [ ] Outputed text arrays/dicts aren't colorized when on the same line.
- [ ] Soda files in `lang/` with language prefix: `vars-en.soda` for replacing states without adding any.
- [ ] Allow or `.` paths inside single key.
- [ ] Translation loading when mods are loaded.
- [ ] Generate translation file that ignores objects/dicts/arrays.
- [ ] `#meta:` meta keys.
    - [ ] `#.:` to define a location all keys are inside. ie `#.: items`
- [ ] `\,` escapes
- [ ] Shortcuts for functions that take arguments.
- [x] `?` flag key.
- [x] `$` shortcut key.
- [x] `.soda` debug viewer.
- [x] Dictionary -> `.soda` text function.
- [x] Highlighter.
- [x] Create data format file based on YAML.
- [ ] ~~Translation key `prop_name-lang:`~~

# *.soma Markdown File
- [ ] Create file format based on Markdown for showing more complicated text like notebooks, item info, world story data...
- [x] ~~`.soma` -> BBCode parser.~~ Use/override `soot` highlighter.
- [ ] `text/` folder to load from.

# Editors
- `.soot`
    - [x] Actions
        - [x] Node actions
        - [x] State actions
        - [x] Persistent state actions
        - [x] Enums
        - [x] Custom objects
    - [50%] ctrl click on `===` `---` to toggle line hiding
    - [ ] Show available `kwarg` keys.
        When at last element or further, check if its `kwargs`
        Then look in function info for a `kwargs` dict, and display all
        - [ ] Check for already inputted kwargs.
        - [ ] Insert kwarg with it's default.
    - [ ] Auto complete for `<list|pattern>`
    - [x] Evals
    - [x] Actions in bbcode
    - [x] Evals in bbcode
    - [x] Emojis when inside `::`
    - [x] Only show autocomple in `~@^$` and bbcode.
    - [x] Basic autocomplete

# Highlighters
- `.soot`
    - [ ] Highlight `IGNORE` yellow
    - [x] Tint text based on bbcode
    - [ ] Don't highlight arguments after `/` if inside a string
    - [ ] Do bbcode tags:
        - [x] `hue`
        - [x] `dim` `lit`
        - [ ] `dima`  `lita`
    - [x] Markdown * ** ***
- [ ] Move `type` to `M` meta.
- [x] Match statements on same line aren't colored.
- [x] `+` options isn't colored
- [x] Colorize `/` in `=>` `==` paths.
- [x] `=>` and `==` should by symbols.
- [x] Colorize [and if else or == !=] in condition brackets {{}} as symbols.
- `.sola`
    - [x] `<?>`
    - [x] comments not working.
    - [x] shortcuts.
- [x] Auto apply script highlighter to files.

# UFile
- [x] Add `_on_files(dir: String, call: Callable)` function. To make collecting on a pattern easier.
- [x] `file_exists_in_dir()`: Check for a file inside a directory.
- [x] `get_file_in_dir(tail)`: Get a path to a possibly nested file ending in tail.

# VisualNovel
- [x] Seperate UI from backend.
- [ ] Use state objects to parse text/speaker. `_preparse_caption` `_preparse_caption_name`
- [ ] ~~Create theme templates for captions + options.~~
- [x] Character can control string wrappes `"` (For phones and such.)
- [x] Captions use node function `@show_caption`
- [x] Include fonts folder.
- [x] Include input mapping in main project.
- [x] UI screen that hides when dialogue is shown.
- [x] BUG: ui_caption doesn't go away when the final flow step is a menu.
- [x] SootScene remove debug prints.
- [x] SootButton shouldn't call if no "action" is set.
- [x] SootButton add class_name.
- [x] SootScene "Open *.soot" button should allow file to be nested.
- [x] Remove SE_SootScene

## UI
- Captions
    - [ ] ~~Seperate'indicator' into it's own agnostic scenes~~ Draw indicator with a RichTextEffect somehow.
    - [x] Seperate 'speaker' and 'caption' field into their own seperate scenes

- Notifications
    - [ ] Task/Quest notification.
    - [ ] Inventory gained/lost.
- Save
    - [ ] Total time played.
- [ ] Warn when starting a new game that progress will be lost.
- [ ] ~~Better HUD system for pause menu and such.~~
- [ ] Create really simple dummy menus that can be "overriden" by simply having a replacement in a `/scene/` folder

### Captions
- [x] Mouse over options to hover.
- [x] Click an option to select.

## Sprites
- [ ] Add resource for taking a snapshot of a position, scale, rotation, and color. Then call a function to lerp there.
- [x] Add hide() function to immediately set modulate.a = 0.0.

# Docs
- [ ]

# TreeView
- [ ] Include state objects some how.
    - [ ] Every bool int and str?
- [ ] Shrink minimap.
- [ ] Change dead ends to black instead of red, to prevent confusing with `><` and `>><<`.
- [ ] Meta info tab to show:
    - [ ] Total estimated time.
    - [ ] Total words.
    - [ ] Total words per character.
    - [ ] Total branches.
    - [ ] Auto count possible routes.
    - [ ] Timer per route.
    - [ ] Characters in route.

# Printers
- [x] Seperate text printers and options menu.

# Text Parsing
- [ ] Printer that can show text across multiple captions.
- [ ] Using RichTextEffect.pre_parse() for pre parsing strings.
- [x] Use `/` instead of `.` for sub flows.

# Other
- [in progress] generate a node map so it's visible where everything is.
- [ ] Save file sorting by:
    - time since last played.
    - total time played.
    - progress.
