@tool
extends Node2D
class_name OSMTileMap

@export var latitude: float = -12.05 :
	set(value):
		latitude = value
		_update_map()

@export var longitude: float = -77.13 :
	set(value):
		longitude = value
		_update_map()

@export var zoom: int = 15 :
	set(value):
		zoom = value
		_update_map()

@export var base_url: String = "https://mt1.google.com/vt/lyrs=m" 

var loading_tiles = []
var loaded_tiles = {} 
var last_camera_tile = Vector2(99999, 99999) 
var update_timer: float = 0.0

func _ready():
	if not DirAccess.dir_exists_absolute("user://map_cache"):
		DirAccess.make_dir_absolute("user://map_cache")
	_update_map()

func _process(delta):
	if not Engine.is_editor_hint():
		update_timer += delta
		if update_timer > 0.5: 
			update_timer = 0.0
			var camera = get_viewport().get_camera_2d()
			if camera:
				var current_camera_tile = Vector2(floor(camera.position.x / 256.0), floor(camera.position.y / 256.0))
				if current_camera_tile != last_camera_tile:
					last_camera_tile = current_camera_tile
					draw_tiles(current_camera_tile, deg2num(latitude, longitude, zoom))
					_limpiar_tiles_lejanos(current_camera_tile)

func _update_map():
	if not is_inside_tree(): return

	for child in get_children():
		if child is HTTPRequest:
			child.cancel_request() 
			child.queue_free()
			
	for tile_pos in loaded_tiles.keys():
		var tile = loaded_tiles[tile_pos]
		if is_instance_valid(tile):
			tile.queue_free()
			
	loaded_tiles.clear()
	loading_tiles.clear()
	last_camera_tile = Vector2(99999, 99999)
	
	var osmPoint = deg2num(latitude, longitude, zoom)
	draw_tiles(Vector2(0,0), osmPoint)

func draw_tiles(t_point, o_point):
	for x in range(t_point.x - 3, t_point.x + 4):
		for y in range(t_point.y - 3, t_point.y + 4):
			var pos = Vector2(x, y)
			if not loading_tiles.has(pos) and not loaded_tiles.has(pos):
				_request_tile(pos, o_point + pos)

func _request_tile(tile_pos: Vector2, osm_pos: Vector2):
	loading_tiles.append(tile_pos)
	
	var cache_path = "user://map_cache/%d_%d_%d.png" % [zoom, int(osm_pos.x), int(osm_pos.y)]
	
	if FileAccess.file_exists(cache_path):
		_load_tile_from_cache(tile_pos, cache_path)
		return
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	var url = base_url + "&x=%d&y=%d&z=%d" % [int(osm_pos.x), int(osm_pos.y), zoom]
	var headers = ["User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0 Safari/537.36"]
	
	http_request.request_completed.connect(func(_result, response_code, _headers_res, body):
		_on_tile_received(_result, response_code, body, tile_pos, http_request, cache_path)
	)
	http_request.request(url, headers)

func _load_tile_from_cache(tile_pos: Vector2, cache_path: String):
	var image = Image.new()
	var err = image.load(cache_path)
	if err != OK:
		loading_tiles.erase(tile_pos)
		return
	_crear_sprite_calle(image, tile_pos)

func _on_tile_received(result, response_code, body, tile_pos: Vector2, http_node: HTTPRequest, cache_path: String):
	if is_instance_valid(http_node):
		http_node.queue_free()
	
	if response_code != 200 or result != HTTPRequest.RESULT_SUCCESS:
		loading_tiles.erase(tile_pos)
		return
		
	var image = Image.new()
	var err = image.load_png_from_buffer(body)
	if err != OK:
		loading_tiles.erase(tile_pos)
		return
		
	image.save_png(cache_path)
	_crear_sprite_calle(image, tile_pos)

func _crear_sprite_calle(image: Image, tile_pos: Vector2):
	var texture = ImageTexture.create_from_image(image)
	var sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.position = tile_pos * 256.0
	sprite.z_index = 0
	add_child(sprite)
	loaded_tiles[tile_pos] = sprite
	loading_tiles.erase(tile_pos)

func _limpiar_tiles_lejanos(centro_tile: Vector2):
	var distancia_max = 5
	var tiles_a_borrar = []
	for tile_pos in loaded_tiles.keys():
		if abs(tile_pos.x - centro_tile.x) > distancia_max or abs(tile_pos.y - centro_tile.y) > distancia_max:
			tiles_a_borrar.append(tile_pos)
	for pos in tiles_a_borrar:
		if is_instance_valid(loaded_tiles[pos]):
			loaded_tiles[pos].queue_free()
		loaded_tiles.erase(pos)

### FUNCIONES MATEMÁTICAS ###
func deg2num(lat, lon, z):
	var lat_rad = deg_to_rad(lat)
	var n = pow(2.0, z)
	var xtile = int((((lon + 180.0) / 360.0)) * n)
	var ytile = int((1.0 - log(tan(lat_rad) + 1/cos(lat_rad)) / PI) / 2.0 * n)
	return Vector2(xtile, ytile)

func deg2num_exact(lat, lon, z) -> Vector2:
	var lat_rad = deg_to_rad(lat)
	var n = pow(2.0, z)
	var xtile = ((lon + 180.0) / 360.0) * n
	var ytile = (1.0 - log(tan(lat_rad) + 1/cos(lat_rad)) / PI) / 2.0 * n
	return Vector2(xtile, ytile)

func lat_lon_to_pixel(lat_lon: Vector2) -> Vector2:
	var exact_tile = deg2num_exact(lat_lon.x, lat_lon.y, zoom)
	var current_osm_point = deg2num(latitude, longitude, zoom)
	return (exact_tile - current_osm_point) * 256.0

func num2deg(xtile: float, ytile: float, z: int) -> Vector2:
	var n = pow(2.0, z)
	var lon_deg = (xtile / n) * 360.0 - 180.0
	var lat_rad = atan(sinh(PI * (1.0 - 2.0 * ytile / n)))
	var lat_deg = rad_to_deg(lat_rad)
	return Vector2(lat_deg, lon_deg)

func pixel_to_lat_lon(pixel_pos: Vector2) -> Vector2:
	var current_osm_point = deg2num(latitude, longitude, zoom)
	var fractional_tile = current_osm_point + (pixel_pos / 256.0)
	return num2deg(fractional_tile.x, fractional_tile.y, zoom)
