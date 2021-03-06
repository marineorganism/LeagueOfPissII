extends Node

onready var itemSprite = preload("res://adventures/objects/itemSprite.tscn")
onready var textbox = preload("res://adventures/objects/textbox.tscn")
onready var question = preload("res://adventures/objects/question.tscn")
onready var cheatbox = preload("res://adventures/objects/cheat.tscn")
onready var bag = preload("res://adventures/objects/bag.tscn")
onready var transition = preload("res://adventures/objects/transition.tscn")
onready var fader = preload("res://adventures/objects/fade.tscn")
onready var thing = preload("res://adventures/thing.gd")

const NORMAL = 0
const ANGRY = 1
const EXCITED = 2

export var music = "ambience"

signal animated
signal said

const C = "completed"

var guiNode
var item = null
var gui = false
var caller = null
var value = null

"""
" @override Node.
"""
func _ready():
	set_process_input(true)
	global.resetMouse()
	if (sound.getSong() != music): sound.song(music)
	add_child(bag.instance())
	guiNode = Node2D.new()
	guiNode.set_name("gui")
	add_child(guiNode)
	var node = thing.new()
	node.realName = "SYSTEME"
	node.name = "_god_"
	$actives.add_child(node)
	if (has_method("start")): start()

"""
" Runs a function belonging to the room.
" @param code is the name of the function to run.
" @param owner is the thing you clicked on I thnk.
"""
func run(code, owner):
	caller = owner
	if (item == null):
		if (has_method(code)): call(code)
		else: printerr("uhoh missing function %s" % code)
	else:
		var itemCode = "%s_%s" % [code, item]
		var allCode = "%s_" % code
		if (has_method(itemCode)):
			var saveItem = call(itemCode)
			if (global.itemProperty(item, "dispose") and not saveItem):
				global.removeFromInventory(item)
		elif (has_method(allCode)):
			call(allCode,item)
		else: say("%s does nothing here" % item)
		removeItem()

"""
" Runs an animation on an animator, and then returns the animator so you can
" yield on it.
" @param AnimationPlayer animator is the animator object to play the animation.
" @param String animation is the name of the animation.
" @return AnimationPlayer the same animator you passed in.
"""
func anim(animator, animation):
	animator.play(animation)
	return animator

"""
" Takes the item off the mouse and out of current usage.
"""
func removeItem():
	item = null
	get_node("itemSprite").queue_free()

"""
" gives you the character with the given code name.
" @param name is the name of the character within the scene tree.
" @return named character or the active character if no name given.
"""
func getActive(name=null):
	if (name): return get_node("actives/%s" % name)
	return caller

"""
" Attaches an item to the mouse cursor so that it can be used.
" @param name is the name of the item we will be using hell yeah.
"""
func useItem(name):
	item = name
	var ib = itemSprite.instance()
	ib.set_texture(repository.items[name].texture)
	add_child(ib)

"""
" Sets or gets a switch.
" @param name is the name of the switch (or switch expression if no change).
" @param change is the value to set the given switch to or null for no change.
" @return the current value of the switch.
"""
func s(name,change=null):
	if (change == null): return global.getSwitch(name)
	global.setSwitch(name,change)
	return change

"""
" Sets or gets a self switch.
" TODO: this does not currently work with switch expressions.
" @param String name is name of the switch or switch expression if no change.
" @param boolean change is value to set the given switch to or null for same.
" @return boolean the current value of the self switch.
"""
func ss(name,change=null):
	if (!global.state["area"]): return false
	return s(global.state["area"] + ":" + name,change)

"""
" Goes into a given room. It's shorthand for global.enterAdventure(map)
" @param String map is the map to go to.
"""
func move(map):
	global.enterAdventure(map)

"""
" Put a given character in a given pose.
" @param n is the code number of the pose for them to do.
" @param name is the name of the character and it defaults the active character.
"""
func pose(n,name = null):
	var owner = getActive(name)
	if (owner != null): owner.get_node("sprite").set_frame(n)

