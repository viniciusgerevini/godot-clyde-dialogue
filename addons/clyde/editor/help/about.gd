@tool
extends Window

const InterfaceText = preload("../config/interface_text.gd")
const Settings = preload("../config/settings.gd")

@onready var _title: Label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/title

# main screen
@onready var _description: RichTextLabel = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/main_page/description
@onready var _version: Label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/main_page/version
@onready var _main_page: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/main_page
@onready var _main_help_button: Button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/main_page/VBoxContainer/help
@onready var _main_license_button: Button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/main_page/VBoxContainer/license
@onready var _main_report_button: Button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/main_page/VBoxContainer/report
@onready var _main_online_docs_button: Button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/main_page/VBoxContainer/online_docs


# license screen
@onready var _license_page: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/license_page
@onready var _license: RichTextLabel = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/license_page/license
@onready var _license_back_button: Button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/license_page/back

# help screen
@onready var _help_page: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/help_page
@onready var _help_back_button: Button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/help_page/back
@onready var _help_editor_button: Button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/help_page/editor
@onready var _help_player_button: Button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/help_page/player
@onready var _help_debugger_button: Button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/help_page/debugger
@onready var _help_tools_button: Button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/help_page/tools
@onready var _help_language_button: Button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/help_page/language

@onready var _help_text_page: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/help_text_page
@onready var _help_text_field: RichTextLabel = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/help_text_page/help_text_field
@onready var _help_text_back: Button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/help_text_page/back

var _settings: Settings

func setup(settings: Settings) -> void:
	_settings = settings
	_setup_strings()
	_setup_background(settings)


func _on_close_requested() -> void:
	queue_free()


func _on_description_meta_clicked(meta: Variant) -> void:
	if meta == "LICENSE":
		_on_license_button_down()
		return
	OS.shell_open(str(meta))


func _setup_strings() -> void:
	self.title = InterfaceText.get_string(InterfaceText.KEY_ABOUT_WINDOW_TITLE)
	_title.text = InterfaceText.get_string(InterfaceText.KEY_ABOUT_TITLE)
	_description.text = InterfaceText.get_string(InterfaceText.KEY_ABOUT_DESCRIPTION)
	_version.text = "v%s" % InterfaceText.plugin_version
	_license.text = _get_license_content()

	_main_report_button.text = InterfaceText.get_string(InterfaceText.KEY_HELP_REPORT_ISSUE)
	_main_report_button.icon = _settings.get_theme_icon("external_link")

	_main_online_docs_button.text = InterfaceText.get_string(InterfaceText.KEY_HELP_ONLINE_DOCS)
	_main_online_docs_button.icon = _settings.get_theme_icon("external_link")

	_main_help_button.text = InterfaceText.get_string(InterfaceText.KEY_PLUGIN_HELP_AND_INFO)
	_main_help_button.icon = _settings.get_theme_icon("help")

	_main_license_button.text = InterfaceText.get_string(InterfaceText.KEY_VIEW_LICENSE)
	_main_license_button.icon = _settings.get_theme_icon("help_license")

	_license_back_button.text = InterfaceText.get_string(InterfaceText.KEY_BACK)

	_help_back_button.text = InterfaceText.get_string(InterfaceText.KEY_BACK)
	_help_editor_button.text = InterfaceText.get_string(InterfaceText.KEY_EDITOR)
	_help_editor_button.icon = _settings.get_theme_icon("help_editor")
	_help_player_button.text = InterfaceText.get_string(InterfaceText.KEY_PLAYER)
	_help_player_button.icon = _settings.get_theme_icon("help_player")
	_help_debugger_button.text = InterfaceText.get_string(InterfaceText.KEY_DEBUGGER)
	_help_debugger_button.icon = _settings.get_theme_icon("help_debugger")
	_help_tools_button.text = InterfaceText.get_string(InterfaceText.KEY_TOOLS)
	_help_tools_button.icon = _settings.get_theme_icon("help_tools")
	_help_language_button.text = InterfaceText.get_string(InterfaceText.KEY_LANGUAGE)
	_help_language_button.icon = _settings.get_theme_icon("help_language")

	_help_text_back.text = InterfaceText.get_string(InterfaceText.KEY_BACK)


func _setup_background(settings: Settings) -> void:
	var base_color: Color = settings.get_theme_base_color()
	var panel = StyleBoxFlat.new()
	panel.bg_color = base_color
	$PanelContainer.add_theme_stylebox_override("panel", panel)


func _on_back_button_down() -> void:
	_license_page.hide()
	_main_page.show()


