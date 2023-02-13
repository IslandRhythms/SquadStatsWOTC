// This is an Unreal Script
class XComGameState_SquadStats extends XComGameState_BaseObject;


struct SoldierDetails {
	var string FullName;
	var int SoldierID;
};

struct ChosenInformation {
	var string ChosenType;
	var string ChosenName;
	var float NumEncounters;
	var float NumDefeats;
};

struct SquadDetails {
	var array<SoldierDetails> CurrentMembers;
	var array<SoldierDetails> PastMembers;
	var array<String> DeceasedMembers; // can keep as an array of strings cause once they're dead, there is no coming back.
	var array<String> PastSquadNames;
	var array<String> MissionNamesWins;
	var array<String> MissionNamesLosses;
	var array<ChosenInformation> ChosenEncounters;
	var float WinRateAgainstWarlock;
	var float WinRateAgainstHunter;
	var float WinRateAgainstAssassin;
	var float NumMissions;
	var float Wins;
	var string MissionClearanceRate;
	var string SquadInceptionDate;
	var string SquadIcon;
	var string SquadName;
	var string CurrentSquadLeader; // First soldier Added to the Squad. Can change over time
	var TDateTime RawInception;
	var bool bIsActive; // If the user deletes a squad, set status to decomissioned. If they remake the squad, we can reaccess the old data. Update ObjectID
	var int SquadID;
};


var array<SquadDetails> SquadData;

var array<ChosenInformation> TheChosen;

function UpdateSquadData() {
	local XComGameState_LWSquadManager SquadMgr;
	local XComGameState_LWPersistentSquad Squad;
	local SquadDetails EntryData;
	local XComGameState_BattleData BattleData;
	local XComGameState_Unit Unit;
	local int Index, Exists;
	local XComGameState_AdventChosen ChosenState;
	local ChosenInformation MiniBoss;

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
			EntryData.NumMissions = 1.0;
			UpdateClearanceRate(BattleData, EntryData)
			Unit = Squad.GetSoldier(0);
			EntryData.CurrentSquadLeader = Unit.GetFullName();
			EntryData.bIsActive = true;
			// Chosen Data stuff
			if(BattleData.ChosenRef.ObjectID != 0) {
				ChosenState = XComGameState_AdventChosen(`XCOMHISTORY.GetGameStateForObjectID(BattleData.ChosenRef.ObjectID));
				UpdateChosenInformation(ChosenState, BattleData, EntryData);
			}
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
		UpdateRosterHistory(Squad, SquadData[Index].CurrentMembers, SquadData[Index].PastMembers);
		SquadData[Index].CurrentMembers.Length = 0;
		SquadData[Index].CurrentMembers = UpdateCurrentMembers(Squad);
		UpdateClearanceRate(BattleData, SquadData[Index]);
		// Chosen Data stuff
		if(BattleData.ChosenRef.ObjectID != 0) {
			ChosenState = XComGameState_AdventChosen(`XCOMHISTORY.GetGameStateForObjectID(BattleData.ChosenRef.ObjectID));
			UpdateChosenInformation(ChosenState, BattleData, SquadData[Index]);
		}
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

// TODO: Maybe move the win loss calculation to UpdateClearanceRates since it has to calculate the overall win loss
function UpdateChosenInformation(XComGameState_AdventChosen ChosenState, XComGameState_BattleData BattleData, SquadDetails SquadData) {
	local string ChosenName;
	local int Exists;
	local ChosenInformation MiniBoss;
	ChosenName = ChosenState.FirstName $ " " ChosenState.NickName $ " " $ ChosenState.LastName;
	Exists = SquadData.ChosenEncounters.Find('ChosenName', ChosenName);
	// The Squad has not encountered this chosen yet
	if (Exists == INDEX_NONE) {
		MiniBoss.ChosenType = string(ChosenState.GetMyTemplateName());
		MiniBoss.ChosenType = Split(MiniBoss.ChosenType, "_", true);
		MiniBoss.ChosenName = ChosenName;
		MiniBoss.NumEncounters = 1.0;
		if (BattleData.bChosenLost) {
			MiniBoss.NumDefeats += 1.0;
		}
		SquadData.ChosenEncounters.AddItem(MiniBoss);
	} else {
		// do chosen information processing here
		SquadData.ChosenEncounters[Exists].NumEncounters += 1.0;
		if (BattleData.bChosenLost) {
			SquadData.ChosenEncounters[Exists].NumDefeats += 1.0;
		}
		// do the rest here. Or maybe do all of it in the function.
	}
}

function UpdateClearanceRates(XComGameState_BattleData BattleData, SquadDetails SquadData) {
	if (BattleData.bLocalPlayerWon && !BattleData.bMissionAborted) {
		SquadData.Wins += 1.0;
		SquadData.MissionNamesWins.AddItem(BattleData.m_strOpName);
		SquadData.MissionClearanceRate = (SquadData.Wins/ SquadData.NumMissions) * 100 $ "%";
	} else {
		SquadData.MissionNamesLosses.AddItem(BattleData.m_strOpName);
		SquadData.MissionClearanceRate = (SquadData.Wins/ SquadData.NumMissions) * 100 $ "%";
	}
}
// maybe just do what this is suppose to do in UpdateChosenInformation
function UpdateClearanceRateAgainstChosen(string Chosen, XComGameState_BattleData BattleData, SquadDetails SquadData) {

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
	// need to handle case where the deceased solider was borrowed from another squad
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
function UpdateRosterHistory(XComGameState_LWPersistentSquad Squad, array<SoldierDetails> CurrentMembers, array<SoldierDetails> PastMembers) {
	local XComGameState_Unit Unit;
	local array<StateObjectReference> Units;
	local StateObjectReference UnitRef;
	local string FullName;
	local int Index, Exists, Former;

	Units = Squad.GetSoldierRefs(); // This is different from the Units that were deployed.
	/*  Squad.GetSoldierRefs() gets the refs to the soldiers assigned to the squad. Past soldiers would no longer be in this list. But we should have a record in CurrentMembers
		If CurrentMembers doesn't contain any of these troops, then the missing ones are past members.
	*/
	for (Index = 0; Index < CurrentMembers.Length; Index++) {
		Exists = Units.Find('ObjectID', CurrentMembers[Index].SoldierID);
		if (Exists == INDEX_NONE) {
			// The soldier is not in the current squad. Therefore, they are now a past member.
			// Now check if they have been a past member before
			Former = PastMembers.Find('SoldierID', CurrentMembers[Index].SoldierID);
			if (Former == INDEX_NONE) {
				PastMembers.AddItem(CurrentMembers[Index]);
			}
		}
	}

}

// resets the array and populates with Squad.GetSoldiers();
// must run after update roster history
function array<SoldierDetails> UpdateCurrentMembers(XComGameState_LWPersistentSquad Squad) {
	local SoldierDetails Data;
	local array <XComGameState_Unit> Units;
	local array<SoldierDetails> UpdatedList;
	local int Index;
	local string FullName;

	Units = Squad.GetSoldiers();

	for (Index = 0; Index < Units.Length; Index++) {
	// I feel like there is a bug on this line.
		`log(Units[Index].ObjectID);
		Data.SoldierID = Units[Index].ObjectID;
		FullName = Units[Index].GetFullName();
		Data.FullName = FullName;
		UpdatedList.AddItem(Data);
	}

	return UpdatedList;

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