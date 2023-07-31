// This is an Unreal Script
class XComGameState_SquadStats extends XComGameState_BaseObject;

struct SoldierDetails {
	var string FullName; // Mission Name
	var int SoldierID;
	var int SoldierRank;
	var string SoldierRankImage; // small picture
	var string SoldierFlag; // big picture
	var bool bIsAlive; // mission success?
};

struct ChosenInformation {
	var string ChosenType;
	var string ChosenName;
	var float NumEncounters;
	var float NumDefeats; // how many times this squad has defeated this chosen.
};

struct SquadDetails {
	var array<SoldierDetails> CurrentMembers;
	var array<SoldierDetails> PastMembers;
	var array<SoldierDetails> DeceasedMembers; // can keep as an array of strings because once they're dead, there is no coming back.
	var array<String> PastSquadNames;
	var array<String> MissionNamesWins;
	var array<String> MissionNamesLosses;
	var array<ChosenInformation> ChosenEncounters;
	var string WinRateAgainstWarlock;
	var string WinRateAgainstHunter;
	var string WinRateAgainstAssassin;
	var bool DefeatedAssassin;
	var bool DefeatedWarlock;
	var bool DefeatedHunter;
	var float NumMissions;
	var float Wins;
	var string MissionClearanceRate;
	var string SquadInceptionDate;
	var string SquadIcon;
	var string SquadName;
	var string AverageRank; // Average Rank of the Squad
	var string CurrentSquadLeader; // First soldier Added to the Squad. Can change over time
	var TDateTime RawInception;
	var bool bIsActive; // If the user deletes a squad, set status to decomissioned. If they remake the squad, we can reaccess the old data. Update ObjectID
	var int SquadID; // The ID of the Squad from the dependency
	var int ID; // our generated ID
	var int NumSoldiers; // Number of Soldiers in the Squad
};


var array<SquadDetails> SquadData;

var array<ChosenInformation> TheChosen;

var localized string squadLabel;
var localized string UnitFlagImage;

var bool XCOMSquadLinked;

var string SelectedSquad;
var string SelectedList;

