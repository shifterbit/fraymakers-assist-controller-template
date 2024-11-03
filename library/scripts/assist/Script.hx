var enabled = self.makeBool(false);
var prefix = "specialModeType_";
var modeName = "suddenDeath"; // change this to the special mode name you want
var globalDummy: Projectile = null; // We can create a projectile and assign it to this temporarily in case we need timers and the owner is frozen from match.freeze.
var globalController: CustomGameObject = null; // This stores all our data


function modeId() {
	return prefix + modeName;
}

/**
 * Since AssistController's cannot use getResource().getContent(id), this exists as a workaround to bypass that limitation.
 */
function getContent(id: String) {
	var player: Character = self.getOwner();
	var resource = player.getAssistContentStat("spriteContent") + id;
	return resource;
}

/**
 * Checks if an identical specialMode is running, returns false if no control object with this special mode is found.
 */
function isRunning(mode: String) {
	var objs: Array<CustomGameObject> = match.getCustomGameObjects();
	var foundExisting = false;
	Engine.forEach(objs, function (obj: CustomGameObject, _idx: Int) {
		if (obj.exports.specialModeType == slug(mode)) {
			foundExisting = true;
			return false;
		} else {
			return true;
		}
	}, []);
	return foundExisting;
}


/**
 * Creates a "controller" object which helps other special modes know if this is being used, nothing will happen
 * nothing will happen if another special mode with the same controller is found(e.g 2 players have the same special mode)
 */
function createController(mode: String) {
	if (!isRunning(mode)) {
		var player: Character = self.getOwner();
		var resource: String = player.getAssistContentStat("spriteContent") + "controller";
		var controller: CustomGameObject = match.createCustomGameObject(resource, player);
		controller.exports.specialModeType = modeId();
		controller.exports.data = {}; // we can use this field to store and update whatever data we need for our mode 
		globalController = controller;
		/**
		 * Initializing Data:
		 * globalController.exports.data = {points: [0,0,0,0]};
		 * You probably wanna store all your data for each player in arrays of length 4
		 * 
		 * Updating:
		 * 
		 * Lets say you wanna add a points to a player
		 * First we get the port with
		 * var port = player.getPlayerConfig().port;
		 * Then we can just increment the field with:
		 * globalController.exports.data[port] += 1;
		 * 
		 * 
		 * Accessing
		 * 
		 * This is also pretty easy, just
		 * var port = player.getPlayerConfig().port;
		 * var points globalController.exports.data[port];
		 * 
		 * Make sure you have created the fields *BEFORE* you access it
		 * 
		 */
	}
}


/***
 * Generates the ui element on the damage container on the player
 */
function createIndicator() {
	var player: Character = self.getOwner();
	var container: Container = player.getDamageCounterContainer();
	var resource: String = player.getAssistContentStat("spriteContent") + "modeIndicator"; // probably wanna edit the sprite for this
	var sprite = Sprite.create(resource);
	// May wanna adjust these depending on your sprite size
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




function enableSpecialMode() {
	var players = match.getPlayers();
	Engine.forEach(players, function (player: Character, _idx: Int) {
		player.setDamage(300);
		player.addEventListener(CharacterEvent.RESPAWN,
			function (event: GameObjectEvent) {
				event.data.self.setDamage(300);
			}, { persistent: true });

		return true;
	}, []);

}

function enableMode() {
	var mode = modeId();
	if (!isRunning(mode)) {
		createIndicator();
		createController(mode);
		enableSpecialMode();
	}
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
		enabled.set(true);
		/*
		Here, we artificially delay the activation of the special mode depending on the port number.
		This prevents cases whEngineere multiple players check for the existence of other controllers on the
		same frame, all of which would return false as all of the players check at the same time, giving 
		us enough space to check for duplicates.
		 */
		player.addTimer((1 + port) * 5, 1, function () {
			enableMode();
		}, { persistent: true });
	}
}
function onTeardown() {
}
