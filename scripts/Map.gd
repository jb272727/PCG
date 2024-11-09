@tool
extends Node3D
@onready var grid_map : GridMap = $GridMap

@export var horDiv : int = 17
@export var vertDiv : int = 10

@export var articProb : float = .90 # for snow biome
@export var midProb : float = .80 # for grass biome
@export var equatorProb : float = .60 # for desert biome

enum Tile {
	full,
	noTop,
	noRight,
	noBottom,
	noLeft,
	noTopNoRight,
	noTopNoBottom,
	noTopNoLeft,
	noRightNoBottom,
	noRightNoLeft,
	noRightNoTop,
	noBottomNoLeft,
	noBottomNoTop,
	noBottomNoRight,
	noLeftNoTop,
	noLeftNoRight,
	noLeftNoBottom,
	noTopNoRightNoBottom,
	noTopNoRightNoLeft,
	noTopNoBottomNoLeft,
	noTopNoBottomNoRight,
	noTopNoLeftNoRight,
	noTopNoLeftNoBottom,
	noRightNoBottomNoLeft,
	noRightNoLeftt,
	noRightNoToptt,
	noBottomNoLefttt,
	noBottomNoToptt,
	noBottomNoRighttt,
	noLeftNoToptt,
	noLeftNoRighttt,
	noLeftNoBottomtt,
}

var rng = RandomNumberGenerator.new()
@export var seed : int : set = set_seed
func set_seed(val: int) -> void:
	seed = val
	if rng and (seed != 0):
		rng.seed = seed

@export var start : bool = false : set = set_start
func set_start(val:bool)->void:
	generate()

@export var map_size: int = 100 : set = set_map_size
func set_map_size(val : int)->void:
	map_size = val
	if Engine.is_editor_hint():
		visualize_border()

@export var clear_gridmap: bool = false : set = set_clear_gridmap
func set_clear_gridmap(val: bool) -> void:
	clear_gridmap = val
	if Engine.is_editor_hint() and val:
		clear_grid()
		# Reset the checkbox to false after clearing the GridMap
		clear_gridmap = false
		notify_property_list_changed()

func find_median(n: int) -> float:
	if n <= 0:
		return 0  # Handling case where n is non-positive
	
	if n % 2 == 0:
		# For even n, the median is the average of the two middle numbers
		var mid1 = n / 2
		var mid2 = mid1 + 1
		if rng.randf() > .5:
			return mid1
		else:
			return mid2
	else:
		# For odd n, the median is the middle number
		return float((n + 1) / 2)

func visualize_border():
	print("visualizing border")
	for i in range(0, map_size+1):
		grid_map.set_cell_item(Vector3i(i,0,0), 4)
		grid_map.set_cell_item(Vector3i(i,0,map_size), 4)
		i += 1
	for i in range(0, map_size+1):
		grid_map.set_cell_item(Vector3i(0,0,i), 4)
		grid_map.set_cell_item(Vector3i(map_size,0,i), 4)
		i += 1

func generate_heightmap() -> Array:
	var heightmap = []
	var perlin_noise = FastNoiseLite.new()

	# Set Perlin noise parameters
	perlin_noise.seed = rng.randi()
	perlin_noise.fractal_octaves = 6
	perlin_noise.fractal_gain = 0.5
	perlin_noise.frequency = 0.5

	for x in range(map_size+1):
		var column = []
		for y in range(map_size+1):
			# Get Perlin noise value for the current position
			var noise_value = perlin_noise.get_noise_2d(x / 10.0, y / 10.0)
			# Map the noise value to the range [0, 1]
			var height = (noise_value + 1.0) / 2.0
			column.append(height)
		heightmap.append(column)
	return heightmap

func fill_map():
	for j in range(0, map_size+1):
		for i in range(0, map_size+1):
			$GridMap.set_cell_item(Vector3i(i,0,j), 6)

func find_biomes(cell : Vector3i, arraypts : Array) -> Array:
	var distances = []
	var v1 = Vector2(cell.x, cell.z)
	for pt in arraypts:
		var v2 = Vector2(pt.x, pt.y)
		distances.append(v1.distance_to(v2))
	return distances

func get_curved_path(start: Vector2, end: Vector2, width: int) -> Array:
	var path = []

	# Calculate the delta between start and end points
	var dx = end.x - start.x
	var dy = end.y - start.y

	# Bresenham's line algorithm
	var p = 2 * dy - dx
	var y = start.y

	for x in range(start.x, end.x + 1):
		# Add the main point
		path.append(Vector3(x, 0, y))
		
		# Add adjacent points to increase width
		for w in range(1, width + 1):
			path.append(Vector3(x + w, 0, y))
			path.append(Vector3(x - w, 0, y))

		if p > 0:
			y += 1
			p += 2 * dy - 2 * dx
		else:
			p += 2 * dy

	return path

