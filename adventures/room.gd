extends Node

onready var itemSprite = preload("res://adventures/objects/itemSprite.tscn")
onready var animator = preload("animator.gd").new(self)
onready var textbox = preload("res://adventures/objects/textbox.tscn")
onready var question = preload("res://adventures/objects/question.tscn")
onready var cheatbox = preload("res://adventures/objects/cheat.tscn")
onready var bag = preload("res://adventures/objects/bag.tscn")
onready var transition = preload("res://adventures/objects/transition.tscn")
onready var fader = preload("res://adventures/objects/fade.tscn")

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


func _ready():
	set_process_input(true)
	global.resetMouse()
	if (sound.getSong() != music): sound.song(music)
	add_child(bag.instance())
	guiNode = Node2D.new()
	guiNode.set_name("gui")
	add_child(guiNode)
	if (has_method("start")): start()

func run(code,owner):
	caller = owner
	
	if (item == null):
		if (has_method(code)): call(code)
		else: print("uhoh missing function %s" % code)
	else:
		var itemCode = "%s_%s" % [code,item]
		var allCode = "%s_" % code
		if (has_method(itemCode)):
			var saveItem = call(itemCode)
			if (global.itemProperty(item,"dispose") and not saveItem):
				global.removeFromInventory(item)
		elif (has_method(allCode)):
			call(allCode,item)
		else: say("%s does nothing here" % item)
		item = null
		get_node("itemSprite").queue_free()


func getActive(name):
	if (name != null):
		return get_node("actives/%s" % name)
	return caller

func useItem(name):
	item = name
	var ib = itemSprite.instance()
	ib.set_texture(global.items[name].texture)
	add_child(ib)
	
##########################################################################################
######################## Functions for using in script ###################################
##########################################################################################
func s(name,change=null):
	if (change == null): return global.getSwitch(name)
	global.setSwitch(name,change)

func ss(name,change=null):
	if (!global.area): return false
	return s(global.area + ":" + name,change)

func move(map):
	global.enterAdventure(map)

func pose(n,name = null):
	var owner = getActive(name)
	if (owner != null): owner.get_node("sprite").set_frame(n)

func cheat():
	var ib = cheatbox.instance()
	guiNode.add_child(ib)
	gui = true
	yield(ib, "said")

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

func animate(anim):
	return animator.r(anim)

func puzzle(filename):
	var puzzle = load("res://adventures/puzzles/%s.tscn" % filename).instance()
	var holder = get_node("puzzle")
	if (holder == null):
		printerr("you're meant to add a puzzle node to set where it'll appear idiota")
		return yield()
	get_node("puzzle").add_child(puzzle)
	gui = true
	return yield(puzzle, "said")
	

func battle(map, tier=""):
	gui = true
	var ib = transition.instance()
	var scene = load("res://battles/battles/%s.tscn" % map).instance()
	scene.tier = tier
	get_node("/root/room/gui").add_child(ib)
	sound.song("%s" % scene.song)
	ib.get_node("anim").connect("animation_finished",self,"beginBattle",[scene])
	return yield(scene, "said")

func beginBattle(a, scene):
	get_node("/root/room/gui/transition").queue_free()
	add_child(scene)
	

func fade(map):
	gui = true
	var ib = fader.instance()
	var scene = load("res://adventure/scenes/%s.tscn" % map).instance()
	get_node("/root/room/gui").add_child(ib)
	ib.get_node("anim").connect("finished",global,"enterAdventure",[map])

func fadeIn():
	gui = true
	var ib = fader.instance()
	get_node("/root/room/gui").add_child(ib)
	ib.get_node("anim").play("enter")
	return ib

func refresh():
	global.enterAdventure(global.area)



##########################################################################################
############################### Item Functions ###########################################
##########################################################################################
func save():
	global.saveGame()
	say("game saved!")

func quit():
	yield(ask("Are you sure you want to quit?","yeah","nah"),C)
	if (value == "a"): get_tree().change_scene("res://menus/menu.tscn")