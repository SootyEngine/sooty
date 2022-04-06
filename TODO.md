
# Bugs
- [ ] temp_save tries to save on editor quit.
- [ ] .soot multiline strings `""""` have an issue with tabs.
- [x] Changing scenes ends the stack.
- [x] Reloading dialogue stopped working.
- [x] Quitting doesn't hide captions.

# Bad Design
- [ ] Persistent data loaded before mods loaded.
- [ ] Optional obfuscation/encrypt for `soot` `soda` and save data?

# Sooty
- [ ] Meta counter outputs:
    - [ ] Total estimated time.
    - [ ] Total words.
    - [ ] Total words per character.
    - [ ] Total branches.
    - [ ] Auto count possible routes.
    - [ ] Timer per route.
    - [ ] Characters in route.
- [ ] Remove `.` from `EXT_*` properties.
- [x] Rename Achievement to Award.
- [x] Data parser.
- [x] Container Awards, Tasks, and other things in collections, rather than state.
- [x] Move UI/console and fonts to `VisualNovel` addon.

# *.soot Dialogue Files
- [ ] Match arrays pattern.
- [ ] Match dict pattern.
- [x] Multi file loading from mods. (not tested)
- [x] Reimplement `+` as a dialogue option for merging external options.
- [x] Change comments from `// ` to `# `.

# *.sola Language Files
- [ ] Generate `.sola` files with previous data, so nothing is lost.
- [ ] Only merge as a `== flow call` if there are more than one.
- [x] Multiline id's.
- [x] Load and merge langs files.
- [x] Generate `.sola` files, for writing translations.

# *.soda Data Files
- [ ] Allow `:` paths inside key.
- [ ] `//` meta key.
- [ ] `\,` escapes
- [x] `$` shortcut key.
- [x] `.soda` debug viewer.
- [x] Dictionary -> `.soda` text function.
- [x] Highlighter.
- [x] Create data format file based on YAML.

# *.soma Markdown File
- [ ] Create file format based on Markdown for showing more complicated text like notebooks, item info, world story data...
- [ ] `.soma` -> BBCode parser.
- [ ] Highlighter.

# Highlighters
- [x] `.soda` shortcuts.
- [x] Match statements on same line aren't colored.
- [x] `+` options isn't colored
- [x] Colorize `/` in `=>` `==` paths.
- [x] `=>` and `==` should by symbols.
- [x] Colorize [and if else or == !=] in condition brackets {{}} as symbols.
- [x] Auto apply script highlighter to .soot files.

# UFile
- [x] Add _on_files(dir: String, call: Callable) function. To make collecting on a pattern easier.
- [x] file_exists_in_dir(): Check for a file inside a directory.
- [x] get_file_in_dir(tail): Get a path to a possibly nested file ending in tail.

# VisualNovel
- [ ] Character can control string wrappes `"` (For phones and such.)
- [ ] Create theme templates for captions + options.
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

# Printers
- [x] Seperate text printers and options menu.

# Parsing
- [ ] Printer that can show text across multiple captions.
- [ ] Using RichTextEffect.pre_parse() for pre parsing strings.
- [x] Use `/` instead of `.` for sub flows.

# Other
- [in progress] generate a node map so it's visible where everything is.
- [ ] Save file sorting by:
    - time since last played.
    - total time played.
    - progress.