func _on_license_button_down() -> void:
	_main_page.hide()
	_license_page.show()


func _get_license_content() -> String:
	var file: FileAccess = FileAccess.open("res://addons/clyde/LICENSE", FileAccess.READ)
	return file.get_as_text()


func _on_main_help_button_down() -> void:
	_main_page.hide()
	_help_page.show()


func _on_main_report_button_down() -> void:
	OS.shell_open(_settings.REPORT_ISSUE_URL)


func _on_main_online_docs_button_down() -> void:
	OS.shell_open(_settings.ONLINE_DOCS_URL)


func _on_help_back_button_down() -> void:
	_help_page.hide()
	_main_page.show()


func _on_help_editor_button_down() -> void:
	_show_help_content("EDITOR")


func _on_help_player_button_down() -> void:
	_show_help_content("PLAYER")


func _on_help_debugger_button_down() -> void:
	_show_help_content("DEBUGGER")


func _on_help_tools_button_down() -> void:
	_show_help_content("TOOLS")


func _on_help_language_button_down() -> void:
	_show_help_content("LANGUAGE")


func _on_help_text_back_button_down() -> void:
	_help_text_page.hide()
	_help_page.show()


func _show_help_content(content: String) -> void:
	_help_text_page.show()
	_help_page.hide()
	_help_text_field.text = manuals[content]
	_help_text_field.scroll_to_line(0)

