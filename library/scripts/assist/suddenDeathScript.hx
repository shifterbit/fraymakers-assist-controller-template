var enabled = self.makeBool(false);


/**
 * Checks if an identical specialMode is running, returns false if no control object with this special mode is found.
 */
function isRunning() {
	var objs: Array<CustomGameObject> = match.getCustomGameObjects();
	var foundExisting = false;
	Engine.forEach(objs, function (obj: CustomGameObject, _idx: Int) {
		if (obj.exports.specialModesSuddenDeath == true) {
			foundExisting = true;
			return false;
		} else {
			return true;
		}
	}, []);
	Engine.log(foundExisting);
	return foundExisting;


}

/**
 * Creates a "controller" object which helps other special modes know if this is being used, nothing will happen
 * nothing will happen if another special mode with the same controller is found(e.g 2 players have the same special mode)
 */
function createController() {
	if (!isRunning()) {
		Engine.log("creating controller");
		var player: Character = self.getOwner();
		var resource: String = player.getAssistContentStat("spriteContent") + "controller";
		var controller: CustomApiObject = match.createCustomGameObject(resource, player);
		controller.exports.specialModesSuddenDeath = true;
	}
}


function createIndicator() {
	var player: Character = self.getOwner();
	var container: Container = player.getDamageCounterContainer();
	var resource: String = player.getAssistContentStat("spriteContent") + "critical";
	var sprite = Sprite.create(resource);
	sprite.scaleY = 0.6;
	sprite.scaleX = 0.6;
	sprite.y = sprite.y + 12;
	sprite.x = sprite.x + (8 * 13);
	container.addChild(sprite);
}


/** 
 * Checks if any item in the array is either equal to or is a subtring of the target
 * @param {String[]} arr - array of strings
 * @param {String} target - target string
 */
function containsString(arr: Array<String>, item: String) {
	for (i in arr) {
		if (i == item) {
			return true;
		}
	}
	return false;
}


function to300(event: GameObjectEvent) {
	event.data.self.setDamage(300);
}


function enableSuddenDeath() {
	var players = match.getPlayers();
	if (!isRunning()) {
		Engine.forEach(players, function (player: Character, _idx: Int) {
			player.setDamage(300);
			player.addEventListener(CharacterEvent.RESPAWN, to300, { persistent: true });
			return true;
		}, []);
	}
	createController();
}

// Runs on object init
function initialize() {
}

function update() {
	var player: Character = self.getOwner();
	// set owners assist charge to 0 as we won't be calling an assist
	player.setAssistCharge(0);
	
	/* 
	Actual Initialization occurs here, given that assist controllers spawn 
	before any players are actually in the match, we wait until there are 
	players in the match before running our initialization code. 
	*/
	if (match.getPlayers().length > 1 && !enabled.get()) {
		var port = player.getPlayerConfig().port;
		Engine.log("Player " + port);
		enabled.set(true);
		/*
		Here, we artificially delay the activation of the special mode depending on the port number.
		This prevents cases where multiple players check for the existence of other controllers on the
		same frame, all of which would return false as all of the players check at the same time, giving 
		us enough space to check for duplicates.
		 */
		player.addTimer((1 + port) * 5, 1, function () {
			enableSuddenDeath();
		}, { persistent: true });
	}
}
// function onTeardown() {
// }
