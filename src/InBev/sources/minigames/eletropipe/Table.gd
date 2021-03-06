extends Node2D

const MAX_TILE_SIZE = Vector2(4, 6)

const PIPES_TYPE = {
	ENTER = "ENTER",
	PATH = "NORMAL",
	EXIT = "EXIT"
}

const PIPES_NAME = {
	DEFAULT = "PIPE_"
}

const PIPES_FORMAT = {
	DEFAULT = "DEFAULT",
	CURVED = "CURVED",
	STRAIGHT = "STRAIGHT"
}

const STATUS_MESSAGE = {
	NOT_CONNECTED = "NÃO CONECTADOS",
	CONNECTED = "CONECTADOS",
	CHECKING = "VERIFICANDO"
}

const STATUS_COLOR = {
	NOT_CONNECTED = "#FF6188",
	CONNECTED = "#A9DC76",
	CHECKING = "#FFD865"
}

onready var pipeCurvedScene = preload("res://scenes/minigames/eletropipe/bases/PipeCurved.tscn")
onready var pipeStraightScene = preload("res://scenes/minigames/eletropipe/bases/PipeStraight.tscn")

var checkingPipe = false
var pipesAcitiveList = []

static func calculate_distance_of_tile(tilePosition1, tilePosition2):
	return (tilePosition1 - tilePosition2).length()

func load_map(map_id):
	"""
		Loads a map from the map id.
		default map id: Level_{ID}
	"""
	var mapInstance = load("res://scenes/minigames/eletropipe/maps/Level_%d.tscn" % map_id).instance() # Copy a instance of map from the resource
	add_child(mapInstance)

func connected():
	"""
		Shows the win layer and set labels for connected.
	"""
	get_node("../Interface/StatusLabel").text = STATUS_MESSAGE.CONNECTED # Set the status label
	get_node("../Interface/StatusLabel").set("custom_colors/font_color", Color(STATUS_COLOR.CONNECTED)) # Set the status label color

	get_node("../WinLayer").modulate.a = 0 # Hide the win layer with modulation
	get_node("../WinLayer").visible = true # Show the win layer
	get_node("AnimationTween").interpolate_property(get_node("../WinLayer"), "modulate:a", 0, 1,  0.75, Tween.TRANS_LINEAR, Tween.EASE_IN) # Create animation
	get_node("AnimationTween").start() # Start animation

	checkingPipe = false

func not_connected():
	"""
		Update label with message for not connected.
	"""

	get_node("../Interface/StatusLabel").text = STATUS_MESSAGE.NOT_CONNECTED # Update label text
	get_node("../Interface/StatusLabel").set("custom_colors/font_color", Color(STATUS_COLOR.NOT_CONNECTED))# Update label color

	revert_energy_system() # Revert energy system

func checking_connected():
	"""
		Update label with message for checking connected.
	"""

	get_node("../Interface/StatusLabel").text = STATUS_MESSAGE.CHECKING # Update label text
	get_node("../Interface/StatusLabel").set("custom_colors/font_color", Color(STATUS_COLOR.CHECKING)) # Update label color

func _ready():
	get_node("../WinLayer").visible = false # Hide win layer

func reset_pipes_modulation():
	"""
		Resets the pipes modulation.
	"""
	for pipe in get_all_pipes(): # For each pipe
		if pipe.type == PIPES_TYPE.PATH: # If is a path pipe
			pipe.modulate = Color(1, 1, 1) # Reset modulation

