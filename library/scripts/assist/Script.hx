var enabled = self.makeBool(false);
var prefix = "";
var modeName = "suddenDeath"; // CHANGE THIS TO SOMETHING UNIQUE
var globalDummy: Projectile = null; // We can create a projectile and assign it to this temporarily in case we need timers and the owner is frozen from match.freeze.
var globalController: CustomGameObject = null; // This stores all our data

/**
 *  Set this to true if you want this assist to apply to all players, Absolutely do not change it after the fact. 
*/
var MULTIPLAYER = true;


function controllerId() {
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
function isRunning() {
	if (MULTIPLAYER) {
		var objs: Array<CustomGameObject> = match.getCustomGameObjects();
		var foundExisting = false;
		Engine.forEach(objs, function (obj: CustomGameObject, _idx: Int) {
			if (obj.exports.id == controllerId()) {
				foundExisting = true;
				return false;
			} else {
				return true;
			}
		}, []);
		return foundExisting;
	} else {
		return false;
	}
}


/**
 * Creates a "controller" object which helps other special modes know if this is being used, nothing will happen
 * nothing will happen if another special mode with the same controller is found(e.g 2 players have the same special mode)
 */
function createController() {
	if (!isRunning()) {
		var player: Character = self.getOwner();
		var resource: String = player.getAssistContentStat("spriteContent") + "controller";
		var controller: CustomGameObject = match.createCustomGameObject(resource, player);
		controller.exports.id = controllerId();
		controller.exports.data = {
			meters: [null, null, null, null]
		}; // we can use this field to store and update whatever data we need for our mode 
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
		 * Generally speaking you want to kinda duplicate the fields you want in an array of 4
		 * e.g if you want to store a number for each player you store the field as [0,0,0,0]
		 * if its a list [ [], [], [], []],
		 * Similar idea applies to strings, sprite objects, gameobjects, literally anything
		 * while its easier to just use a single variable directly, doing it this way makes adding multiplayer support
		 * a literal single line change
		 * 
		 */
	}
}

function berserkMode(player: Character) {
	var port: int = player.getPlayerConfig().port;
	var meter: Sprite = globalController.exports.data.meters[port];

	if (!player.isOnFloor()) {
		player.playAnimation("assist_call_air");
	} else {
		player.playAnimation("assist_call");
	}

	var outerGlow = new GlowFilter();
	outerGlow.color = 0xFF0000;
	var middleGlow = new GlowFilter();
	middleGlow.color = 0xF95D74;
	var innerGlow = new GlowFilter();
	innerGlow.color = 0xFFFFFF;
	player.addFilter(innerGlow);
	player.addFilter(middleGlow);
	player.addFilter(outerGlow);

	function boostDamage(event: GameObjectEvent) {
		var baseDamage = event.data.hitboxStats.damage;
		event.data.hitboxStats.damage = baseDamage * 2;
		meter.currentFrame = 0;
	};

	function removeMode() {
		player.removeEventListener(GameObjectEvent.HITBOX_CONNECTED, boostDamage);
		player.removeFilter(outerGlow);
		player.removeFilter(middleGlow);
		player.removeFilter(innerGlow);
	}
	player.addEventListener(GameObjectEvent.HITBOX_CONNECTED, boostDamage, { persistent: true });

	player.addTimer(1, 60 * 10, function () {
		meter.currentFrame = 0;
	}, { persistent: true });

	player.addTimer(60 * 10, 1, removeMode, { persistent: true });
}

function createMeter(player: Character) {
	var damageContainer = player.getDamageCounterContainer();
	var res = getContent("meter");
	var sprite = Sprite.create(res);
	sprite.scaleX = 0.3;
	sprite.scaleY = 0.25;
	sprite.x = 64 + 32 + 8 + 8;
	sprite.y = 36;
	sprite.currentFrame = 0;
	damageContainer.addChild(sprite);

	return sprite;
}


function activateMeter(player: Character) {
	var port: Int = player.getPlayerConfig().port;
	var meter: Sprite = globalController.exports.data.meters[port];

	player.addTimer(1, -1, function () {

		// Taunt refills meter in training mode
		if ((match.getMatchSettingsConfig().matchRules[0].contentId == "infinitelives")) {
			if (meter.currentFrame >= 100) {
				meter.currentFrame = 100;
			} else {
				meter.currentFrame += 1;
			}
		}
		if (player.getHeldControls().EMOTE && meter.currentFrame == 100) {
			meter.currentFrame = 0;
			berserkMode(player);
		}


	}, { persistent: true });

	player.addEventListener(GameObjectEvent.HIT_DEALT, function (event: GameObjectEvent) {
		var charge = meter.currentFrame;
		if (!event.data.foe.hasBodyStatus(BodyStatus.INVINCIBLE)) {
			var damage = Math.ceil(event.data.hitboxStats.damage);
			if (charge + damage >= 100) {
				meter.currentFrame = 100;
			} else {
				meter.currentFrame += damage;
			}
		}

	}, { persistent: true });
}

function activateModeForPlayer(player: Character) {
	var port: Int = player.getPlayerConfig().port;
	globalController.exports.data.meters[port] = createMeter(player);
	activateMeter(player);
}

function activateMode() {
	var players = match.getPlayers();
	if (MULTIPLAYER) {
		Engine.forEach(players, function (player: Character, _idx: Int) {
			activateModeForPlayer(player);
			return true;
		}, []);
	} else {
		activateModeForPlayer(self.getOwner());
	}
}

function activateController() {
	var mode = controllerId();
	if (!isRunning(mode)) {
		createController(mode);
		activateMode();
	}
}

// Runs on object init
function initialize() {
	prefix = getContent(""); // We set the prefix here to our content id, so it can be unique

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
			activateController();
		}, { persistent: true });
	}
}
function onTeardown() {
}
