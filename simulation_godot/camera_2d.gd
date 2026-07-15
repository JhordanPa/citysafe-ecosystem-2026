extends Camera2D

var arrastrando = false
var mapa = null
var zoom_cooldown = 0.0

func _ready():
	position = Vector2(0, 0)
	if get_parent() is OSMTileMap:
		mapa = get_parent()
	else:
		mapa = get_parent().get_node_or_null("OsmTileMap")

func _process(delta):
	if zoom_cooldown > 0:
		zoom_cooldown -= delta

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			arrastrando = event.pressed
		
		# Zoom inteligente (Estilo Google Maps)
		if event.is_pressed() and zoom_cooldown <= 0 and mapa != null:
			var viejo_zoom = mapa.zoom
			
			if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				# 1. Miramos qué lat/lon real está tocando el ratón ahora mismo
				var pos_raton_pantalla = get_global_mouse_position()
				var lat_lon_raton = mapa.pixel_to_lat_lon(pos_raton_pantalla)
				
				if event.button_index == MOUSE_BUTTON_WHEEL_UP:
					mapa.zoom = clamp(mapa.zoom + 1, 1, 19)
				elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
					mapa.zoom = clamp(mapa.zoom - 1, 1, 19)

				# 2. Si el zoom cambió, compensamos la cámara moviéndola hacia el ratón
				if viejo_zoom != mapa.zoom:
					zoom_cooldown = 0.4 
					var nueva_pos_raton = mapa.lat_lon_to_pixel(lat_lon_raton)
					position += (nueva_pos_raton - pos_raton_pantalla)

	elif event is InputEventMouseMotion and arrastrando:
		position -= event.relative
