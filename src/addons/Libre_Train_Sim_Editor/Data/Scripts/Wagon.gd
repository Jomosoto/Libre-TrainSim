extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export (float) var length = 17.5

export (bool) var cabinMode = false

var bakedRoute
var bakedRouteDirection
var routeIndex = 0
var forward
var currentRail 
var distanceOnRail = 0
var distance = 0
var speed = 0

var distanceToPlayer = -1

export var pantographEnabled = false


var player
var world

var initialSet = false
# Called when the node enters the scene tree for the first time.
func _ready():
	if cabinMode:
		length = 4
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
var initialSwitchCheck = false
func _process(delta):
	
	if player == null or player.despawning: 
		queue_free()
		return
	
	if not initialSwitchCheck:
		updateSwitchOnNextChange()
		initialSwitchCheck = true
		
	speed = player.speed
	
	if cabinMode:
		drive(delta)
		return
	
	$MeshInstance.show()
	if get_parent().name != "Players": return
	if distanceToPlayer == -1:
		distanceToPlayer = abs(player.distanceOnRail - distanceOnRail)
	visible = player.wagonsVisible
	if not initialSet or not visible:
		$MeshInstance.hide()
	if speed != 0 or not initialSet: 
		drive(delta)
		initialSet = true
	check_doors()
	
	if pantographEnabled:
		check_pantograph()
	
	if not visible: return
	if forward:
		self.transform = currentRail.get_transform_at_rail_distance(distanceOnRail)
	else:
		self.transform = currentRail.get_transform_at_rail_distance(distanceOnRail)
		rotate_object_local(Vector3(0,1,0), deg2rad(180))
	
	if has_node("InsideLight"):
		$InsideLight.visible = player.insideLight
	
	



func drive(delta):
	if currentRail  == player.currentRail:
		if player.forward:
			distanceOnRail = player.distanceOnRail - distanceToPlayer
			distance = player.distance - distanceToPlayer
			if distanceOnRail > currentRail.length:
				change_to_next_rail()
		else:
			distanceOnRail = player.distanceOnRail + distanceToPlayer
			distance = player.distance + distanceToPlayer
			if distanceOnRail < 0:
				change_to_next_rail()
		
		
	else: 
		## Real Driving - Only used, if wagon isn't at the same rail as his player.
		var drivenDistance
		if forward:
			drivenDistance = speed * delta
			distanceOnRail += drivenDistance
			distance += drivenDistance
			if distanceOnRail > currentRail.length:
				change_to_next_rail()
		else:
			drivenDistance = speed * delta
			distanceOnRail -= drivenDistance
			distance += drivenDistance
			if distanceOnRail < 0:
				change_to_next_rail()

func change_to_next_rail():
	if forward:
		distanceOnRail -= currentRail.length
	routeIndex += 1
	currentRail =  world.get_node("Rails").get_node(bakedRoute[routeIndex])
	forward = bakedRouteDirection[routeIndex]
	updateSwitchOnNextChange()

	if not forward:
		distanceOnRail += currentRail.length

var lastDoorRight = false
var lastDoorLeft = false
var lastDoorsClosing = false
func check_doors():
	if player.doorRight and not lastDoorRight:
		$DoorRight.play("open")
	if player.doorRight and not lastDoorsClosing and player.doorsClosing:
		$DoorRight.play_backwards("open")
	if player.doorLeft and not lastDoorLeft:
		$DoorLeft.play("open")
	if player.doorLeft and not lastDoorsClosing and player.doorsClosing:
		$DoorLeft.play_backwards("open")
		
	
	lastDoorRight = player.doorRight
	lastDoorLeft = player.doorLeft
	lastDoorsClosing = player.doorsClosing

var lastPantograph = false
var lastPantographUp = false
func check_pantograph():
	if not self.has_node("Pantograph"): return
	if not lastPantographUp and player.pantographUp:
		print("Started Pantograph Animation")
		$Pantograph/AnimationPlayer.play("Up")
	if lastPantograph and not player.pantograph:
		$Pantograph/AnimationPlayer.play_backwards("Up")
	lastPantograph = player.pantograph
	lastPantographUp = player.pantographUp


## This function is very very basic.. It only checks, if the "end" of the current Rail, or the "beginning" of the next rail is a switch. Otherwise it sets nextSwitchRail to null..
#var nextSwitchRail = null
#var nextSwitchOnBeginning = false
#func findNextSwitch():
#	if forward and currentRail.isSwitchPart[1] != "":
#		nextSwitchRail = currentRail
#		nextSwitchOnBeginning = false
#		return
#	elif not forward and currentRail.isSwitchPart[0] != "":
#		nextSwitchRail = currentRail
#		nextSwitchOnBeginning = true
#		return
#
#	if bakedRoute.size() > routeIndex+1:
#		var nextRail = bakedRoute[routeIndex+1]
#		var nextForward = bakedRouteDirection[routeIndex+1]
#		if nextForward and nextRail.isSwitchPart[0] != "":
#			nextSwitchRail = nextRail
#			nextSwitchOnBeginning = true
#			return
#		elif not nextForward and nextRail.isSwitchPart[1] != "":
#			nextSwitchRail = nextRail
#			nextSwitchOnBeginning = true
#			return
#
#	nextSwitchRail = null
	
var switchOnNextChange = false
func updateSwitchOnNextChange():
	if forward and currentRail.isSwitchPart[1] != "":
		switchOnNextChange = true
		return
	elif not forward and currentRail.isSwitchPart[0] != "":
		switchOnNextChange = true
		return
	
	if bakedRoute.size() > routeIndex+1:
		var nextRail = world.get_node("Rails").get_node(bakedRoute[routeIndex+1])
		var nextForward = bakedRouteDirection[routeIndex+1]
		if nextForward and nextRail.isSwitchPart[0] != "":
			switchOnNextChange = true
			return
		elif not nextForward and nextRail.isSwitchPart[1] != "":
			switchOnNextChange = true
			return
			
	switchOnNextChange = false