"""
" display a text box and optionally set a name on the top of the box and make
" a character pull a pose. It yields until the user closes the box.
" @param String text is the text to put in the box.
" @param String name is the optional name of a character to ascribe the box to.
" @param int face is the optional pose to make named character pull.
"""
func say(text,name = null,face = null):
	var ib = textbox.instance()
	var active = getActive(name)
	if (active == null): return ib
	ib.get_node("name").set_text(active.realName)
	if (face != null):
		ib.setFace(active.get_node("sprite"))
		active.get_node("sprite").set_frame(face)
	#make he text nicer
	text = text.replace("\n"," ")
	text = text.replace("~","\n")
	#back to work
	ib.get_node("text").set_text(text)
	guiNode.add_child(ib)
	gui = true
	yield(ib, "said")

"""
" Gives the player a message and a couple of choices that they can select. It
" does not return anything but I think the response gets saved somewhere or
" other.
" TODO: maybe I should refactor this so that you do not have to have the
" mandatory answers and stuff and use a list of possible answers that is
" scrollable or something so that space does not run out. I dunno it is far from
" a priority.
" @param text is the message to say to the player.
" @param a1 is the first answer.
" @param a2 is the second answer.
" @param a3 is the third answer.
" @param a4 is the fourth answer.
"""
func ask(text,a1,a2,name = null,a3 = null,a4 = null):
	var ib = question.instance()
	ib.get_node("name").set_text(getActive(name).realName)
	ib.get_node("text").set_text(text)
	ib.get_node("a").set_text(a1)
	ib.get_node("b").set_text(a2)
	if (a3 == null): ib.get_node("c").free()
	else: ib.get_node("c").set_text(a3)
	if (a4 == null): ib.get_node("d").free()
	else: ib.get_node("d").set_text(a4)
	guiNode.add_child(ib)
	gui = true
	yield(ib, "said")

"""
" Runs a puzzle until it is done.
" @param filename is the name of the file the puzzle is in.
" @return whatever the puzzle returns which should be a success boolean.
"""
func puzzle(filename):
	var puzzle = load("res://adventures/puzzles/%s.tscn" % filename).instance()
	var holder = get_node("puzzle")
	if (holder == null):
		printerr(
			"you're meant to add a puzzle node to set where it'll appear "+
			"idiota"
		)
		return yield()
	get_node("puzzle").add_child(puzzle)
	gui = true
	return yield(puzzle, "said")

"""
" Starts a battle with an optional tier value.
" @param map is the filename of the battle to enter.
" @param tier is an optional string to pass to the battling enemy. TODO: remove?
" @return whatever the battle returns which should be a success boolean
"""
func battle(map, tier=""):
	gui = true
	var ib = transition.instance()
	var scene = load("res://battles/battles/%s.tscn" % map).instance()
	scene.tier = tier
	get_node("/root/room/gui").add_child(ib)
	sound.song("%s" % scene.song)
	yield(ib.get_node("anim"), "animation_finished")
	get_node("/root/room/gui/transition").queue_free()
	add_child(scene)
	return yield(scene, "said")

"""
" Fades out the screen and enters a new room.
" TODO: this is not using the new function yield system and could be improved.
" @param map is the filename of the room to change to.
"""
func fade(map):
	gui = true
	var ib = fader.instance()
	var scene = load("res://adventure/scenes/%s.tscn" % map).instance()
	get_node("/root/room/gui").add_child(ib)
	ib.get_node("anim").connect("finished",global,"enterAdventure",[map])

"""
" Fades in from black.
" TODO: could moved to function yielding system.
" @return the blackness sprite which will fire a signal when it is done.
"""
func fadeIn():
	gui = true
	var ib = fader.instance()
	get_node("/root/room/gui").add_child(ib)
	ib.get_node("anim").play("enter")
	return ib

"""
" Reloads the room. Can be used so that changes to game state are loaded.
"""
func refresh():
	global.enterAdventure(global.state["area"])

"""
" Saves the game.
" Intended to be called as a result of using the "save" item.
"""
func save():
	global.saveGame()
	say("game saved!", "_god_")

"""
" Asks player if they want to quit the game and quits it if they do.
" Intended to be called as a result of using the "quit" item.
"""
func quit():
	yield(ask("Are you sure you want to quit?","yeah","nah", "_god_"), C)
	if (value == "a"): get_tree().change_scene("res://menus/menu.tscn")

"""
" Adds a debug dialogue to the screen and yields until it has been closed.
"""
func cheat():
	var ib = cheatbox.instance()
	guiNode.add_child(ib)
	gui = true
	yield(ib, "said")