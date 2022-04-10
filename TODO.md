
# Bugs
- [ ] .soot multiline strings `""""` have an issue with tabs.
- [ ] Caption name showsup a second before hiding.
- [x] ~~temp_save tries to save on editor quit.~~
- [x] Changing scenes ends the stack.
- [x] Reloading dialogue stopped working.
- [x] Quitting doesn't hide captions.

# Bad Design
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

- [x] Remove `.` from `EXT_*` properties.
- [x] Rename Achievement to Award.
- [x] Data parser.
- [x] Container Awards, Tasks, and other things in collections, rather than state.
- [x] Move UI/console and fonts to `VisualNovel` addon.

# State
- [ ] Custom `Bool` class for managing a single state bool.

# *.soot Dialogue Files
- [ ] define step types in Soot
- [ ] inserts for choices
- [ ] inserts for actions?

- [x] Don't be file bound.
    - [x] Let multiple files contribute to the same dialogue.
    - [x] And let a single file contribute to multiple dialogues.
- [x] `|>` as 'option' head
- [x] `+>` as 'add options' head
- [x] `||` as 'underline' divider
- [x] `((array_type))` array pattern
    - [x] line array pattern
        ```
        (())
            line 1
            line 2
            line 3
            ==||lineset line 1
                lineset line 2
                lineset line 3
        ```
    - [x] text array pattern (multiple may exist in one text.)
        ```
        text line ((array_type | option1 | option2 | option 3)) other text. ((array_type|option 1|option2|option3)).
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
- [ ] Match arrays pattern.
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
- [ ] `.soma` -> BBCode parser.
- [ ] `text/` folder to load from.
- [ ] Highlighter.

# Highlighters
- `.soot`
    - [ ] Highlight `IGNORE` yellow
    - [x] Markdown * ** ***
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
    - [ ] Seperate'indicator' into it's own agnostic scenes
    - [ ] Seperate 'speaker' and 'caption' field into their own seperate scenes

- Notifications
    - [ ] Task/Quest notification.
    - [ ] Inventory gained/lost.
- Save
    - [ ] Total time played.
- [ ] Warn when starting a new game that progress will be lost.
- [ ] Better HUD system for pause menu and such.

### Captions
- [x] Mouse over options to hover.
- [x] Click an option to select.

## Sprites
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
