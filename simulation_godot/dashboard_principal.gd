extends Node2D

@onready var mapa = $OsmTileMap
@onready var mqtt = $MQTT 
@onready var panel_info = $CanvasLayer/Panel 

# Referencias Login
@onready var menu_login = $CanvasLayer/MenuLogin
@onready var input_user = $CanvasLayer/MenuLogin/InputUser
@onready var input_pass = $CanvasLayer/MenuLogin/InputPass
@onready var btn_login = $CanvasLayer/MenuLogin/BtnLogin

# Referencias Menú Creación
@onready var menu_creacion = $CanvasLayer/MenuCreacion
@onready var input_lugar = $CanvasLayer/MenuCreacion/InputLugar
@onready var input_desc = $CanvasLayer/MenuCreacion/InputDesc
@onready var opciones_urgencia = $CanvasLayer/MenuCreacion/OpcionesUrgencia
@onready var opciones_tipo_reporte = $CanvasLayer/MenuCreacion/OpcionesTipoReporte

# Botones Inferiores
@onready var btn_totem = $CanvasLayer/MenuOpciones/BtnTotem
@onready var btn_sensor = $CanvasLayer/MenuOpciones/BtnSensor
@onready var btn_ruido = $CanvasLayer/MenuOpciones/BtnRuido
@onready var btn_reporte = $CanvasLayer/MenuOpciones/BtnReporte
@onready var btn_borrar = $CanvasLayer/MenuOpciones/BtnBorrar
@onready var opciones_ruido = $CanvasLayer/MenuOpciones/OpcionesRuido 

# Botones del Panel de Info
@onready var btn_guardar = $CanvasLayer/MenuCreacion/BtnGuardar
@onready var btn_cancelar = $CanvasLayer/MenuCreacion/BtnCancelar
@onready var btn_editar_panel = $CanvasLayer/Panel/HBoxContainer/BtnEditar
@onready var btn_eliminar_panel = $CanvasLayer/Panel/HBoxContainer/BtnEliminar
@onready var btn_cerrar_panel = $CanvasLayer/Panel/BtnCerrar 

var api_request: HTTPRequest
var reproductor_alarma: AudioStreamPlayer
var totem_request: HTTPRequest
var delete_request: HTTPRequest 
var login_request: HTTPRequest 

var modo_actual = "NORMAL"
var coords_temporales = Vector2.ZERO
var pos_clic_inicial = Vector2.ZERO
var elemento_seleccionado = null
var elementos_bajo_raton = 0

var mi_token = "" 
const RUTA_GUARDADO = "user://dispositivos_locales.json"

class OndaRuido extends Node2D:
	var radio_base = 0.0
	var lat_lon = Vector2.ZERO
	var mapa_ref = null
	func _process(_delta):
		if mapa_ref != null:
			position = mapa_ref.lat_lon_to_pixel(lat_lon)
			scale = Vector2.ONE * pow(2.0, mapa_ref.zoom - 15)
	func _draw():
		draw_circle(Vector2.ZERO, radio_base, Color(0.5, 0.5, 0.5, 0.4))

