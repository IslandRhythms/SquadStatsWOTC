// This is an Unreal Script
class XComGameState_SquadStats extends XComGameState_BaseObject;

struct SoldierDetails {
	var string FullName; // Mission Name
	var string SoldierNickName;
	var int SoldierID;
	var int SoldierRank;
	var string SoldierRankImage; // small picture
	var string SoldierFlag; // big picture
	var string Status; // mission success?
	var int Missions;
	var int Kills;
	var int DaysOnAvenger;
	var int DaysInjured;
	var int AttacksMade;
	var int DamageDealt;
	var int AttacksSurvived;
	var String MissionDied;
	var String KilledDate;
	var String CauseOfDeath;
	var String Epitaph;

	var string CountryName;
	var string RankName;
	var string ClassName;

	var name CountryTemplateName;

	var int CampaignIndex; // needed for the soldier pic
};

struct MissionImages {
	var string MissionThumbnail;
	var string MissionGraphic;
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
	var array<SoldierDetails> Missions;
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
var string SelectedList; // Past, Deceased, Current, Missions

function UpdateSquadData() {
	local XComGameState_LWSquadManager SquadMgr;
	local XComGameState_LWPersistentSquad Squad;
	local SquadDetails EntryData;
	local XComGameState_BattleData BattleData;
	local array<XComGameState_Unit> Units;
	local XComGameState_Unit Unit;
	local array<StateObjectReference> UnitRefs;
	local StateObjectReference UnitRef;
	local int Index, Exists, i;
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
	else if (Index == INDEX_NONE) { // The first time in our records that this squad went out on a mission.
		if (Squad.sSquadName == squadLabel && !XCOMSquadLinked) { // Gatecrasher squad has been reactivated. Only exception to the above statement.
			Exists = SquadData.Find('SquadName', Squad.sSquadname);
			SquadData[Exists].SquadIcon = Squad.SquadImagePath != "" ? Squad.SquadImagePath : Squad.DefaultSquadImagePath; // could change the icon, stay up to date
			SquadData[Exists].NumMissions += 1.0;
			UpdateDeceasedSquadMembers();
			// Before resetting the current members array, go through the current team and see who is now a past member.
			UnitRefs = Squad.GetSoldierRefs();
			for (i = 0; i < SquadData[Exists].CurrentMembers.Length; i++) {
				Index = UnitRefs.Find('ObjectID', SquadData[Exists].CurrentMembers[i].SoldierID);
				if (Index == INDEX_NONE) { // could not find this unit in the squad manager current squad members, they are a past member now.
					SquadData[Exists].PastMembers.AddItem(SquadData[Exists].CurrentMembers[i]);
				}
			}
			SquadData[Exists].CurrentMembers.Length = 0;
			SquadData[Exists].CurrentMembers = UpdateCurrentMembers(Squad);
			SquadData[Exists].CurrentSquadLeader = AssignSquadLeader(Squad);
			SquadData[Exists].NumSoldiers = Units.Length;
			SquadData[Exists].bIsActive = true;
			SquadData[Exists].SquadID = SquadMgr.LastMissionSquad.ObjectID;
			// Chosen Data stuff
			if(BattleData.ChosenRef.ObjectID != 0) {
				UpdateChosenInformation(BattleData, Exists);
			}
			UpdateClearanceRates(BattleData, Exists);
			XCOMSquadLinked = true;
		} else { // not the gatecrasher team.

			// This if statement handles the case where the entire squad dies on the first mission. First mission so no concept of past members
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
				EntryData.CurrentSquadLeader = AssignSquadLeader(Squad);
				UpdateDeceasedSquadMembers();
				Units = Squad.GetSoldiers();
				EntryData.NumSoldiers = Units.Length;
				EntryData.AverageRank = CalculateAverageRank(Squad);
				EntryData.bIsActive = true;
				EntryData.Missions.AddItem(GetMissionSummaryDetails());
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
		// check if the current squad name was a past squad name
		Exists = SquadData[Index].PastSquadNames.Find(Squad.sSquadName);
		if (Exists == INDEX_NONE) { // brand new name
			if (SquadData[Index].SquadName != Squad.sSquadName) { // The name in our db does not match the current name, update accordingly
				SquadData[Index].PastSquadNames.AddItem(SquadData[Index].SquadName);
				SquadData[Index].SquadName = Squad.sSquadName;
			}
		}
		// this covers if a past squad name was reused.
		if (SquadData[Index].SquadName != Squad.sSquadName) {
			SquadData[Index].SquadName = Squad.sSquadName;
		}
		SquadData[Index].SquadIcon = Squad.SquadImagePath != "" ? Squad.SquadImagePath : Squad.DefaultSquadImagePath; // could change the icon, stay up to date
		SquadData[Index].NumMissions += 1.0;
		UpdateDeceasedSquadMembers();
		SquadData[Index].CurrentMembers.Length = 0;
		SquadData[Index].CurrentMembers = UpdateCurrentMembers(Squad);
		SquadData[Index].CurrentSquadLeader = AssignSquadLeader(Squad);
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
		SquadData[Index].Missions.AddItem(GetMissionSummaryDetails());
	} else {
		SquadData[Index].MissionNamesLosses.AddItem(BattleData.m_strOpName);
		SquadData[Index].MissionClearanceRate = (SquadData[Index].Wins / SquadData[Index].NumMissions) * 100 $ "%";
		SquadData[Index].Missions.AddItem(GetMissionSummaryDetails());
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
		SoldierData = GetSoldierDetails(Unit);
		if (Unit.IsAlive() && !Unit.bCaptured) {
			TeamData.CurrentSquadLeader = SoldierData.FullName;
		} else if (Unit.bCaptured) {
			TeamData.PastMembers.AddItem(SoldierData);
		}	else if (!Unit.IsAlive()) {
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
	TeamData.Missions.AddItem(GetMissionSummaryDetails());
	return TeamData;
	// forgo setting SquadID since we'll link it later.
}

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

function string AssignSquadLeader(XComGameState_LWPersistentSquad Team) {
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
				// It is possible that this soldier does not belong to any squad. In which case they don't go in any squad pages.
				`log("what is the objectID"@UnitRef.ObjectID);
				Found = SquadData[Index].CurrentMembers.Find('SoldierID', UnitRef.ObjectID); // even though they are dead, they are still in the current members array
				`log("If the number isn't negative, they belong to a squad on record"@Found);
				`log("the squad they belong to is"@SquadData[Index].SquadName);
				if (Found != INDEX_NONE) {
					SquadData[Index].DeceasedMembers.AddItem(Detail);
					SquadData[Index].NumSoldiers -= 1;
				}
				Found = SquadData[Index].PastMembers.Find('SoldierID', UnitRef.ObjectID);
				// they are a past member for this squad, change their status to dead.
				if (Found != INDEX_NONE) {
					SquadData[Index].PastMembers[Found].Status = "KIA";
				}
			}
		}
	 }
}

// resets the array and populates with Squad.GetSoldiers();
function array<SoldierDetails> UpdateCurrentMembers(XComGameState_LWPersistentSquad Team) {
	local SoldierDetails Data;
	local array <XComGameState_Unit> Units;
	local array<SoldierDetails> UpdatedList;
	local int Index;

	Units = Team.GetSoldiers();

	for (Index = 0; Index < Units.Length; Index++) {
		Data = GetSoldierDetails(Units[Index]);
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
// because squad XCOM doesn't have an ID until they've completed a mission, they are unaffected by this
// This updates the current members array as well as the past members array
function UpdateAllCurrentSquadMembers() {
	local XComGameState_LWSquadManager Manager;
	local StateObjectReference Ref;
	local XComGameState_LWPersistentSquad Team;
	local SoldierDetails Data;
	local array <StateObjectReference> UnitRefs;
	local array <XComGameState_Unit> Units;
	local int Index, i, Found, Check;
	Manager = XComGameState_LWSquadManager(`XCOMHISTORY.GetSingleGameStateObjectForClass(class 'XComGameState_LWSquadManager', true));
	foreach Manager.Squads(Ref) {
		Team = XComGameState_LWPersistentSquad(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
		Index = SquadData.Find('SquadID', Team.ObjectID);
		if (Index != INDEX_NONE) { // We have the squad on record
			UnitRefs = Team.GetSoldierRefs(); // currently in the squad via squad manager
			// loop through our internal array and see if anyone has been reassigned.
			// this is old data but is ok since that is what we need to cross reference.
			for (i = 0; i < SquadData[Index].CurrentMembers.Length; i++) {
				Found = UnitRefs.Find('ObjectID', SquadData[Index].CurrentMembers[i].SoldierID);
				if (Found == INDEX_NONE) { // This soldier is a past member now
					Check = SquadData[Index].PastMembers.Find('SoldierID', SquadData[Index].CurrentMembers[i].SoldierID);
					if (Check == INDEX_NONE) { // Check if they're not already in the past members array
						SquadData[Index].PastMembers.AddItem(SquadData[Index].CurrentMembers[i]);
					}
				} else { // They are a current member on record, even if we do the reset
					// check that they are not currently on the past members array
					Check = SquadData[Index].PastMembers.Find('SoldierID', SquadData[Index].CurrentMembers[i].SoldierID);
					// if they are in the past members array, we need to remove them.
					if (Check != INDEX_NONE) {
						SquadData[Index].PastMembers.Remove(Check, 1);
					}
				}
			}
			SquadData[Index].CurrentMembers.Length = 0; // Recalculate the current members array
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
	local XComGameState_Analytics Analytics;
	local int Hours, Days;
	local XComGameState_BattleData BattleData;
	local XComGameState_CampaignSettings CampaignSettingsStateObject;
	local int CampaignIndex;

	Analytics = XComGameState_Analytics(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_Analytics'));
	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class 'XComGameState_BattleData'));
	CampaignSettingsStateObject = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings', true));
	CampaignIndex = CampaignSettingsStateObject.GameIndex;
	Detail.CampaignIndex = CampaignIndex;
	Detail.SoldierID = Unit.GetReference().ObjectID;
	Detail.FullName = Unit.GetName(eNameType_FullNick);
	Detail.SoldierRank = Unit.GetRank();
	Detail.SoldierRankImage = GetRankImage(Detail.SoldierRank);
	if (!Unit.IsAlive()) {
		Detail.Status =  "KIA";
	} else if (Unit.bCaptured) {
		Detail.Status = "Captured";
	} else {
		Detail.Status = "Active";
	}
	Detail.SoldierFlag = Unit.GetCountryTemplate().FlagImage;
	if (Detail.SoldierFlag == "") {
		Detail.SoldierFlag = UnitFlagImage;
	}
	Hours = Analytics.GetUnitFloatValue( "ACC_UNIT_SERVICE_LENGTH", Unit.GetReference() );
	Days = int(Hours / 24.0f);
	Detail.DaysOnAvenger = Days;
	Detail.CauseOfDeath = Unit.m_strCauseOfDeath;
	Hours = Analytics.GetUnitFloatValue( "ACC_UNIT_HEALING", Unit.GetReference() );
	Days = int( Hours / 24.0f );
	Detail.DaysInjured = Days;
	Detail.AttacksMade = Analytics.GetUnitFloatValue( "ACC_UNIT_SUCCESSFUL_ATTACKS", Unit.GetReference() );
	Detail.DamageDealt = Analytics.GetUnitFloatValue( "ACC_UNIT_DEALT_DAMAGE", Unit.GetReference() );
	Detail.AttacksSurvived = Analytics.GetUnitFloatValue( "ACC_UNIT_ABILITIES_RECIEVED", Unit.GetReference() );
	Detail.MissionDied = BattleData.m_strOpname;
	Detail.KilledDate = class'X2StrategyGameRulesetDataStructures'.static.GetDateString(BattleData.LocalTime, true);
	Detail.Epitaph = Unit.m_strEpitaph;
	Detail.RankName = class'X2ExperienceConfig'.static.GetRankName(Unit.GetSoldierRank(), Unit.GetSoldierClassTemplateName());
	Detail.CountryName = Unit.GetCountryTemplate().DisplayName;
	Detail.ClassName = Unit.GetSoldierClassTemplate().DisplayName;
	Detail.CountryTemplateName = Unit.GetCountry();
	return Detail;
}

function SoldierDetails GetMissionSummaryDetails() {
	local SoldierDetails MissionData;
	local MissionImages Pics;
	local X2MissionTemplateManager MissionTemplateManager;
	local X2MissionTemplate MissionTemplate;
	local XComGameState_BattleData BattleData;

	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	MissionTemplateManager = class'X2MissionTemplateManager'.static.GetMissionTemplateManager();
	MissionTemplate = MissionTemplateManager.FindMissionTemplate(BattleData.MapData.ActiveMission.MissionName);
	MissionData.FullName = BattleData.m_strOpName;
	if (BattleData.bLocalPlayerWon && !BattleData.bMissionAborted) {
		MissionData.Status = "Success";
	} else {
		MissionData.Status = "Failed";
	}
	
	Pics = GetMissionImages(MissionTemplate.DisplayName);
	MissionData.SoldierRankImage = Pics.MissionGraphic;
	MissionData.SoldierFlag = Pics.MissionThumbnail;
	return MissionData;
}


function MissionImages GetMissionImages(string obj) {
	local MissionImages Images;
	if (obj == "Defeat Chosen Warlock") {
		Images.MissionThumbnail = "img:///UILibrary_XPACK_StrategyImages.DarkEvent_Loyalty_Among_Thieves_Warlock";
		Images.MissionGraphic = "img:///UILibrary_XPACK_Common.MissionIcon_ChosenStronghold";
	} else if (obj == "Defeat Chosen Assassin") {
		Images.MissionThumbnail = "img:///UILibrary_XPACK_StrategyImages.DarkEvent_Loyalty_Among_Thieves_Assasin";
		Images.MissionGraphic = "img:///UILibrary_XPACK_Common.MissionIcon_ChosenStronghold";
	} else if (obj == "Defeat Chosen Hunter") {
		Images.MissionThumbnail = "img:///UILibrary_XPACK_StrategyImages.DarkEvent_Loyalty_Among_Thieves_Hunter";
		Images.MissionGraphic = "img:///UILibrary_XPACK_Common.MissionIcon_ChosenStronghold";
	} else if (obj == "Rescue Stranded Resistance Agents" || InStr(obj, "Gather Survivors") > -1) {
		Images.MissionThumbnail = "img:///UILibrary_DLC2Images.Alert_Downed_Skyranger";
		Images.MissionGraphic = "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_Resistance";
	} else if (InStr(obj, "Extract VIP") > -1 || obj == "Recover Resistance Operative") {
		Images.MissionThumbnail = "img:///UILibrary_DLC2Images.Alert_Downed_Skyranger";
		Images.MissionGraphic = "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_Resistance";
	} else if (InStr(obj, "Rescue VIP") > -1 || obj == "Rescue Operative from ADVENT Compound") {
		Images.MissionThumbnail = "img:///UILibrary_XPACK_StrategyImages.DarkEvent_The_Collectors";
		Images.MissionGraphic = "img:///UILibrary_XPACK_Common.MissionIcon_RescueSoldier";
	} else if (obj == "Stop the ADVENT Retaliation" || obj == "Haven Assault") {
		Images.MissionThumbnail = "img:///UILibrary_StrategyImages.X2StrategyMap.Alert_Retaliation";
		Images.MissionGraphic = "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_Retaliation";
	} else if (InStr(obj, "Raid") > -1 || obj == "Extract ADVENT Supplies") {
		Images.MissionThumbnail = "img:///UILibrary_StrategyImages.X2StrategyMap.POI_DeadAdvent";
		Images.MissionGraphic = "img:///UILibrary_XPACK_Common.MissionIcon_SupplyExtraction";
	} else if (InStr(obj, "Investigate") > -1 || obj == "Secure the ADVENT Network Tower" || obj == "Assault the Alien Fortress" || obj == "Destroy Avatar Project") { // story
		Images.MissionThumbnail = "img:///UILibrary_StrategyImages.X2StrategyMap.POI_WhatsInTheBarn";
		Images.MissionGraphic = "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_Goldenpath";
	} else if (obj == "Defend the Avenger" || obj == "Repel the Chosen Assault") {
		Images.MissionThumbnail = "img:///UILibrary_XPACK_StrategyImages.Alert_Avenger_Assault";
		Images.MissionGraphic = "img:///UILibrary_DLC2Images.MissionIcon_POI_Special2"; // could cause a crash if they don't have dlc installed possibly
	} else {
		Images.MissionThumbnail = "img:///uilibrary_strategyimages.X2StrategyMap.Alert_Objective_Complete";
		Images.MissionGraphic = "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_GOPS";
	}

	return Images;
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

DefaultProperties {
	bSingleton=true;
}