function UpdateSquadData() {
	local XComGameState_LWSquadManager SquadMgr;
	local XComGameState_LWPersistentSquad Squad;
	local SquadDetails EntryData;
	local XComGameState_BattleData BattleData;
	local array<XComGameState_Unit> Units;
	local XComGameState_Unit Unit;
	local StateObjectReference UnitRef;
	local int Index, Exists;
	local XComGameState_AdventChosen ChosenState;
	local ChosenInformation MiniBoss;
	local SoldierDetails Soldier;
	local bool Passed, EveryoneDied;
	local string ChosenName;

	// Prevent an entry being created for a squad being eliminated on their first outing
	EveryoneDied = true;
	foreach `XCOMHQ.Squad(UnitRef) {
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
		if (Unit.IsAlive()) {
			EveryoneDied = false;
			break;
		}
	}
	SquadMgr = XComGameState_LWSquadManager(`XCOMHISTORY.GetSingleGameStateObjectForClass(class 'XComGameState_LWSquadManager', true));
	Squad = XComGameState_LWPersistentSquad(`XCOMHISTORY.GetGameStateForObjectID(SquadMgr.LastMissionSquad.ObjectID));
	`LOG("Total Amount of people in the squad"@Squad.SquadSoldiers.Length);
	for (Index = 0; Index < Squad.SquadSoldiers.Length; Index++) {
		`LOG("ObjectID of squad member is"@Squad.SquadSoldiers[Index].ObjectID);
	}
	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class 'XComGameState_BattleData'));
	// Check if the Squad already exists in our Data.
	// Actually for this to function without issue we can't allow re-linking. So if a user deletes a squad. thats it. Squad is perma decommisioned.
	Index = SquadData.Find('SquadID', SquadMgr.LastMissionSquad.ObjectID);
	if (BattleData.m_strOpName == "Operation Gatecrasher") { // Special Case for Gatecrasher. Can't use Squad or SquadMgr
		EntryData = SetGateCrasherData(EntryData, BattleData);
		SquadData.AddItem(EntryData);
	}
	else if (Index == INDEX_NONE) { // The first time in our records that this squad went out on a mission
		if (Squad.sSquadName == squadLabel && !XCOMSquadLinked) { // Gatecrasher squad has been reactivated
			XCOMSquadLinked = true;
			Exists = SquadData.Find('SquadName', Squad.sSquadname);
			SquadData[Exists].SquadIcon = Squad.SquadImagePath != "" ? Squad.SquadImagePath : Squad.DefaultSquadImagePath; // could change the icon, stay up to date
			SquadData[Exists].NumMissions += 1.0;
			SquadData[Exists].CurrentSquadLeader = AssignSquadLeader(Squad, SquadData[Exists]);
			UpdateDeceasedSquadMembers();
			SquadData[Exists].PastMembers = UpdateRosterHistory(Squad, SquadData[Exists].CurrentMembers, SquadData[Exists].PastMembers);
			SquadData[Exists].CurrentMembers.Length = 0;
			SquadData[Exists].CurrentMembers = UpdateCurrentMembers(Squad);
			Units = Squad.GetSoldiers();
			SquadData[Exists].NumSoldiers = Units.Length;
			SquadData[Exists].bIsActive = true;
			SquadData[Exists].SquadID = SquadMgr.LastMissionSquad.ObjectID;
			// Chosen Data stuff
			if(BattleData.ChosenRef.ObjectID != 0) {
				UpdateChosenInformation(BattleData, Exists);
			}
			UpdateClearanceRates(BattleData, Exists);
		} else { // not the gatecrasher team.

			// This if statement handles the case where the entire squad dies on the first mission.
			// If it's their first mission and they all die, don't put them in the books.
			if (!EveryoneDied) {
				EntryData.SquadID = SquadMgr.LastMissionSquad.ObjectID;
				EntryData.RawInception = BattleData.LocalTime;
				EntryData.SquadInceptionDate = class'X2StrategyGameRulesetDataStructures'.static.GetDateString(BattleData.LocalTime, true); // Set as the first mission they complete
				EntryData.SquadIcon = Squad.SquadImagePath != "" ? Squad.SquadImagePath : Squad.DefaultSquadImagePath;
				EntryData.SquadName = Squad.sSquadName;
				EntryData.NumMissions += 1.0;
				// handle case where first soldier is dead
				EntryData.CurrentMembers = UpdateCurrentMembers(Squad);
				EntryData.CurrentSquadLeader = AssignSquadLeader(Squad, EntryData);
				UpdateDeceasedSquadMembers();
				Units = Squad.GetSoldiers();
				EntryData.NumSoldiers = Units.Length;
				EntryData.AverageRank = CalculateAverageRank(Squad);
				EntryData.bIsActive = true;
				EntryData.ID = SquadData.Length + 1;
				// Chosen Data stuff
				if(BattleData.ChosenRef.ObjectID != 0) {
					ChosenState = XComGameState_AdventChosen(`XCOMHISTORY.GetGameStateForObjectID(BattleData.ChosenRef.ObjectID));
					ChosenName = ChosenState.FirstName $ " " $ ChosenState.NickName $ " " $ ChosenState.LastName;
					MiniBoss.ChosenType = GetChosenType(ChosenState);
					MiniBoss.ChosenName = ChosenName;
					MiniBoss.NumEncounters = 1.0;
					if (BattleData.bChosenLost) {
						MiniBoss.NumDefeats += 1.0;
						if (MiniBoss.ChosenType == "Warlock") {
							EntryData.WinRateAgainstWarlock = "100%";
						} else if (MiniBoss.ChosenType == "Hunter") {
							EntryData.WinRateAgainstHunter = "100%";
						} else {
							EntryData.WinRateAgainstAssassin = "100%";
						}
					} else {
						if (MiniBoss.ChosenType == "Warlock") {
							EntryData.WinRateAgainstWarlock = "0%";
						} else if (MiniBoss.ChosenType == "Hunter") {
							EntryData.WinRateAgainstHunter = "0%";
						} else {
							EntryData.WinRateAgainstAssassin = "0%";
						}
					}
					EntryData.ChosenEncounters.AddItem(MiniBoss);
				}
				// done with the chosen stuff
				if (BattleData.bLocalPlayerWon && !BattleData.bMissionAborted) {
					EntryData.Wins += 1.0;
					EntryData.MissionNamesWins.AddItem(BattleData.m_strOpName);
					EntryData.MissionClearanceRate = "100%";
				} else {
					EntryData.MissionNamesLosses.AddItem(BattleData.m_strOpName);
					EntryData.MissionClearanceRate = "0%";
				}
				SquadData.AddItem(EntryData); // should only do this on cases where the entry wasn't in the db
			} 
		}
	} else { // The squad returning from the mission exists in the db
		Exists = SquadData[Index].PastSquadNames.Find(Squad.sSquadName);
		if (Exists == INDEX_NONE) { // This name has not been used in the past by this squad
			if (SquadData[Index].SquadName != Squad.sSquadName) { // The name has been changed
				SquadData[Index].PastSquadNames.AddItem(SquadData[Index].SquadName);
				SquadData[Index].SquadName = Squad.sSquadName;
			}
		}
		SquadData[Index].SquadIcon = Squad.SquadImagePath != "" ? Squad.SquadImagePath : Squad.DefaultSquadImagePath; // could change the icon, stay up to date
		SquadData[Index].NumMissions += 1.0;
		SquadData[Index].CurrentSquadLeader = AssignSquadLeader(Squad, SquadData[Index]);
		UpdateDeceasedSquadMembers();
		SquadData[Index].PastMembers = UpdateRosterHistory(Squad, SquadData[Index].CurrentMembers, SquadData[Index].PastMembers);
		SquadData[Index].CurrentMembers.Length = 0;
		SquadData[Index].CurrentMembers = UpdateCurrentMembers(Squad);
		Units = Squad.GetSoldiers();
		SquadData[Index].NumSoldiers = Units.Length;
		// Chosen Data stuff
		if(BattleData.ChosenRef.ObjectID != 0) {
			UpdateChosenInformation(BattleData, Index);
		}
		UpdateClearanceRates(BattleData, Index);
	}
	SetStatus(SquadMgr, SquadData);

}