func _ready():
	panel_info.hide() 
	menu_creacion.hide()
	
	if mi_token == "":
		menu_login.show()
	else:
		menu_login.hide()
	
	btn_login.pressed.connect(_on_btn_login_pressed)
	
	opciones_urgencia.add_item("Nivel 0", 0)
	opciones_urgencia.add_item("Nivel 1", 1)
	opciones_urgencia.add_item("Nivel 2", 2)
	opciones_urgencia.add_item("Nivel 3", 3)
	
	opciones_ruido.add_item("Ruido Genérico (0)", 0)
	opciones_ruido.add_item("Choque (1)", 1)
	opciones_ruido.add_item("Disparo (2)", 2)
	opciones_ruido.add_item("Explosión (3)", 3)
	opciones_ruido.hide() 
	
	opciones_tipo_reporte.add_item("Seguridad", 0)
	opciones_tipo_reporte.add_item("Médicas", 1)
	opciones_tipo_reporte.add_item("Servicios Públicos", 2)
	opciones_tipo_reporte.add_item("Protección Civil", 3)
	
	var grupo_botones = ButtonGroup.new()
	grupo_botones.allow_unpress = true 
	
	for btn in [btn_totem, btn_sensor, btn_ruido, btn_reporte, btn_borrar]:
		btn.button_group = grupo_botones
	
	btn_totem.toggled.connect(func(on): _cambiar_modo(on, "CREAR_TOTEM"))
	btn_sensor.toggled.connect(func(on): _cambiar_modo(on, "CREAR_SENSOR"))
	btn_reporte.toggled.connect(func(on): _cambiar_modo(on, "CREAR_REPORTE"))
	btn_ruido.toggled.connect(func(on): _cambiar_modo(on, "GENERAR_RUIDO"))
	btn_borrar.toggled.connect(func(on): _cambiar_modo(on, "BORRAR"))
	
	btn_guardar.pressed.connect(_on_btn_guardar_pressed)
	btn_cancelar.pressed.connect(_on_btn_cancelar)
	btn_eliminar_panel.pressed.connect(_on_btn_eliminar_pressed)
	btn_editar_panel.pressed.connect(_on_btn_editar_pressed)
	btn_cerrar_panel.pressed.connect(func(): panel_info.hide())
	
	reproductor_alarma = AudioStreamPlayer.new()
	reproductor_alarma.stream = preload("res://alarma.wav")
	add_child(reproductor_alarma)
	
	api_request = HTTPRequest.new()
	add_child(api_request)
	api_request.request_completed.connect(_on_historial_recibido)
	
	login_request = HTTPRequest.new()
	add_child(login_request)
	login_request.request_completed.connect(_on_login_completed)
	
	mqtt.broker_connected.connect(_on_broker_connected)
	mqtt.received_message.connect(_on_received_message)
	mqtt.connect_to_broker("broker.emqx.io")
	
	totem_request = HTTPRequest.new()
	add_child(totem_request)
	delete_request = HTTPRequest.new()
	add_child(delete_request)
	
	cargar_estado_local()

func _process(_delta):
	for child in get_children():
		if child.has_meta("is_pin") or child.has_meta("is_totem") or child.has_meta("is_sensor"):
			var lat_lon = Vector2(child.get_meta("lat"), child.get_meta("lon"))
			child.position = mapa.lat_lon_to_pixel(lat_lon)

# --- FUNCIÓN DE COLORES POR URGENCIA ---
func _obtener_color_urgencia(nivel: int) -> Color:
	match nivel:
		0: return Color(0.2, 0.5, 1.0) # Azul
		1: return Color(0.2, 0.8, 0.2) # Verde
		2: return Color(1.0, 0.6, 0.0) # Naranja
		3: return Color(1.0, 0.0, 0.0) # Rojo
	return Color(1.0, 0.0, 0.0)

# --- SISTEMA DE LOGIN (OAuth2) ---
func _on_btn_login_pressed():
	if input_user.text == "" or input_pass.text == "": return
	var body = "username=" + input_user.text.uri_encode() + "&password=" + input_pass.text.uri_encode()
	var headers = ["Content-Type: application/x-www-form-urlencoded"]
	login_request.request("http://127.0.0.1:8000/token", headers, HTTPClient.METHOD_POST, body)

func _on_login_completed(_result, response_code, _headers, body):
	if response_code == 200:
		var json = JSON.new()
		if json.parse(body.get_string_from_utf8()) == OK:
			mi_token = json.get_data()["access_token"]
			menu_login.hide()
			cargar_historial_incidentes() 
			print("¡Sesión iniciada con éxito!")
	else:
		print("Error de credenciales")
		input_pass.text = "" 