# I'll keep this here for nwo as it's easy to edit. Will likely move to somewhere else
# when translating the plugin
const manuals = {
	"EDITOR": '''[center][b]Editor[/b][/center]
[hr]

This plugin enhances Godot's script editor to support authoring dialogues in the engine. Just open or create any [code].clyde[/code] file in the Script Editor.

[b]Syntax highlighting:[/b]
Special characters, logic blocks and special elements, like speakers, are highlighted for easy reading, following your defined colorscheme.
In case your dialogue is not highlighted, with the file open in the Script Editor, go to "Edit > Syntax Highlighter > Clyde Dialogue".

[b]Real-time parsing:[/b]
As you write your dialogue, the editor will check the syntax in background. If any errors occur during parsing, the line will be marked in red and you can see more details about the error by hovering it or in the Output console.

[b]Player integration:[/b]
You can execute your dialogues in the Dialogue Player for quick validation.
To open a file in the player, right-click the file name in the scripts list and select "Open in Dialogue Player". You can also find this option in the context menu in the FileSystem dock.
To read more about the Dialogue Player you can check the [url=PLAYER_SECTION]player's help section[/url].

''',
	"PLAYER": '''[center][b]Player[/b][/center]
[hr]
Clyde Plugin brings a Dialogue Player direct to Godot's editor so you can easily validate your dialogues. The player is a Godot native dock, so you can choose the best location for it as you would with any other dock.

[b]Opening the Dialogue Player[/b]
When you first install the plugin, the Dialogue Player should be available on the right hand side dock. You can close and open it at any time.

You can re-open the player in a few different ways:
[ul]
Via the Editor Docks menu in "Editor > Editor Docks > Dialogue Player"
In the Script Editor, by right-clicking any *.clyde file and selecting "Open in Dialogue Player"
In the FileSystem dock, also by right-clicking any *.clyde file and selecting "Open in Dialogue Player"
In the Tools menu, "Project > Tools > Clyde > Open Dialogue Player"
[/ul]

[b]Executing Dialogues[/b]

To load a dialogue you can use the button with the folder icon in the player's top right corner.
This menu will show a list with all open *.clyde files and give you the option to open a new one.

You can also open a specific Clyde file from the Script Editor script list and FileSytem list by right-clicking the file and selecting "Open in Dialogue Player".

Once the file is loaded, you can click anywhere in the player and it will execute the next line, showing the current executing line in the Script Editor. You can also click any of the Dialogue bubbles to locate the line in the Clyde file in the Script Editor.

[i]Note: Due to Godot Editor's limitation, the plugin cannot programmatically open a Dialogue file in the script editor. This means if you have a file open in the player and not in the Script Editor, you won't be able to use the features mentioned above[/i]

[b]Player action bar[/b]
In the action bar you fill find the following buttons:
[indent]
[b]Block Selector[/b]
This allows you to select which block from the dialogue file to execute.

[b]Restart Dialogue[/b]
Restart the current dialogue from the begining. This will not clean the memory, so it will remember any single option used, variation triggered, and variable set.

[b]Next Line[/b]
Get next dialogue line. This is the same as clicking in the player itself.

[b]Forward to Next Choice[/b]
Automatically get dialogue lines and stop if an option/branch is returned so you can select it.

[b]Poltergeist Mode (auto-select)[/b]
Automatically get dialogue lines till the dialogue reaches an end. When it finds an option/branch, it picks one at random and continues the dialogue. This is useful to monkey-testing your dialogue and find edge cases.

[b]Clear Memory[/b]
Restart the dialogue and cleans all the internal memory. Any variable, single-use options and variations will be reset to the initial/unitialized state.

[b]Show Debug Panel[/b]
Open the Debug Panel in the bottom dock. This panel allows you to set and change variables and inspect variables and events triggered in your dialogue. Check the [url=DEBUGGER_SECTION]Debugger docs for more details[/url].

[b]Overflow menu[/b]
In the overflow menu (three dots on the right side) you will find the following options
[ul]
[b]Show Current Line in Script Editor:[/b] When selected, the Script Editor will follow the current line being executed.
[b]Watch for File Changes:[/b] When selected, the player will automatically reload and parse the dialogue when it detects the source file has changed.
[b]Move action bar to (top/bottom)[/b] Changes the position of this bar.
[b]Toggle Multi-Bubble Mode:[/b] When selected, all dialogue lines are shown in sequence, like a text chat. If not selected, only the last dialogue line will be shown. It can be changed while executing the dialogue without losing the context.
[b]Show Metadata:[/b] When selected, the line metadta is shown in the bubble. e.g line ids and tags.
[/ul]
[/indent]
[b]Other Features[/b]

[ul]
When clicking a dialogue bubble, the player locates and shows the source line in the Script Editor.
On the top-left part you can see a status indicator, which shows if the dialogue is parsing, succeeded or failed. If the dialogue fails parsing, the player shows the error message in the timeline and when hovering this indicator.
You can also open files from outside your project to test them.
[/ul]

''',
	"DEBUGGER": '''[center][b]Debugger[/b][/center]
[hr]
The debugger dock can be openned by clicking the debug button in the player's action bar. Check the [url=PLAYER_SECTION]player's help section[/url] for more details.

In this dock you can:
[ul]
Inspect dialogue's internal and external variables, set new values, add and remove any variables.
See the history of variables changes and events triggered in the dialogue.
[/ul]

Internal variables are removed when the player/editor is closed.
External variables are persisted in the editor cache and won't be removed when closing the dialogue or the editor. You can manually remove them via this debug dock.

''',
	"TOOLS": '''[center][b]Tools[/b][/center]
[hr]
There are a few extra tools to help with authoring and translating your dialogues.

[b]Generate Line IDs[/b]

This tool automatically generate line ids for your file. Line IDs can be used for a few different things, but the main use case are translations. Clyde automatically look up translations for the current locale using the dialogue line ID.
Manually adding IDs for each dialogue line can be cumbersome, so this tool can be ran at any time to fill it up. It won't replace existing line IDs, only add new ones to the lines without one.

As of now, the line IDs generated are resource IDs, which are a bit long and maybe not very user friendly, but random enough to prevent collisions. I intend to implement other id strategies in a future version.

To trigger Line ID generation, in the Script Editor, right-click the clyde file in the script list and select the option "Generate Line IDs".

[b]Create Dialogue CSV[/b]

This tool generates a CSV file with the dialogue file lines, to help with translations. It only includes lines with IDs.

You can select the delimiter (i.e , or ;), if it should include header, and if it should include a metadata column (this column will contain the speaker and any tags associated with the line).

You can access this tool via:
[ul]
The tools menu (Project > Tools > Clyde Dialogue > Create Dialogue CSV...).
In the FileSystem dock or Script Editor script list context menu when right-clicking a .clyde file.
[/ul]
''',
	"LANGUAGE": '''[center][b]Language[/b][/center]
[hr]
Please, check [url="CLYDE_DOC"]Clyde's online docs[/url] for a detailed explanation what it can do.

You can find some examples in the plugins examples folder ([url=EXAMPLES_FOLDER]./addons/clyde/examples/dialogues/[/url]).
''',
}


func _on_help_text_field_meta_clicked(meta: Variant) -> void:
	match meta:
		"PLAYER_SECTION":
			_on_help_player_button_down()
		"DEBUGGER_SECTION":
			_on_help_debugger_button_down()
		"CLYDE_DOC":
			OS.shell_open("https://thisisvini.com/clyde")
		"EXAMPLES_FOLDER":
			EditorInterface.select_file("res://addons/clyde/examples/dialogues/")
