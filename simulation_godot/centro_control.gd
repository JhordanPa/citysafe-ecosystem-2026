extends Node2D

# Cargamos de forma dinámica la escena del marcador que creamos en el Paso 2
var marcador_scene = preload("res://marcador_alerta.tscn")
@onready var http_request = $HTTPRequest
@onready var timer = $Timer

# Dirección base de tu backend de FastAPI
var api_url = "http://localhost:8000/incidentes/"

func _ready():
	# Conectamos las señales en Godot 4.x usando Callables
	timer.timeout.connect(_on_timer_timeout)
	http_request.request_completed.connect(_on_request_completed)
	
	# Primera consulta al arrancar
	solicitar_incidentes()

func _on_timer_timeout():
	solicitar_incidentes()

func solicitar_incidentes():
	# Realiza la petición HTTP GET de forma asíncrona
	var error = http_request.request(api_url)
	if error != OK:
		print("Error al iniciar la petición HTTP: ", error)

func _on_request_completed(_result, response_code, _headers, body):
	# ¡Añadimos esto para ver qué está pasando!
	print("Código de respuesta del servidor: ", response_code)
	
	if response_code != 200:
		print("¡Error! No me pude conectar al servidor.")
		return
		
	var json_string = body.get_string_from_utf8()
	print("Datos recibidos: ", json_string) # Esto nos mostrará en la consola qué recibió
	
	var datos_incidentes = JSON.parse_string(json_string)
	
	if datos_incidentes == null:
		print("Error al parsear el JSON.")
		return
		
	# Limpiamos marcadores previos
	for child in get_children():
		if child.is_in_group("alertas_activas"):
			child.queue_free()
			
	# Dibujamos
	actualizar_interfaz_mapa(datos_incidentes)

func actualizar_interfaz_mapa(incidentes_list):
	for child in get_children():
		if child.is_in_group("alertas_activas"):
			child.queue_free()
	
	# Nuevo: Contador de saturación
	var conteo = incidentes_list.size()
	print("Incidentes detectados: ", conteo)
	
	# Lógica visual de saturación
	if conteo > 3:
		# Aquí podrías cambiar el color de fondo o mostrar un aviso
		print("¡Saturación crítica detectada!")
	
	for incidente in incidentes_list:
		var nuevo_marcador = marcador_scene.instantiate()
		nuevo_marcador.add_to_group("alertas_activas")
		
		# Obtenemos las coordenadas desde "latitud" y "longitud"
		# Usamos .get() con un valor por defecto (0) por seguridad
		var pos_x = incidente.get("latitud", 100) 
		var pos_y = incidente.get("longitud", 100)
			
		nuevo_marcador.position = Vector2(pos_x, pos_y)
		add_child(nuevo_marcador)