function UpdateChosenInformation(XComGameState_BattleData BattleData, int Index) {
	local string ChosenName;
	local int Exists;
	local ChosenInformation MiniBoss;
	local XComGameState_AdventChosen ChosenState;
	ChosenState = XComGameState_AdventChosen(`XCOMHISTORY.GetGameStateForObjectID(BattleData.ChosenRef.ObjectID));
	ChosenName = ChosenState.FirstName $ " " $ ChosenState.NickName $ " " $ ChosenState.LastName;
	Exists = SquadData[Index].ChosenEncounters.Find('ChosenName', ChosenName);
	// The Squad has not encountered this chosen yet
	if (Exists == INDEX_NONE) {
		MiniBoss.ChosenType = GetChosenType(ChosenState);
		MiniBoss.ChosenName = ChosenName;
		MiniBoss.NumEncounters = 1.0;
		if (BattleData.bChosenLost) {
			MiniBoss.NumDefeats += 1.0;
		}
		if (BattleData.bChosenDefeated) {
			if (MiniBoss.ChosenType == "Warlock") {
				SquadData[Index].DefeatedWarlock = true;
			} else if (MiniBoss.ChosenType == "Hunter") {
				SquadData[Index].DefeatedHunter = true;
			} else {
				SquadData[Index].DefeatedAssassin = true;
			}
		}
		SquadData[Index].ChosenEncounters.AddItem(MiniBoss);
	} else {
		// do chosen information processing here
		SquadData[Index].ChosenEncounters[Exists].NumEncounters += 1.0;
		if (BattleData.bChosenLost) {
			SquadData[Index].ChosenEncounters[Exists].NumDefeats += 1.0;
		}
		if (BattleData.bChosenDefeated) {
			if (SquadData[Index].ChosenEncounters[Exists].ChosenType == "Warlock") {
				SquadData[Index].DefeatedWarlock = true;
			} else if (SquadData[Index].ChosenEncounters[Exists].ChosenType == "Hunter") {
				SquadData[Index].DefeatedHunter = true;
			} else {
				SquadData[Index].DefeatedAssassin = true;
			}
		}
	}
}

function UpdateClearanceRates(XComGameState_BattleData BattleData, int Index) {
	local XComGameState_AdventChosen ChosenState;
	local int Chosen;
	local string ChosenType;
	if (BattleData.bLocalPlayerWon && !BattleData.bMissionAborted) {
		SquadData[Index].Wins += 1.0;
		SquadData[Index].MissionNamesWins.AddItem(BattleData.m_strOpName);
		SquadData[Index].MissionClearanceRate = (SquadData[Index].Wins / SquadData[Index].NumMissions) * 100 $ "%";
	} else {
		SquadData[Index].MissionNamesLosses.AddItem(BattleData.m_strOpName);
		SquadData[Index].MissionClearanceRate = (SquadData[Index].Wins / SquadData[Index].NumMissions) * 100 $ "%";
	}
	if (BattleData.ChosenRef.ObjectID != 0) { // I should be able to put all the stuff that relies on this check in one function, but I don't want to take that time.
		ChosenState = XComGameState_AdventChosen(`XCOMHISTORY.GetGameStateForObjectID(BattleData.ChosenRef.ObjectID));
		ChosenType = GetChosenType(ChosenState);
		Chosen = SquadData[Index].ChosenEncounters.Find('ChosenType', ChosenType);
		if (ChosenType == "Warlock") {
			SquadData[Index].WinRateAgainstWarlock = (SquadData[Index].ChosenEncounters[Chosen].NumDefeats / SquadData[Index].ChosenEncounters[Chosen].NumEncounters) * 100 $ "%";
		} else if (ChosenType == "Hunter") {
			SquadData[Index].WinRateAgainstHunter = (SquadData[Index].ChosenEncounters[Chosen].NumDefeats / SquadData[Index].ChosenEncounters[Chosen].NumEncounters) * 100 $ "%";
		} else {
			SquadData[Index].WinRateAgainstAssassin = (SquadData[Index].ChosenEncounters[Chosen].NumDefeats / SquadData[Index].ChosenEncounters[Chosen].NumEncounters) * 100 $ "%";
		}
		
	}
}

