// Assist stats for Template Assist

// Define some states for our state machine
STATE_IDLE = 0;
STATE_JUMP = 1;
STATE_FALL = 2;
STATE_SLAM = 3;
STATE_OUTRO = 4;

{
	spriteContent: self.getResource().getContent(""),
	initialState: STATE_IDLE,
	stateTransitionMapOverrides: [
		STATE_IDLE => {
			animation: "idle"
		}
	],
	gravity: 0,
	assistChargeValue: 1000
}