# --- SISTEMA DE GUARDADO LOCAL (.JSON) ---
func guardar_estado_local():
	var datos_a_guardar = []
	for child in get_children():
		if child.is_queued_for_deletion(): continue
		if child.has_meta("is_totem"):
			var datos = child.get_meta("datos_totem").duplicate()
			datos["tipo_dispositivo"] = "totem" 
			datos_a_guardar.append(datos)
		elif child.has_meta("is_sensor"):
			var datos = child.get_meta("datos_sensor").duplicate()
			datos["tipo_dispositivo"] = "sensor"
			datos_a_guardar.append(datos)
			
	var archivo = FileAccess.open(RUTA_GUARDADO, FileAccess.WRITE)
	if archivo:
		archivo.store_string(JSON.stringify(datos_a_guardar, "\t"))
		archivo.close()

func cargar_estado_local():
	if FileAccess.file_exists(RUTA_GUARDADO):
		var archivo = FileAccess.open(RUTA_GUARDADO, FileAccess.READ)
		var contenido = archivo.get_as_text()
		archivo.close()
		var json = JSON.new()
		if json.parse(contenido) == OK:
			for dispositivo in json.get_data():
				if dispositivo["tipo_dispositivo"] == "totem": dibujar_totem(dispositivo)
				elif dispositivo["tipo_dispositivo"] == "sensor": dibujar_sensor(dispositivo)

func _cambiar_modo(toggled_on: bool, nuevo_modo: String):
	if toggled_on:
		modo_actual = nuevo_modo
		if nuevo_modo == "GENERAR_RUIDO": opciones_ruido.show()
		else: opciones_ruido.hide()
	else:
		modo_actual = "NORMAL"
		opciones_ruido.hide()

func _unhandled_input(event):
	if menu_creacion.visible or menu_login.visible: return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			pos_clic_inicial = event.position 
		else:
			if event.position.distance_to(pos_clic_inicial) < 5.0:
				if elementos_bajo_raton > 0: return 
				panel_info.hide() 
				
				var clic_lat_lon = mapa.pixel_to_lat_lon(get_global_mouse_position())
				
				if modo_actual in ["CREAR_TOTEM", "CREAR_SENSOR", "CREAR_REPORTE"]:
					coords_temporales = clic_lat_lon
					abrir_menu_creacion()
				elif modo_actual == "GENERAR_RUIDO":
					_generar_onda_ruido(clic_lat_lon)

# --- MENÚ DINÁMICO ---
func abrir_menu_creacion():
	input_lugar.text = ""
	input_desc.text = ""
	
	# ¡CAMBIO AQUÍ! Ahora solo ocultamos la urgencia SI es un Sensor de Ruido.
	# Si es Tótem o Reporte Civil, mostramos la urgencia.
	if modo_actual == "CREAR_SENSOR" or (elemento_seleccionado != null and elemento_seleccionado.has_meta("is_sensor")):
		opciones_urgencia.hide() 
	else:
		opciones_urgencia.show() # ¡El Tótem ahora mostrará esto!
		# Si estamos creando un Tótem nuevo, por defecto nivel 2
		if elemento_seleccionado == null: opciones_urgencia.selected = 2
		else: opciones_urgencia.selected = (elemento_seleccionado.get_meta("datos_totem")["nivel_urgencia"])
		
	menu_creacion.show()