func is_pipes_path_connected():
	"""
		Change win layer if the pipes are connected.
	"""
	checking_connected()

	var currentPipeTrack = get_pipe_enter() # Get the current pipe track
	var endPipe = get_pipe_exit() # get the exit pipe

	var trackList = [] # list of track

	var nextDirection = Vector2.ZERO # The direction of the next pipe
	var lastDirection = Vector2.ZERO # The direction of the last pipe

	for _pipe in get_node("Pipes").get_children(): # Limit the search to the pipes with the numbers of pipes
		trackList.append(currentPipeTrack) # Add the current pipe track to the list

		for outerDirection in currentPipeTrack.get_holes_sides(): # Get the outer direction of the current pipe
			if outerDirection * -1 == lastDirection: # If the direction is the same as the last direction
				continue

			var dumpPipe = get_next_pipe_from_direction(currentPipeTrack.tilePosition, outerDirection) # Get the next pipe from the direction

			if dumpPipe == null: # Check if pipe exist
				continue

			for innerDirection in dumpPipe.get_holes_sides(): # Get the inner direction of the next pipe
				if innerDirection * -1 == outerDirection: # If the direction is the same as the outer direction
					nextDirection = outerDirection # Set the next direction
					break

			if nextDirection != Vector2.ZERO: # Check if the next direction is not zero and break outer loop
				break

		if nextDirection == Vector2.ZERO: # Check if the next direction is zero
			print("[Eletropipe] NOT CONNECT: Next direction not found from " + "(%d,%d)" % [lastDirection.x, lastDirection.y] + " to " + "(%d,%d)" % [currentPipeTrack.tilePosition.x, currentPipeTrack.tilePosition.y])
			not_connected()
			return

		currentPipeTrack = get_next_pipe_from_direction(currentPipeTrack.tilePosition, nextDirection) # Get the next pipe

		if currentPipeTrack == null: # Check if the pipe exist
			print("[Eletropipe] NOT CONNECT: The pipes are not connected to continue.")
			not_connected()
			return

		elif currentPipeTrack == endPipe: # Check if the current pipe is the end pipe
			print("[Eletropipe] CONNECTED: The pipes are connected!.")
			connected()
			return

		init_energy_system(currentPipeTrack) # Init the energy system
		yield(get_node("AnimationTween"), "tween_all_completed") # Wait tween animation complete

		lastDirection = nextDirection # Set the last direction
		nextDirection = Vector2.ZERO # Reset the next direction

func create_pipe(style, tilePosition):
	"""
		Create a pipe with the given position and type.
		Style: The style of the pipe: 'curved' or 'straight'.
		TilePosition: The position of the pipe.
	"""
	var pipe = null # The pipe to be created

	if style == "curved": # If the style is curved
		pipe = pipeCurvedScene.instance() # Create the pipe
	elif style == "straight": # If the style is straight
		pipe = pipeStraightScene.instance() # Create the pipe

	pipe.tilePosition = tilePosition # Set the position of the pipe
	return pipe # Return the pipe

func get_random_seed():
	"""
		Return a random seed.
	"""
	var rng = RandomNumberGenerator.new() # Create a new random number generator
	rng.randomize() # Randomize the number generator
	return rng.randi() # Return a random integer

func get_distance_from_exit(currentTilePosition):
	"""
		Return the distance length from the exit.
	"""
	var exitPipe = get_pipe_exit() # Get the exit pipe
	return calculate_distance_of_tile(currentTilePosition, exitPipe.tilePosition) # Return the distance from the exit

func get_free_directions(tilePosition, directions = [Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]):
	"""
		Return a list of possible directions from the given position.
	"""

	for direction in directions: # For each direction
		var testDirection = tilePosition + direction
		if testDirection.x > MAX_TILE_SIZE.x or testDirection.y > MAX_TILE_SIZE.y or testDirection.x < 0 or testDirection.y < 0: # Check if the position is out of bounds
			directions.remove(direction) # Remove the direction from the list
			continue

		if get_pipe_from_tile(testDirection) != null: # Check if the position is a pipe
			directions.remove(direction) # Remove the direction from the list
			continue

	return directions # Return the list of possible directions

#func get_formated_next_pipe(lastPipe, lastPipeDirection, nextPipeDirection):
#	"""
#		Return the type of the next pipe with base of last pipe added.
#	"""
#	var pipe = null