func get_orientation() -> int:
	var orientations = [0,10,16,22]
	var index = rng.randi_range(0, orientations.size() - 1)
	return orientations[index]

func generate():
	print("generating...") #find number of pts by dividing map size // rng.randi_range(,)
	var heightmap = generate_heightmap()
	
	var ptsHor : int
	var ptsVert : int
	ptsHor = map_size / horDiv
	ptsVert = map_size / vertDiv
	var pos : Vector2 = Vector2(0,0)
	#fill array of biomepts 
	var arraypts = []
	for i in range(0, ptsVert):
		pos.x = 0
		pos.y += vertDiv
		for j in range(0, ptsHor):
			pos.x += horDiv
			arraypts.append(Vector2(pos))
	print(arraypts)
	print(ptsHor)
	print(ptsVert)
	# use rng to find out biome for each pt
	var biomepts = [] # array of: 7 - snow | 4 - grass | 8 - desert // replace: 4 with 6, 7 with 22, 8 with 38
	for i in range(arraypts.size()):
		biomepts.append(i) # initializing array
	var mid : float = find_median(ptsVert)
	print(mid)
	for i in range(0, ptsVert):
		for j in range(0, ptsHor):
			if i == 0:
				if rng.randf() < articProb:
					biomepts[(ptsHor*i)+j] = 22
				else:
					biomepts[(ptsHor*i)+j] = 6
			if i == 1:
				if rng.randf() < midProb:
					biomepts[(ptsHor*i)+j] = 6
				else:
					biomepts[(ptsHor*i)+j] = 22
			if i > 1 and i < mid-1:
				if rng.randf() < midProb:
					biomepts[(ptsHor*i)+j] = 6
				else:
					biomepts[(ptsHor*i)+j] = 38
			if i == mid-1:
				if rng.randf() < equatorProb:
					biomepts[(ptsHor*i)+j] = 38
				else:
					biomepts[(ptsHor*i)+j] = 6
			if i >mid-1 and i< ptsVert-2:
				if rng.randf() < midProb:
					biomepts[(ptsHor*i)+j] = 6
				else:
					biomepts[(ptsHor*i)+j] = 38
			if i == ptsVert-2:
				if rng.randf() < midProb:
					biomepts[(ptsHor*i)+j] = 6
				else:
					biomepts[(ptsHor*i)+j] = 22
			if i == ptsVert-1:
				if rng.randf() < articProb:
					biomepts[(ptsHor*i)+j] = 22
				else:
					biomepts[(ptsHor*i)+j] = 6
	print(biomepts)
	fill_map()
	
	#iterate through each tile in the map and find distance to nearest biomes point and give closest biomes heaviest
	for i in range(0, arraypts.size()):
		arraypts[i].x += rng.randi_range(-3,3)
		arraypts[i].y += rng.randi_range(-3,3)
	#print(arraypts)
	for i in range(0,50):
		var randomIndex = rng.randi_range(0, arraypts.size()-1)
		var randompt = arraypts[randomIndex]
		var randomBiome = biomepts[randomIndex]
		#if rng.randf() < .2:
			#randomBiome = 4
		var newpt = randompt
		newpt.x += rng.randi_range(-3,3)
		newpt.y += rng.randi_range(-3,3)
		arraypts.insert(randomIndex, newpt)
		biomepts.insert(randomIndex, randomBiome)
	#print(arraypts)
	var count : int = 0
	for pt in biomepts: # desert corrections
		if pt == 38:
			count += 1
	if count > 6:
		for i in range(0, arraypts.size()):
			if biomepts[i] == 38:
				if rng.randf() < .57:
					biomepts[i] = 6
	#print(biomepts)
	var used_cells = $GridMap.get_used_cells()
	for cell in used_cells:
		var distances = find_biomes(cell, arraypts)
		var biomeDistances = []
		for i in range(biomepts.size()):
			biomeDistances.append(Vector2(biomepts[i], distances[i]))
		var valid_distances = []  # Create a new array for valid distances
		for distance in biomeDistances:
			if distance.y < horDiv * 1.9:  # Only add distances that are valid
				valid_distances.append(distance)
		#print(valid_distances)
		
		var mins = valid_distances[0].y
		#var min2 = min
		var toSet = valid_distances[0].x 
		#var toSet2 = toSet
		for distance in valid_distances:
			if distance.y <= mins:
				#min2 = min
				#toSet2 = toSet
				mins = distance.y
				toSet = distance.x
		#if min >= (vertDiv/2) - 0.05 and min < vertDiv:
			#if rng.randf() < 0.95/min:
				#grid_map.set_cell_item(cell, toSet2)
		#else:
				$GridMap.set_cell_item(cell, toSet)

	used_cells = $GridMap.get_used_cells()
	for cell in used_cells:
		var type = $GridMap.get_cell_item(cell)
		var currCell = cell
		currCell.y += 1
		var random = rng.randf()
		var x = cell.x
		var z = cell.z
		var height = heightmap[x][z]
		if height < .4:
			$GridMap.set_cell_item(cell, 5)  # ocean
		elif height < .3:
			$GridMap.set_cell_item(cell, 1)  # deep ocean
		elif height > .7 and height <= .8:
			$GridMap.set_cell_item(currCell, 4, get_orientation()) # mountain
		elif type == 6 || type == 22: # placing trees
			if height > .6:
				if random < .8:
					$GridMap.set_cell_item(currCell, 3, get_orientation()) # forest 1
			else:
				if random < .05:
					$GridMap.set_cell_item(currCell, 3, get_orientation())
				elif random < .45:
					$GridMap.set_cell_item(currCell, 2, get_orientation()) # forest 2

	used_cells = $GridMap.get_used_cells()
	for cell in used_cells:
		if cell.y == 1:
			break
		var type = $GridMap.get_cell_item(cell)
		var downCell = cell
		var aboveCell = cell
		var belowCell = cell
		var rightCell = cell
		var leftCell = cell
		var currCell = cell
		currCell.y += 1
		downCell.y -= 1
		belowCell.z += 1
		aboveCell.z -= 1
		rightCell.x += 1
		leftCell.x -= 1
		if type != 5 and type != 1:
			var toAdd
			if type == 6:
				toAdd = 0
			elif type == 22:
				toAdd = 16
			elif type == 38:
				if rng.randf() < .33:
					$GridMap.set_cell_item(currCell, 0, get_orientation())
				toAdd = 32
			var sides = [0,0,0,0]
			var abv
			var bel
			var left
			var right
			if $GridMap.get_cell_item(aboveCell) != -1:
				abv = $GridMap.get_cell_item(aboveCell)
				if abv == 5 or abv == 1:
					sides[0] = 1
			if $GridMap.get_cell_item(belowCell) != -1:
				bel = $GridMap.get_cell_item(belowCell)
				if bel == 5 or bel == 1:
					sides[2] = 1
			if $GridMap.get_cell_item(leftCell) != -1:
				left = $GridMap.get_cell_item(leftCell)
				if left == 5 or left == 1:
					sides[3] = 1
			if $GridMap.get_cell_item(rightCell) != -1:
				right = $GridMap.get_cell_item(rightCell)
				if right == 5 or right == 1:
					sides[1] = 1
			if sides[0] == 1:
				if sides[1] == 1:
					if sides[2] == 1:
						if sides[3] == 1:
							print("island")
						elif sides[3] == 0:
							$GridMap.set_cell_item(cell, 11 + toAdd - 3, 22)
					elif sides[2] == 0:
						if sides[3] == 1:
							$GridMap.set_cell_item(cell, 12 + toAdd - 3, 22)
						elif sides[3] == 0:
							$GridMap.set_cell_item(cell, 13 + toAdd - 3, 22)
				elif sides[1] == 0:
					if sides[2] == 1:
						if sides[3] == 1:
							$GridMap.set_cell_item(cell, 14 + toAdd - 3, 22)
						elif sides[3] == 0:
							$GridMap.set_cell_item(cell, 15 + toAdd - 3, 22)
					elif sides[2] == 0:
						if sides[3] == 1:
							$GridMap.set_cell_item(cell, 16 + toAdd - 3, 22)
						elif sides[3] == 0:
							$GridMap.set_cell_item(cell, 17 + toAdd - 3, 22)
			elif sides[0] == 0:
				if sides[1] == 1:
					if sides[2] == 1:
						if sides[3] == 1:
							$GridMap.set_cell_item(cell, 18 + toAdd - 3, 22)
						elif sides[3] == 0:
							$GridMap.set_cell_item(cell, 19 + toAdd - 3, 22)
					elif sides[2] == 0:
						if sides[3] == 1:
							$GridMap.set_cell_item(cell, 20 + toAdd - 3, 22)
						elif sides[3] == 0:
							$GridMap.set_cell_item(cell, 21 + toAdd - 3, 22)
				elif sides[1] == 0:
					if sides[2] == 1:
						if sides[3] == 1:
							$GridMap.set_cell_item(cell, 22 + toAdd - 3, 22)
						elif sides[3] == 0:
							$GridMap.set_cell_item(cell, 23 + toAdd - 3, 22)
					elif sides[2] == 0:
						if sides[3] == 1:
							$GridMap.set_cell_item(cell, 24 + toAdd - 3, 22)
						elif sides[3] == 0:
							$GridMap.set_cell_item(cell, 10 + toAdd - 3, 22)



func clear_grid():
	print("Clearing GridMap...")
	var cell_list = $GridMap.get_used_cells()
	for cell in cell_list:
		$GridMap.set_cell_item(cell, -1)  # Setting to -1 clears the cell
	print("GridMap cleared")