func _on_btn_guardar_pressed():
	if modo_actual == "CREAR_REPORTE":
		var tipo = opciones_tipo_reporte.get_item_text(opciones_tipo_reporte.selected)
		var payload = {
			"tipo": tipo,
			"latitud": coords_temporales.x,
			"longitud": coords_temporales.y,
			"nivel_urgencia": 1, 
			"descripcion": input_desc.text
		}
		var headers = ["Content-Type: application/json", "Authorization: Bearer " + mi_token]
		totem_request.request("http://127.0.0.1:8000/incidentes/", headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	else:
		var datos = {
		"latitud": coords_temporales.x,
		"longitud": coords_temporales.y,
		"lugar": input_lugar.text,
		"descripcion": input_desc.text,
		# Si las opciones son visibles, tomamos el valor; si no, forzamos 0 (para sensores)
		"nivel_urgencia": opciones_urgencia.get_selected_id() if opciones_urgencia.visible else 0
	}
		
		if elemento_seleccionado != null:
			if elemento_seleccionado.has_meta("is_totem"): elemento_seleccionado.set_meta("datos_totem", datos)
			elif elemento_seleccionado.has_meta("is_sensor"): elemento_seleccionado.set_meta("datos_sensor", datos)
			elemento_seleccionado = null
		else:
			if modo_actual == "CREAR_TOTEM": dibujar_totem(datos)
			elif modo_actual == "CREAR_SENSOR": dibujar_sensor(datos)
				
		guardar_estado_local()
		
	menu_creacion.hide()

func _on_btn_cancelar():
	menu_creacion.hide()
	elemento_seleccionado = null

# --- SIMULACIÓN DE RUIDO ---
func _generar_onda_ruido(origen_lat_lon: Vector2):
	var urgencia_seleccionada = opciones_ruido.get_selected_id()
	var radio_base = 100.0 
	if urgencia_seleccionada == 1: radio_base = 250.0 
	elif urgencia_seleccionada == 2: radio_base = 450.0 
	elif urgencia_seleccionada == 3: radio_base = 800.0 
	
	var onda = OndaRuido.new()
	onda.radio_base = radio_base
	onda.lat_lon = origen_lat_lon
	onda.mapa_ref = mapa
	onda.z_index = 4 
	add_child(onda)
	get_tree().create_timer(2.0).timeout.connect(func(): if is_instance_valid(onda): onda.queue_free())
	
	var pos_origen_fija = mapa.deg2num_exact(origen_lat_lon.x, origen_lat_lon.y, 15) * 256.0
	for child in get_children():
		if child.has_meta("is_sensor"):
			var lat_lon_sensor = Vector2(child.get_meta("lat"), child.get_meta("lon"))
			var pos_sensor_fija = mapa.deg2num_exact(lat_lon_sensor.x, lat_lon_sensor.y, 15) * 256.0
			if pos_origen_fija.distance_to(pos_sensor_fija) <= radio_base:
				_activar_sensor_y_reportar(child, urgencia_seleccionada)

func _activar_sensor_y_reportar(sensor_ref, nivel_urgencia):
	# ¡COLOR DE URGENCIA DINÁMICO EN EL SENSOR!
	sensor_ref.get_node("Sprite2D").modulate = _obtener_color_urgencia(nivel_urgencia)
	get_tree().create_timer(2.0).timeout.connect(func():
		if is_instance_valid(sensor_ref):
			sensor_ref.get_node("Sprite2D").modulate = Color(1, 1, 1)
	)
	var datos_sensor = sensor_ref.get_meta("datos_sensor")
	var payload = {
		"tipo": "Sensor de Ruido (" + datos_sensor["lugar"] + ")",
		"latitud": sensor_ref.get_meta("lat"),
		"longitud": sensor_ref.get_meta("lon"),
		"nivel_urgencia": nivel_urgencia,
		"descripcion": "Alerta captada: " + opciones_ruido.get_item_text(nivel_urgencia) + ".\nNotas del sensor: " + datos_sensor["descripcion"]
	}
	var req = HTTPRequest.new()
	add_child(req)
	req.request_completed.connect(func(_res, _code, _head, _body): req.queue_free())
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + mi_token]
	req.request("http://127.0.0.1:8000/incidentes/", headers, HTTPClient.METHOD_POST, JSON.stringify(payload))

# --- FUNCIONES MQTT Y DIBUJADO BASE ---
func cargar_historial_incidentes():
	if mi_token == "": return 
	api_request.request("http://127.0.0.1:8000/incidentes/")

func _on_historial_recibido(_result, response_code, _headers, body):
	if response_code == 200:
		var json = JSON.new()
		if json.parse(body.get_string_from_utf8()) == OK:
			for incidente in json.get_data(): dibujar_pin_de_emergencia(incidente)

func _on_broker_connected():
	mqtt.subscribe("citysafe/alertas")

func _on_received_message(topic: String, message: String):
	if topic == "citysafe/alertas":
		var json = JSON.new()
		if json.parse(message) == OK: dibujar_pin_de_emergencia(json.get_data())