#	if lastPipe.format  == PIPES_FORMAT.STRAIGHT:
#		if lastPipe.get_holes_sides() in [Vector2.DOWN, Vector2.UP]:
#			if direction in [Vector2.LEFT, Vector2.RIGHT]:
#				pass
#	pipe.tilePosition = lastPipe.tilePosition + direction

#	return pipe

#func generate_random_pipes_path():
#	"""
#		Simulate a artificial intelligence to generate a random pipes path.
#	"""
#	var enterPipe = get_pipe_enter() # Get the current pipe track
#	var endPipe = get_pipe_exit() # get the exit pipe

#	var lastPipe = enterPipe # The last pipe

#	for _i in range(MAX_TILE_SIZE.x * MAX_TILE_SIZE.y):
#		var nextDirection = get_free_directions(enterPipe.tilePosition, enterPipe.get_holes_sides()) # Get the next direction

#		if nextDirection.empty():
#			print("[Eletropipe] NOT FOUND FREE DIRECTION: The pipes dont have free directions.")
#			return false

#		nextDirection = nextDirection[get_random_seed() % nextDirection.size()] # Get a random direction

func init_energy_system(pipe):
	"""
		Initialize the energy system of the pipe.
	"""
	get_node("AnimationTween").interpolate_property(pipe, "modulate", pipe.modulate, Color("#78DCE8"),  0.20, Tween.TRANS_LINEAR, Tween.EASE_IN) # Create animation
	get_node("AnimationTween").start() # Start animation

	pipesAcitiveList.append(pipe)

func revert_energy_system():
	if pipesAcitiveList.empty():
		checkingPipe = false # Set checking pipe to false
		return

	pipesAcitiveList.invert()

	for pipe in pipesAcitiveList:
		if pipe:
			get_node("AnimationTween").interpolate_property(pipe, "modulate", Color("#78DCE8"), Color(1, 1, 1, 1),  0.20,  Tween.TRANS_LINEAR, Tween.EASE_IN) # Create animation
			get_node("AnimationTween").start() # Start animation
			yield(get_node("AnimationTween"), "tween_all_completed") # Wait tween animation complete

	pipesAcitiveList.clear() # Clear the list

	checkingPipe = false # Set checking pipe to false

func get_pipe_enter():
	"""
		Return the pipe at the entrance.
	"""
	for pipe in get_node("Pipes").get_children(): # Search for the pipe at the entrance
		if pipe.type == PIPES_TYPE.ENTER: # If the pipe is at the entrance
			return pipe # Return the pipe at the entrance
	return null # Return null if there is no pipe at the entrance


func get_pipe_exit():
	"""
		Return the pipe at the exit.
	"""
	for pipe in get_node("Pipes").get_children(): # Search for the pipe at the exit
		if pipe.type == PIPES_TYPE.EXIT: # If the pipe is at the exit
			return pipe # Return the pipe at the exit
	return null # Return null if there is no pipe at the exit

func get_pipe_from_tile(tile):
	"""
		Returns the pipe at the given tile position.
		If there is no pipe at the given position, returns null.
	"""
	return get_node("Pipes").get_node_or_null(PIPES_NAME.DEFAULT + ("%dx%d" % [tile.x, tile.y])) # Return the pipe at the given position.

func get_next_pipe_from_direction(tile, direction):
	"""
		Returns the next pipe in the given direction.
		If there is no pipe in the given direction, returns null.
	"""
	return get_pipe_from_tile(tile + direction) # Return the pipe in the given direction from position.

func get_all_pipes():
	"""
		Returns all pipes in the table.
	"""
	var pipes = [] # Create a list to store all pipes.

	for xIdx in range(MAX_TILE_SIZE.x): # For each x index.
		for yIdx in range(MAX_TILE_SIZE.y): # For each y index.
			var pipe = get_pipe_from_tile(Vector2(xIdx, yIdx))
			if pipe:
				pipes.append(pipe) # Add the pipe at the given position to the list.

	return pipes # Return all pipes in the game.

func _on_TestConnectionButton_pressed():
	if checkingPipe:
		return
	checkingPipe = true
	print(is_pipes_path_connected())
