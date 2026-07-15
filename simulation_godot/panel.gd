extends Panel

func _ready():
	var tamaño_pantalla = get_viewport_rect().size
	custom_minimum_size = Vector2(tamaño_pantalla.x * 0.30, tamaño_pantalla.y * 0.45)
	
	var estilo = StyleBoxFlat.new()
	# ¡LA SOLUCIÓN! Fondo 100% sólido para que la máscara no vuelva invisible al texto
	estilo.bg_color = Color(1.0, 1.0, 1.0, 1.0) 
	estilo.corner_radius_top_left = 25
	estilo.corner_radius_top_right = 25
	estilo.corner_radius_bottom_left = 25
	estilo.corner_radius_bottom_right = 25
	
	add_theme_stylebox_override("panel", estilo)

func mostrar_detalle(datos):
	for child in get_children(): 
		if child is Label: 
			child.queue_free()
	
	var info = "🚨 REPORTE DE INCIDENTE\n\n"
	info += "📌 Tipo: %s\n" % datos["tipo"]
	info += "⚠️ Nivel de Urgencia: %d\n" % datos["nivel_urgencia"]
	info += "📝 Descripción:\n%s\n\n" % datos["descripcion"]
	info += "📍 Coordenadas:\n%s, %s" % [str(datos["latitud"]).pad_decimals(4), str(datos["longitud"]).pad_decimals(4)]
	
	var label = Label.new()
	label.text = info
	label.position = Vector2(25, 25) 
	label.add_theme_font_size_override("font_size", 16)
	
	# Letras blancas puras (ahora sí serán visibles) con una sombra sutil
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0)) 
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(custom_minimum_size.x - 50, custom_minimum_size.y - 50)
	
	add_child(label)

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		hide()