func dibujar_pin_de_emergencia(datos):
	if "Botón de pánico" in datos["tipo"] or "Sensor de Ruido" in datos["tipo"]: return
	var pin = Area2D.new()
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = preload("res://pin.png") 
	
	# ¡COLOR DE URGENCIA DINÁMICO EN LOS PINES REGULARES!
	var nivel = int(datos.get("nivel_urgencia", 1))
	sprite.modulate = _obtener_color_urgencia(nivel)
	
	sprite.scale = Vector2(0.5, 0.5) 
	pin.add_child(sprite)
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 20
	shape.shape = circle
	pin.add_child(shape)
	pin.z_index = 5
	pin.set_meta("datos", datos) 
	pin.set_meta("is_pin", true) 
	pin.set_meta("lat", datos["latitud"])
	pin.set_meta("lon", datos["longitud"])
	pin.input_pickable = true
	pin.input_event.connect(_on_pin_clicked.bind(pin))
	pin.mouse_entered.connect(func(): elementos_bajo_raton += 1)
	pin.mouse_exited.connect(func(): elementos_bajo_raton -= 1)
	add_child(pin)

func dibujar_totem(datos):
	var totem = Area2D.new()
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D" 
	sprite.texture = preload("res://totem.png") 
	sprite.scale = Vector2(0.5, 0.5) 
	totem.add_child(sprite)
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 30
	shape.shape = circle
	totem.add_child(shape)
	totem.z_index = 8 
	totem.set_meta("is_totem", true)
	totem.set_meta("lat", datos["latitud"])
	totem.set_meta("lon", datos["longitud"])
	totem.set_meta("activado", false) 
	totem.set_meta("datos_totem", datos)
	totem.input_pickable = true
	totem.input_event.connect(_on_totem_clicked.bind(totem))
	totem.mouse_entered.connect(func(): elementos_bajo_raton += 1)
	totem.mouse_exited.connect(func(): elementos_bajo_raton -= 1)
	add_child(totem)

func dibujar_sensor(datos):
	var sensor = Area2D.new()
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D" 
	sprite.texture = preload("res://sensor.png") 
	sprite.scale = Vector2(0.5, 0.5) 
	sensor.add_child(sprite)
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 30
	shape.shape = circle
	sensor.add_child(shape)
	sensor.z_index = 8 
	sensor.set_meta("is_sensor", true)
	sensor.set_meta("lat", datos["latitud"])
	sensor.set_meta("lon", datos["longitud"])
	sensor.set_meta("datos_sensor", datos)
	sensor.input_pickable = true
	sensor.input_event.connect(_on_sensor_clicked.bind(sensor))
	sensor.mouse_entered.connect(func(): elementos_bajo_raton += 1)
	sensor.mouse_exited.connect(func(): elementos_bajo_raton -= 1)
	add_child(sensor)

func _on_pin_clicked(_viewport, event, _shape_idx, pin_ref):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled() 
		if event.pressed:
			if modo_actual == "BORRAR":
				var datos = pin_ref.get_meta("datos")
				if datos.has("id"):
					var headers = ["Authorization: Bearer " + mi_token]
					delete_request.request("http://127.0.0.1:8000/incidentes/" + str(datos["id"]), headers, HTTPClient.METHOD_DELETE)
				elementos_bajo_raton = 0 
				pin_ref.queue_free()
				return
			btn_editar_panel.hide()
			btn_eliminar_panel.hide()
			panel_info.mostrar_detalle(pin_ref.get_meta("datos"))
			panel_info.show()

