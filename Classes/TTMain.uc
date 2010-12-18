class TTMain extends Mutator config;

//var int ItemsMask; // bit mask? maybe
var config int MaxDwellingTime;
var config float SafePickupDistance;
var config string ControlledItemA;
var config string ControlledItemB;
var config string ControlledItemC;
var config string ControlledItemD;
var config string ControlledItemE;

var bool bPickupDataRegistered;
var array<string> ControlledItem;

struct PickupInfo {
	var int Timer;
	var Pickup Item;
};

var array<PickupInfo> PickupData;

function PreBeginPlay() {
	local int i;
	Super.PreBeginPlay();
	DeathMatch(Level.Game).bForceRespawn = True;
	if (ControlledItemA != "") ControlledItem[i++] = ControlledItemA;
	if (ControlledItemB != "") ControlledItem[i++] = ControlledItemB;
	if (ControlledItemC != "") ControlledItem[i++] = ControlledItemC;
	if (ControlledItemD != "") ControlledItem[i++] = ControlledItemD;
	if (ControlledItemE != "") ControlledItem[i++] = ControlledItemE;
	for (i = 0; i < ControlledItem.Length; i++) {
		PickupData.Insert(i, 1);
		PickupData[i].Timer = 0;
		PickupData[i].Item = None;
	}
	StaticSaveConfig();
	SetTimer(1, True);
}

function RegisterPickupData() {
	local Pickup P;
	local int i;
//	Debug("RegisterPickupData:PickupData.Length:" @ PickupData.Length);
	foreach AllActors(class'Pickup', P) {
//		Debug("RegisterPickupData:" @ string(P.Class));
		for (i = 0; i < PickupData.Length; i++) {
			if (string(P.Class) ~= ControlledItem[i]) {
				PickupData[i].Item = P;
//				Debug("Item Reg: " @ string(P.Class));
			}
		}
	}
	bPickupDataRegistered = True;
}

function Timer() {
	local int i;
	local bool bNearPickup;
	local Pawn Pawn;
	if (!bPickupDataRegistered) RegisterPickupData();
	for (i = 0; i < PickupData.Length; i++) {
//		Debug(string(PickupData[i].Item) @ "ReadyToPickup-" @ PickupData[i].Item.ReadyToPickup(0));
		if (!PickupData[i].Item.ReadyToPickup(0)) {
			PickupData[i].Timer = 0;
			continue;
		}
		PickupData[i].Timer++;
		Pawn = Level.GetLocalPlayerController().Pawn;
		bNearPickup = False;
		if (Pawn != None) bNearPickup = VSize(Pawn.Location - PickupData[i].Item.Location) < SafePickupDistance;
		if (PickupData[i].Timer > MaxDwellingTime && !bNearPickup) { // man late to pick up item
			PickupData[i].Item.StartSleeping();
			SetDeathMessage("%o had an aneurysm." @ PickupData[i].Item.GetHumanReadableName() @ "is not taked in time!");
			if (Pawn != None) Pawn.Suicide();
		}
	}
}

function SetDeathMessage(string S) {
	class'Suicided'.default.DeathString = S;
	class'Suicided'.default.FemaleSuicide = S;
	class'Suicided'.default.MaleSuicide = S;
}

static function FillPlayInfo(PlayInfo PlayInfo) {
	local string List;
	Super.FillPlayInfo(PlayInfo);
	PlayInfo.AddSetting(default.RulesGroup, "MaxDwellingTime", "Dwelling Time", 0, 0, "Text", "2;0:25", , False, False);
	PlayInfo.AddSetting(default.RulesGroup, "SafePickupDistance", "Safe Pickup Distance", 0, 0, "Text", "3;0:999", , False, False);
	List = GetItemList();
	PlayInfo.AddSetting(default.RulesGroup, "ControlledItemA", "Controlled Item A", 0, 1, "Select", List, , False, False);
	PlayInfo.AddSetting(default.RulesGroup, "ControlledItemB", "Controlled Item B", 0, 1, "Select", List, , False, False);
	PlayInfo.AddSetting(default.RulesGroup, "ControlledItemC", "Controlled Item C", 0, 1, "Select", List, , False, False);
	PlayInfo.AddSetting(default.RulesGroup, "ControlledItemD", "Controlled Item D", 0, 1, "Select", List, , False, False);
	PlayInfo.AddSetting(default.RulesGroup, "ControlledItemE", "Controlled Item E", 0, 1, "Select", List, , False, False);
}

static function string GetItemList() {
	local string S, xP, xW;
	// SniperRiflePickup Lightning Gun
	// FlakCannonPickup RocketLauncherPickup
	xP = "XPickups.";
	xW = "XWeapons.";
	S = ";None;";
	S $= xP $ "SuperShieldPack;Super Shield Pack;";
	S $= xP $ "ShieldPack;Shield Pack;";
	S $= xW $ "ShockRiflePickup;Shock Rifle;";
	S $= xW $ "SniperRiflePickup;Lightning Gun;";
	S $= xW $ "FlakCannonPickup;Flak Cannon;";
	S $= xW $ "RocketLauncherPickup;Rocket Launcher";
	return S;
}

function Debug(coerce string S) {
	local string S1;
	local PlayerController PC;
	S1 = string(Level.TimeSeconds) @ "TT:" @ S;
	PC = Level.GetLocalPlayerController();
	Level.Game.BroadCast(PC, S1);
	Log(S1);
}

defaultproperties {
	SafePickupDistance=500.0
	MaxDwellingTime=5
	FriendlyName="Timing Training 0.2"
	Description="Attempt to training control under pickuped items. If you will not have time to take item which just has spawned, you are dead :)"
}
