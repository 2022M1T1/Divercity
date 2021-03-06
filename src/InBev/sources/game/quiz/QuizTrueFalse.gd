extends Control

export(String) var correctAnswer
export(Dictionary) var otherAnswer
export(String) var quizzQuestion

export(String) var callbackScenePath
export(Dictionary) var callbackSceneParams

signal change_scene # Create local signal for change to game scene

var correctButttonPath = null
var lastClickTime = 0

func _construct(mainNode):
	"""
		Node constructor
	"""
	connect("change_scene", mainNode, "_change_scene_to") # Connect callback for local signal

func _ready():
	$QuestionLabel.text = quizzQuestion # Set question text

	randomize() # Randomize answers

	var nodesAnswers = ["AnswersLabel/Answers1Label", "AnswersLabel/Answers2Label"] # List of nodes for answers

	nodesAnswers.shuffle() # Randomize answers

	var copyOtherAnswers = otherAnswer # Copy array of answers

	correctButttonPath = nodesAnswers.pop_front()# Get correct answer button path

	get_node(nodesAnswers[0]).text = copyOtherAnswers["question"] # Set answer text

	get_node(correctButttonPath).text = correctAnswer# Set correct answer text


func correct_answer():
	"""
		On correct answer
	"""
	$AudioStreamPlayer.play_win_quiz_sound()

	emit_signal("change_scene", callbackScenePath, true, callbackSceneParams) # Emit the change scene signal to the game scene

func wrong_answer(question):
	"""
		On wrong answer
	"""
	var response = "" # Response text

	if question == otherAnswer["question"]: # If question is equal to the question
		response = otherAnswer["justification"] # Set response text

	$AudioStreamPlayer.play_lose_quiz_sound()
	$Justification/ResponseLabel.text = response # Set response text
	$Justification.visible = true # Show justification

func check_answer(answer, question): # Check answer
	if correctButttonPath.rfind(answer) != -1: # If answer is correct
		correct_answer() # On correct answer
	else:
		wrong_answer(question) # On wrong answer

func _on_Answer2Button_pressed():
	if $Justification.visible or (OS.get_system_time_msecs() - lastClickTime) < 1000: # If justification is visible or last click was less than 1 second ago
		return
	check_answer(2, get_node("AnswersLabel/Answers2Label").text) # Check answer

func _on_Answer1Button_pressed():
	if $Justification.visible or (OS.get_system_time_msecs() - lastClickTime) < 1000: # If justification is visible or last click was less than 1 second ago
		return
	check_answer(1, get_node("AnswersLabel/Answers1Label").text) # Check answer


func _on_SkipJustificationButton_pressed():
	if not $Justification.visible: # If justification is not visible
		return
	$Justification.visible = false # Hide justification
	lastClickTime = OS.get_system_time_msecs() # Set last click time