func _on_totem_clicked(_viewport, event, _shape_idx, totem_ref):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			get_viewport().set_input_as_handled() 
		if event.pressed:
			if modo_actual == "BORRAR" and event.button_index == MOUSE_BUTTON_LEFT:
			# CORRECCIÓN: Resetear contador antes de borrar
				elementos_bajo_raton = 0
				totem_ref.queue_free()
				guardar_estado_local()
				return
			var datos_totem = totem_ref.get_meta("datos_totem")
			if event.button_index == MOUSE_BUTTON_LEFT:
				var nuevo_estado = !totem_ref.get_meta("activado")
				totem_ref.set_meta("activado", nuevo_estado)
				if nuevo_estado:
					# ¡COLOR DE URGENCIA DINÁMICO EN EL TÓTEM!
					var nivel = int(datos_totem.get("nivel_urgencia", 2))
					totem_ref.get_node("Sprite2D").modulate = _obtener_color_urgencia(nivel)
					
					if not reproductor_alarma.playing: reproductor_alarma.play()
					var payload = {
						"tipo": "Botón de pánico (" + datos_totem["lugar"] + ")",
						"latitud": totem_ref.get_meta("lat"),
						"longitud": totem_ref.get_meta("lon"),
						"nivel_urgencia": datos_totem["nivel_urgencia"],
						"descripcion": datos_totem["descripcion"]
					}
					var headers = ["Content-Type: application/json", "Authorization: Bearer " + mi_token]
					totem_request.request("http://127.0.0.1:8000/incidentes/", headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
				else:
					totem_ref.get_node("Sprite2D").modulate = Color(1, 1, 1)
					var apagar = true
					for child in get_children():
						if child.has_meta("is_totem") and child.get_meta("activado"): apagar = false
					if apagar: reproductor_alarma.stop()
					
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				elemento_seleccionado = totem_ref
				btn_editar_panel.show()
				btn_eliminar_panel.show()
				var info_formateada = {
					"tipo": "Tótem Físico (" + datos_totem["lugar"] + ")",
					"nivel_urgencia": datos_totem["nivel_urgencia"],
					"descripcion": datos_totem["descripcion"],
					"latitud": datos_totem["latitud"],
					"longitud": datos_totem["longitud"]
				}
				panel_info.mostrar_detalle(info_formateada)
				panel_info.show()

func _on_sensor_clicked(_viewport, event, _shape_idx, sensor_ref):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			get_viewport().set_input_as_handled()
		if event.pressed:
			if modo_actual == "BORRAR" and event.button_index == MOUSE_BUTTON_LEFT:
			# CORRECCIÓN: Resetear contador antes de borrar
				elementos_bajo_raton = 0
				sensor_ref.queue_free()
				guardar_estado_local()
				return
			if event.button_index == MOUSE_BUTTON_RIGHT:
				elemento_seleccionado = sensor_ref
				var datos_sensor = sensor_ref.get_meta("datos_sensor")
				btn_editar_panel.show()
				btn_eliminar_panel.show()
				var info_formateada = {
					"tipo": "Sensor de Ruido (" + datos_sensor["lugar"] + ")",
					"nivel_urgencia": 0, 
					"descripcion": datos_sensor["descripcion"],
					"latitud": datos_sensor["latitud"],
					"longitud": datos_sensor["longitud"]
				}
				panel_info.mostrar_detalle(info_formateada)
				panel_info.show()

func _on_btn_editar_pressed():
	if elemento_seleccionado != null:
		var datos = null
		if elemento_seleccionado.has_meta("is_totem"): datos = elemento_seleccionado.get_meta("datos_totem")
		elif elemento_seleccionado.has_meta("is_sensor"): datos = elemento_seleccionado.get_meta("datos_sensor")
		if datos:
			input_lugar.text = datos["lugar"]
			input_desc.text = datos["descripcion"]
			if elemento_seleccionado.has_meta("is_totem"):
				opciones_urgencia.show()
				opciones_urgencia.selected = datos["nivel_urgencia"]
			else:
				opciones_urgencia.hide()
			panel_info.hide()
			menu_creacion.show()

func _on_btn_eliminar_pressed():
	if elemento_seleccionado != null:
		# CORRECCIÓN: Resetear contador antes de borrar
		elementos_bajo_raton = 0
		elemento_seleccionado.queue_free()
		panel_info.hide()
		elemento_seleccionado = null
		guardar_estado_local()