// have this return the object
function SquadDetails SetGateCrasherData(SquadDetails TeamData, XComGameState_BattleData BattleData) {
	local StateObjectReference UnitRef;
	local XComGameState_Unit Unit;
	local SoldierDetails SoldierData;
	local bool SquadLeaderSet;

	foreach `XCOMHQ.Squad(UnitRef) {
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
		SoldierData.FullName = Unit.GetFullName();
		SoldierData.SoldierRank = Unit.GetRank();
		SoldierData.SoldierRankImage = GetRankImage(SoldierData.SoldierRank);
		SoldierData.SoldierID = UnitRef.ObjectID;
		SoldierData.SoldierFlag = Unit.GetCountryTemplate().FlagImage;
		if (Unit.IsAlive()) {
			SoldierData.bIsAlive = true;
			if (!SquadLeaderSet) {
				TeamData.CurrentSquadLeader = SoldierData.FullName;
				SquadLeaderSet = true;
			}
			TeamData.CurrentMembers.AddItem(SoldierData);
		} else {
			SoldierData.bIsAlive = false;
			TeamData.DeceasedMembers.AddItem(SoldierData);
		}
	}
	TeamData.NumMissions = 1.0;
	TeamData.MissionNamesWins.AddItem(BattleData.m_strOpName);
	TeamData.NumSoldiers = TeamData.CurrentMembers.Length;
	TeamData.SquadName = squadLabel;
	TeamData.RawInception = BattleData.LocalTime;
	TeamData.SquadInceptionDate = class'X2StrategyGameRulesetDataStructures'.static.GetDateString(BattleData.LocalTime, true);
	TeamData.SquadIcon = "img:///UILibrary_XPACK_StrategyImages.challenge_Xcom";
	TeamData.Wins = 1.0;
	TeamData.MissionClearanceRate = "100%";
	TeamData.AverageRank = "img:///UILibrary_Common.rank_squaddie";
	TeamData.bIsActive = false; // becomes true when they create a squad with the same name
	return TeamData;
	// forgo setting SquadID since we'll link it later.
}

/*
	It is possible for the user to do the following.
		1. Create two or more squads with the same name
		2. Delete one
		3. reuse the name.
	We need to be able to calculate which squad was deleted to properly update them in the db
	Therefore, this function's job will be to go through our entries and find the squad that
	is missing by getting the array of refs from the squad manager

	This is an edge case which should never really trigger. Also
	there isn't a consistent way to make sure that we get the correct squad because
	if a user creates more than two squads with the same name and deletes multiple, we can't
	guarantee an accuracte re-link.
	Will warn in the comments for now.


	function FindMissingSquad() {

	}

*/

function SetStatus(XComGameState_LWSquadManager TeamMgr, array<SquadDetails> TeamData) {
	local int Index, Exists;
	for(Index = 0; Index < TeamData.Length; Index++) {
		Exists = TeamMgr.Squads.Find('ObjectID', TeamData[Index].SquadID);
		// the squad does not exist in the squad manager anymore. They are out of commission.
		if (Exists == INDEX_NONE) {
			TeamData[Index].bIsActive = false;
		}
	}
}

function string AssignSquadLeader(XComGameState_LWPersistentSquad Team, SquadDetails TeamData) {
	local array<XComGameState_Unit> Units;
	local XComGameState_Unit Unit;
	local int Index;
	local string Leader;


	Units = Team.GetSoldiers();
	for (Index = 0; Index < Units.Length; Index++) {
		Unit = Team.GetSoldier(Index);
		if (Unit.IsAlive()) {
			Leader = Unit.GetFullName();
			return Leader;
		}
	}
	Leader = "No Squad Leader Currently Assigned";
	return Leader;
}


function string GetChosenType(XComGameState_AdventChosen ChosenState) {
	local string ChosenType;
	ChosenType = string(ChosenState.GetMyTemplateName());
	ChosenType = Split(ChosenType, "_", true);
	return ChosenType;
}



// when a soldier dies, they are removed from the squad manager data. Therefore, we must use our internal current members array.
function UpdateDeceasedSquadMembers() {
	local XcomGameState_Unit Unit;
	local StateObjectReference UnitRef;
	local int Index, Found;
	local SoldierDetails Detail;
	// need to handle case where the deceased solider was borrowed from another squad
	foreach `XCOMHQ.Squad(UnitRef)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
		if (!Unit.IsAlive()) {
			Detail = GetSoldierDetails(Unit);
			// find the squad this soldier belongs to and add them to the deceased array
			// dead soliders are immediately taken out of the squad, therefore can't rely on Squad manager functions.
			for (Index = 0; Index < SquadData.Length; Index++) {
				// Iterate through the current members we have on record.
				`log("what is the objectID"@UnitRef.ObjectID);
				Found = SquadData[Index].CurrentMembers.Find('SoldierID', UnitRef.ObjectID);
				// It is possible that this soldier does not belong to any squad. In which case they don't go in any squad pages.
				`log("If the number isn't negative, they belong to a squad on record"@Found);
				`log("the squad they belong to is"@SquadData[Index].SquadName);
				if (Found != INDEX_NONE) {
					SquadData[Index].DeceasedMembers.AddItem(Detail);
					SquadData[Index].NumSoldiers -= 1;
				}
			}
		}
	 }
}

// for updating var array<SoldierDetails> PastMembers;
/*
 * This function checks the current members assigned to the squad, and see if it matches what's in the data
 * If not, it updates the array accordingly and returns an array of past members.
*/
function array<SoldierDetails> UpdateRosterHistory(XComGameState_LWPersistentSquad Team, array<SoldierDetails> CurrentMembers, array<SoldierDetails> PastMembers) {
	local XComGameState_Unit Unit;
	local array<StateObjectReference> Units;
	local StateObjectReference UnitRef;
	local string FullName;
	local int Index, Exists, Former;

	Units = Team.GetSoldierRefs(); // This is different from the Units that were deployed.
	/*  Squad.GetSoldierRefs() gets the refs to the soldiers assigned to the squad. Past soldiers would no longer be in this list. But we should have a record in CurrentMembers
		If CurrentMembers doesn't contain any of these troops, then the missing ones are past members.
	*/
	for (Index = 0; Index < CurrentMembers.Length; Index++) {
		Exists = Units.Find('ObjectID', CurrentMembers[Index].SoldierID);
		if (Exists == INDEX_NONE) {
			// The soldier is not in the current squad. Therefore, they are now a past member.
			// Now check if they have been a past member before
			Former = PastMembers.Find('SoldierID', CurrentMembers[Index].SoldierID);
			// Using the soldierId, get the Unit and check if they're alive. 
			Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(CurrentMembers[Index].SoldierID));
			if (Former == INDEX_NONE && Unit.IsAlive()) {
				PastMembers.AddItem(CurrentMembers[Index]);
			}
		}
	}
	return PastMembers;

}

// resets the array and populates with Squad.GetSoldiers();
// must run after update roster history
function array<SoldierDetails> UpdateCurrentMembers(XComGameState_LWPersistentSquad Team) {
	local SoldierDetails Data;
	local array <XComGameState_Unit> Units;
	local array<SoldierDetails> UpdatedList;
	local int Index;
	local string FullName;

	Units = Team.GetSoldiers();

	for (Index = 0; Index < Units.Length; Index++) {
	// I feel like there is a bug on this line.
		`log("What is this value"@Units[Index].ObjectID);
		Data.SoldierID = Units[Index].ObjectID;
		FullName = Units[Index].GetFullName();
		Data.FullName = FullName;
		UpdatedList.AddItem(Data);
	}

	return UpdatedList;

}

// instead of returning the name of the rank, return the image.
// also figure out how to add brigadier image
function string CalculateAverageRank(XComGameState_LWPersistentSquad Team) {
	local array<XComGameState_Unit> Units;
	local int i, Rank, Result;
	local float AverageRank;
	local array<int> Ranks;
	local string RankResult;
	Units = Team.GetSoldiers();
	// put all the soldier ranks in an array
	for (i = 0; i < Units.Length; i++) {
		Rank = Units[i].GetRank();
		Ranks.AddItem(Rank);
	}
	// now calculate the average
	for (i = 0; i < Ranks.Length; i++) {
		Rank += Ranks[i];
	}
	AverageRank = float(Rank) / float(Units.Length);
	Result = Round(AverageRank);
	RankResult = GetRankImage(Result);
	return RankResult;

}

// assests in the content browser are borked. names look wrong but logos are right.
function string GetRankImage(int Result) {
	if (Result == 0) {
		return "img:///UILibrary_Common.rank_rookie";
	} else if (Result == 1) {
		return "img:///UILibrary_Common.rank_squaddie";
	} else if (Result == 2) {
		return "img:///UILibrary_Common.rank_lieutenant";
	} else if (Result == 3) {
		return "img:///UILibrary_Common.rank_sergeant";
	} else if (Result == 4) {
		return "img:///UILibrary_Common.rank_captain";
	} else if (Result == 5) {
		return "img:///UILibrary_Common.rank_major";
	} else if (Result == 6) {
		return "img:///UILibrary_Common.rank_colonel";
	} else if (Result == 7) {
		return "img:///UILibrary_Common.rank_commander";
	} else { // LWOTC Support
		return "img:///UILibrary_Common.rank_fieldmarshall";
	}
}

// run this before every mission so if someone dies we can properly 
// attribute them to the correct squad
function UpdateAllCurrentSquadMembers() {
	local XComGameState_LWSquadManager Manager;
	local StateObjectReference Ref;
	local XComGameState_LWPersistentSquad Team;
	local SoldierDetails Data;
	local array <XComGameState_Unit> Units;
	local int Index, i;
	Manager = XComGameState_LWSquadManager(`XCOMHISTORY.GetSingleGameStateObjectForClass(class 'XComGameState_LWSquadManager', true));
	foreach Manager.Squads(Ref) {
		Team = XComGameState_LWPersistentSquad(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
		Index = SquadData.Find('SquadID', Team.ObjectID);
		if (Index != INDEX_NONE) { // We have the squad on record
			SquadData[Index].CurrentMembers.Length = 0;
			Units = Team.GetSoldiers();
			for (i = 0; i < Units.Length; i++) {
				Data = GetSoldierDetails(Units[i]);
				SquadData[Index].CurrentMembers.AddItem(Data);
			}
		}
	}
}

function SoldierDetails GetSoldierDetails(XComGameState_Unit Unit) {
	local SoldierDetails Detail;
	Detail.SoldierID = Unit.ObjectID;
	Detail.FullName = Unit.GetFullName();
	Detail.SoldierRank = Unit.GetRank();
	Detail.SoldierRankImage = GetRankImage(Detail.SoldierRank);
	Detail.bIsAlive = Unit.IsAlive();
	Detail.SoldierFlag = Unit.GetCountryTemplate().FlagImage;
	if (Detail.SoldierFlag == "") {
		Detail.SoldierFlag = UnitFlagImage;
	}
	return Detail;
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