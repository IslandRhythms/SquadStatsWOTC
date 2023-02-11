// This is an Unreal Script
class XComGameState_SquadStats extends XComGameState_BaseObject;


struct SoldierDetails {
	var string FullName;
	var int SoldierID;
};

struct SquadDetails {
	var array<SoldierDetails> CurrentMembers;
	var array<SoldierDetails> PastMembers;
	var array<String> DeceasedMembers; // can keep as an array of strings cause once they're dead, there is no coming back.
	var array<String> PastSquadNames;
	var array<String> MissionNames;
	var float MissionClearanceRate;
	var float WinRateAgainstWarlock;
	var float WinRateAgainstHunter;
	var float WinRateAgainstAssassin;
	var float NumMissions;
	var string SquadInceptionDate;
	var string SquadIcon;
	var string SquadName;
	var string CurrentSquadLeader; // First soldier Added to the Squad. Can change over time
	var TDateTime RawInception;
	var bool bIsActive; // If the user deletes a squad, set status to decomissioned. If they remake the squad, we can reaccess the old data. Update ObjectID
	var int SquadID;
};

struct ChosenInformation {
	var string ChosenType;
	var string ChosenName;
	var float NumEncounters;
	var float NumDefeats;
	var int CampaignIndex;
};


var array<SquadDetails> SquadData;

var array<ChosenInformation> TheChosen;

function UpdateSquadData() {
	local XComGameState_LWSquadManager SquadMgr;
	local XComGameState_LWPersistentSquad Squad;
	local SquadDetails EntryData;
	local XComGameState_BattleData BattleData;
	local XComGameState_Unit Unit;
	local int Index, Exists, Increase;

	SquadMgr = XComGameState_LWSquadManager(`XCOMHISTORY.GetSingleGameStateObjectForClass(class 'XComGameState_LWSquadManager', true));
	Squad = XComGameState_LWPersistentSquad(`XCOMHISTORY.GetGameStateForObjectID(SquadMgr.LastMissionSquad.ObjectID));
	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class 'XComGameState_BattleData'));
	// Check if the Squad already exists in our Data
	Index = SquadData.Find('SquadID', SquadMgr.LastMissionSquad.ObjectID);
	if (BattleData.m_strOpName == "Operation Gatecrasher") {
	// Need to get a default image to use for the squad icon since its only used once.
	/*
		EntryData.SquadIcon = ; // Cannot make this client facing
		EntryData.SquadName = "XCOM"; // make this client facing so they can create the squad later on and keep these details
		EntryData.RawInception = ;
		EntryData.SquadInceptionDate;
		EntryData.MissionNames.AddItem(BattleData.m_strOpName);
	*/
	} else if (Index == INDEX_NONE) { // Not gatecrasher but the first time this squad went out on a mission
		Exists = SquadData.Find('SquadName', Squad.sSquadName);
		if (Exists != INDEX_NONE) { // this squad was deleted but the player is reusing the name.
			// update the object id
			SquadData[Exists].SquadID = SquadMgr.LastMissionSquad.ObjectID;
		} else {
			EntryData.SquadID = SquadMgr.LastMissionSquad.ObjectID;
			EntryData.RawInception = BattleData.LocalTime;
			EntryData.SquadInceptionDate = class'X2StrategyGameRulesetDataStructures'.static.GetDateString(BattleData.LocalTime, true); // Set as the first mission they complete
			EntryData.SquadIcon = Squad.SquadImagePath != "" ? Squad.SquadImagePath : Squad.DefaultSquadImagePath;
			EntryData.SquadName = Squad.sSquadName != "" ? Squad.sSquadName : "XCOM";
			EntryData.MissionNames.AddItem(BattleData.m_strOpName);
			EntryData.NumMissions = 1.0;
			Unit = Squad.GetSoldier(0);
			EntryData.CurrentSquadLeader = Unit.GetFullName();
			EntryData.bIsActive = true;
			SquadData.AddItem(EntryData); // should only do this on cases where the entry wasn't in the db
		}
	} else { // The squad returning from the mission exists in the db
		SquadData[Index].SquadName = Squad.sSquadName; // could change the name, need to stay up to date
		SquadData[Index].SquadIcon = Squad.SquadImagePath != "" ? Squad.SquadImagePath : Squad.DefaultSquadImagePath; // could change the icon, stay up to date
		SquadData[Index].MissionNames.AddItem(BattleData.m_strOpName);
		SquadData[Index].NumMissions += 1.0;
		Unit = Squad.GetSoldier(0);
		SquadData[Index].CurrentSquadLeader = Unit.GetFullName();
		SquadData[Index].DeceasedMembers = UpdateDeceasedSquadMembers(SquadData[Index].DeceasedMembers);
		SquadData[Index].PastMembers = UpdateRosterHistory(Squad, SquadData[Index].CurrentMembers);

	}
	// TODO: iterate through all the squads to see if any have been deleted.

}
/*
 * Go through all the squads in the squad manager
 * and check if a squad in our array is missing.
 * If so, update the status of our squad to false.
 */
// maybe add a new property that stores the time the squad was reactivated? array?
function UpdateSquadStatus() {

}

function UpdateClearanceRate() {

}

function UpdateClearanceRateAgainstChosen(string Chosen) {

}


// for updating var array<String> DeceasedMembers;
function array<String> UpdateDeceasedSquadMembers(array<String> Dead) {
	local XcomGameState_Unit Unit;
	local StateObjectReference UnitRef;
	local int Index;
	local string FullName;
	local array<String> UpdatedList;
	for (Index = 0; Index < Dead.Length; Index++) {
		UpdatedList.AddItem(Dead[Index]);
	}
	foreach `XCOMHQ.Squad(UnitRef)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
		if (!Unit.IsAlive()) {
			FullName = Unit.GetFullName();
			UpdatedList.AddItem(FullName);
		}
	}
	return UpdatedList;
}

// for updating var array<SoldierDetails> PastMembers;
/*
 * This function checks the current members assigned to the squad, and see if it matches what's in the data
 * If not, it updates the array accordingly and returns an array of past members.
*/
function UpdateRosterHistory(XComGameState_LWPersistentSquad Squad, array<SoldierDetails> CurrentMembers) {
	local XComGameState_Unit Unit;
	local array<XComGameState_Unit> Units;
	local StateObjectReference UnitRef;
	local string FullName;
	local int Index, Exists;

	Units = Squad.GetSoldiers(); // This is different from the Units that were deployed.
	/*  Squad.GetSoldiers() gets the soldiers assigned to the squad. Past soldiers would no longer be in this list. But we should have a record in CurrentMembers
		If CurrentMembers doesn't contain any of these troops, then the missing ones are past members.
	*/
	foreach `XCOMHQ.Squad(UnitRef)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
		Exists = CurrentMembers.Find('SoldierID', UnitRef.ObjectID);
		if (Exists != INDEX_NONE) {

		}
		// FullName = Unit.GetFullName();
		// Index = CurrentMembers.Find(,FullName);
	}
}

// resets the array and populates with Squad.GetSoldiers();
function UpdateCurrentMembers() {

}



function bool IsModActive(name ModName)
{
    local XComOnlineEventMgr    EventManager;
    local int                   Index;

    EventManager = `ONLINEEVENTMGR;

    for (Index = EventManager.GetNumDLC() - 1; Index >= 0; Index--) 
    {
        if (EventManager.GetDLCNames(Index) == ModName) 
        {
            return true;
        }
    }
    return false;
}

DefaultProperties {
	bSingleton=true;
}