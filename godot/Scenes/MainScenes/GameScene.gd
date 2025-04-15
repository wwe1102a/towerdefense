extends Node2D

var map_node
var build_mode = false
var build_valid = false
var build_tile
var build_location 
var build_type

var current_wave = 0
var enemies_in_wave = 0

var popup_scene = preload("res://Scenes/UIScenes/Pop_up_Menu.tscn")  # เปลี่ยนเส้นทางให้ถูกต้อง
var popup_instance  # ตัวแปรสำหรับเก็บอินสแตนซ์ของ Popup

var money = 200

onready var money_label = get_node("UI/HBoxContainer/Money")

func _ready():
	
	_update_money_display()
	
	popup_instance = popup_scene.instance()  # สร้างอินสแตนซ์ของ Popup
	popup_instance.visible = false  # ซ่อน Popup ตั้งแต่เริ่ม
	add_child(popup_instance)  # เพิ่ม Popup ไปยัง Scene
	
	popup_instance.get_node("TextureRect/continue").connect("pressed", self, "_on_continue_pressed")
	popup_instance.get_node("TextureRect/restart").connect("pressed", self, "_on_restart_pressed")
	popup_instance.get_node("TextureRect/quit").connect("pressed", self, "_on_quit_pressed")
	
	map_node = get_node("Map1")
	
	for i in get_tree().get_nodes_in_group("build_buttons"):
		i.connect("pressed", self, "initiate_build_mode", [i.get_name()])
		start_next_wave()

func _process(delta):
	if build_mode:
		update_tower_preview()
		


func _unhandled_input(event):
	if event.is_action_released("ui_cancel") and build_mode == true:
		cancel_build_mode()
	if event.is_action_released("ui_accept") and build_mode == true:
		verify_and_build()
		cancel_build_mode()



##Buildings placements
func initiate_build_mode(tower_type):
	if build_mode:
		cancel_build_mode()
	build_type = tower_type + "T1"
	build_mode = true
	get_node("UI").set_tower_preview(build_type, get_global_mouse_position())


func update_tower_preview():
	var mouse_position = get_global_mouse_position()
	var current_tile = map_node.get_node("TowerExclusion").world_to_map(mouse_position)
	var tile_position = map_node.get_node("TowerExclusion").map_to_world(current_tile)
	
	if map_node.get_node("TowerExclusion").get_cellv(current_tile) == -1:
		get_node("UI").update_tower_preview(tile_position, "ad54ff3c")
		build_valid = true
		build_location = tile_position
		build_tile = current_tile
	else:
		get_node("UI").update_tower_preview(tile_position, "adff4545")
		build_valid = false

func cancel_build_mode():
	build_mode = false
	build_valid = false
	get_node("UI/TowerPreview").free()


func verify_and_build():
	if build_valid:
		
		var tower_cost = GameData.tower_data[build_type]["cost"]  # ประกาศตัวแปรที่อ้างอิงถึงคอสของป้อมปราการ
		if money >= tower_cost: #ตรวจว่ามีค่าใช้จายในการสร้างป้อมเพียงพอมั้ย
			var new_tower = load("res://Scenes/Turrets/" + build_type + ".tscn").instance()
			new_tower.position = build_location
			new_tower.built = true
			new_tower.type = build_type
			new_tower.category = GameData.tower_data[build_type]["category"]
			map_node.get_node("Turrets").add_child(new_tower, true)
			map_node.get_node("TowerExclusion").set_cellv(build_tile, 5)
			subtract_money(tower_cost)  # หักเงินตามค่าของป้อม
		else:
			print("not enough money")
	else:
			cancel_build_mode()


##Wave Functions
func start_next_wave():
	var wave_data = retrieve_wave_data()
	yield(get_tree().create_timer(0.2),"timeout")
	spawn_enemies(wave_data)

func retrieve_wave_data():
	var wave_data = [["BlueTank", 1.2], ["BlueTank", 0.1]]
	current_wave += 1
	enemies_in_wave = wave_data.size()
	return wave_data


func spawn_enemies(wave_data):
	for i in wave_data:
		var new_enemy = load("res://Scenes/Enemies/" + i[0] + ".tscn").instance()
		map_node.get_node("Path").add_child(new_enemy, true)
		yield(get_tree().create_timer(i[1]),"timeout")
		

func _paused (): #หยุดเกมชั่วคราว
	if Engine.time_scale > 0:
		Engine.time_scale = 0  
	else:
		Engine.time_scale = 1  
	
	
func _on_play_paused_button_down():  
	_paused() 



func _on_X2_button_down(): #เร่งความเร็วเกม
	if Engine.time_scale == 1:
		Engine.time_scale = 2  
	else:
		Engine.time_scale = 1  

# ตรวจจับการกด ESC เพื่อเปิด Popup
func _input(event):
	if event.is_action_pressed("Escape"):   # กด ESC เพื่อเปิด Popup
		popup_instance.visible = !popup_instance.visible # สลับการแสดงของ Popup
		if Engine.time_scale == 0:
			Engine.time_scale = 0
		else :
			_paused() 
		
# ฟังก์ชันที่ทำงานเมื่อกดปุ่ม "Continue"
func _on_continue_pressed():
	popup_instance.visible = false  # ปิด Popup
	_paused() 

# ฟังก์ชันที่ทำงานเมื่อกดปุ่ม "Restart"
func _on_restart_pressed():
	popup_instance.visible = false  # ปิด Popup
	_paused()
	get_tree().reload_current_scene()  
	get_tree().change_scene("res://Scenes/MainScenes/GameScene.tscn")

# ฟังก์ชันที่ทำงานเมื่อกดปุ่ม "Quit"
func _on_quit_pressed():
	get_tree().quit()  # ออกจากเกม



# ฟังก์ชันที่ใช้แสดงผลเงินใน Label
func _update_money_display():
	money_label.text = "" + str(money)

# ฟังก์ชันเพิ่มเงินลดเงิน
func add_money(amount: int):
	money += amount
	_update_money_display()

# ฟังก์ชันในการหักค่าใช้จ่าย
func subtract_money(amount: int):
	if money >= amount:
		money -= amount
		_update_money_display()
