extends Node2D

export var very_back_tilemap: NodePath
export var back_tilemap: NodePath
export var middle_tilemap: NodePath
export var front_tilemap: NodePath

onready var very_back_tilemap_node = get_node(very_back_tilemap)
onready var back_tilemap_node = get_node(back_tilemap)
onready var middle_tilemap_node = get_node(middle_tilemap)
onready var front_tilemap_node = get_node(front_tilemap)

var level_data : LevelData
var level_area : LevelArea

var tileset_cache := []

var noise := OpenSimplexNoise.new()

func _ready():
	var level_tilesets := preload("res://assets/tiles/ids.tres")
	for tileset_id in level_tilesets.ids:
		var tileset : LevelTileset = load("res://assets/tiles/" + tileset_id + "/resource.tres")
		tileset_cache.append(tileset)
	
func get_tile(tileset_id, tile_id):
	var tileset = tileset_cache[tileset_id]
	if tile_id == 0:
		return tileset.block_tile_id
	elif tile_id == 1:
		return tileset.slab_tile_id
	elif tile_id == 2:
		return tileset.left_slope_tile_id
	else:
		return tileset.right_slope_tile_id

# func place_edges(pos, placing_tile, bounds, tilemap_node):
# 	var top :    bool = pos.x == bounds.position.x
# 	var left :   bool = pos.x == bounds.position.y
# 	var bottom : bool = pos.x == bounds.end.x - 1
# 	var right :  bool = pos.x == bounds.end.y - 1
	
# 	if left:
# 		tilemap_node.set_cell(-1, pos.y, placing_tile)
# 	if top:
# 		tilemap_node.set_cell(pos.x, -1, placing_tile)
# 	if left and top:
# 		tilemap_node.set_cell(-1, -1, placing_tile)
# 	if left and bottom:
# 		tilemap_node.set_cell(-1, bounds.y, placing_tile)
		
# 	if pos.x == bounds.x - 1:
# 		tilemap_node.set_cell(bounds.x, pos.y, placing_tile)
# 	if pos.y == bounds.y - 1:
# 		tilemap_node.set_cell(pos.x, bounds.y, placing_tile)
# 	if pos.x == bounds.x - 1 and pos.y == bounds.y - 1:
# 		tilemap_node.set_cell(bounds.x, bounds.y, placing_tile)
# 	if pos.x == bounds.x - 1 and pos.y == 0:
# 		tilemap_node.set_cell(bounds.x, -1, placing_tile)
	
const emptyTile = [0,0]
func get_tile_in_data(x: int, y: int, layer: int):

	#warning-ignore:integer_division
	var chunk_key = str(x/16,":",y/16,":",layer)

	
	if level_area.tile_chunks.has(chunk_key):
		var tile = level_area.tile_chunks[chunk_key][x%16+(y%16)*16]
		return tile if tile else emptyTile
	else:
		return emptyTile

var numChunks : int = 0
func set_tile(x: int, y: int, layer: int, tileset_id: int, tile_id: int):
	#warning-ignore:integer_division
	var chunk_key = str(x/16,":",y/16,":",layer)

	var chunk: Array
	if level_area.tile_chunks.has(chunk_key):
		chunk = level_area.tile_chunks[chunk_key]
	else:
		chunk = []
		chunk.resize(16*16)
		level_area.tile_chunks[chunk_key] = chunk
	
	chunk[x%16+(y%16)*16] = [tileset_id, tile_id]
	
	set_tile_visual(x, y, layer, tileset_id, tile_id)
		
func set_tile_visual(x: int, y: int, layer: int, tileset_id: int, tile_id: int, update_bitmask: bool = true):
	var cache_tile = get_tile(tileset_id, tile_id)
	var layer_tilemap_node = back_tilemap_node
	if layer == 3:
		layer_tilemap_node = very_back_tilemap_node	
	elif layer == 1:
		layer_tilemap_node = middle_tilemap_node	
	elif layer == 2:
		layer_tilemap_node = front_tilemap_node	
	if layer_tilemap_node.get_cell(x, y) != cache_tile:
		layer_tilemap_node.set_cell(x, y, cache_tile)
		if(update_bitmask):
			layer_tilemap_node.update_bitmask_area(Vector2(x, y))

func load_in(loaded_level_data : LevelData, loaded_level_area : LevelArea):
	
	level_data = loaded_level_data
	level_area = loaded_level_area
	
	update_tilemaps()

func update_tilemaps():
	var bounds = level_area.settings.bounds
	
	very_back_tilemap_node.clear()
	back_tilemap_node.clear()
	middle_tilemap_node.clear()
	front_tilemap_node.clear()
	
	for key in level_area.tile_chunks:
		var chunk : Array = level_area.tile_chunks[key]

		var _key : Array = key.split(":")
		var chunk_x := int(_key[0])
		var chunk_y := int(_key[1])
		var layer 	:= int(_key[2])

		#print(_key)

		for x in range(16):
			for y in range(16):
				var tile = chunk[x + y*16] #get tile from chunk
				if tile and bounds.has_point(Vector2(chunk_x*16 + x + 0.5, chunk_y*16 + y + 0.5)):
					set_tile_visual(chunk_x*16 + x, chunk_y*16 + y, layer, tile[0], tile[1], false) #no need to update bitmask individually

	
	var tile : int = middle_tilemap_node.tile_set.find_tile_by_name("LevelMargin")


	var left: int = bounds.position.x-1
	var top: int = bounds.position.y-1
	var right: int = bounds.end.x
	var bottom: int = bounds.end.y
	
	for tilemap in [very_back_tilemap_node, back_tilemap_node, middle_tilemap_node, front_tilemap_node]:
		for x in range(left, (right)+1): #range end needs +1 to to actually reach the end
			tilemap.set_cell(x,top, tile)
			tilemap.set_cell(x,bottom, tile)

		for y in range(top+1, (bottom-1)+1): #range end needs +1 to to actually reach the end
			tilemap.set_cell(left, y, tile)
			tilemap.set_cell(right, y, tile)

		tilemap.update_bitmask_region(bounds.position, bounds.end)
	
	tile = middle_tilemap_node.tile_set.find_tile_by_name("OutOfBounds")
	
	
	for x in range(left-2, (right+2)+1): #range end needs +1 to to actually reach the end
		very_back_tilemap_node.set_cell(x,top, tile)
		very_back_tilemap_node.set_cell(x,top-1, tile)
		very_back_tilemap_node.set_cell(x,top-2, tile)
		
		very_back_tilemap_node.set_cell(x,bottom, tile)
		very_back_tilemap_node.set_cell(x,bottom+1, tile)
		very_back_tilemap_node.set_cell(x,bottom+2, tile)

	for y in range(top+1, (bottom-1)+1): #range end needs +1 to to actually reach the end
		very_back_tilemap_node.set_cell(left, y, tile)
		very_back_tilemap_node.set_cell(left-1, y, tile)
		very_back_tilemap_node.set_cell(left-2, y, tile)
		
		very_back_tilemap_node.set_cell(right, y, tile)
		very_back_tilemap_node.set_cell(right+1, y, tile)
		very_back_tilemap_node.set_cell(right+2, y, tile)
