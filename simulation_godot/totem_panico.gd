extends Area2D

var http_request = HTTPRequest.new()
var ya_activado = false

# 1. NUEVO: Traemos la referencia del nodo de sonido que añadimos en el editor
@onready var sonido_alerta = $AudioStreamPlayer2D
func _ready():
	# Añadimos el nodo HTTPRequest para poder enviar datos
	add_child(http_request)
	# Conectamos la señal de cuando un cuerpo entra al área
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Si el objeto que choca se llama "Jugador" y no se ha activado antes
	if body.name == "Jugador" and not ya_activado:
		ya_activado = true
		modulate = Color.RED # El tótem se vuelve rojo al activarse
		
		# 2. NUEVO: Reproducir el sonido aquí mismo
		if sonido_alerta:
			sonido_alerta.play()
		
		enviar_alerta()
		await get_tree().create_timer(3.0).timeout
		modulate = Color.WHITE # Vuelve a su color normal
		ya_activado = false # ¡Ahora el tótem vuelve a estar listo
		
func enviar_alerta():
	print("¡Tótem activado por el personaje! Enviando alerta...")
	var url = "http://localhost:8000/incidentes/totem/"
	
	var headers = ["Content-Type: application/json"]
	var tipos = ["Botón de Pánico", "Alarma Acústica", "Sospechoso", "Disturbio"]
	var niveles = [3, 4, 5]
	var descripciones = [
		"Asistencia inmediata requerida en el sector asignado.",
		"Se detectó actividad inusual mediante el módulo físico.",
		"Activación manual de alerta por ciudadano en riesgo.",
		"Alerta preventiva lanzada desde el nodo interactivo."
	]
	var x_aleatoria = randf_range(0.0, 1150.0)
	var y_aleatoria = randf_range(0.0, 550.0)
	
	var tipo_elegido = tipos.pick_random()
	var nivel_elegido = niveles.pick_random()
	var descripcion_elegida = descripciones.pick_random()
	
	var datos = {
		"tipo": tipo_elegido,
		"latitud": x_aleatoria,
		"longitud": y_aleatoria,
		"nivel_urgencia": nivel_elegido,
		"descripcion": descripcion_elegida
	}
	
	var json_data = JSON.stringify(datos)
	http_request.request(url, headers, HTTPClient.METHOD_POST, json_data)
