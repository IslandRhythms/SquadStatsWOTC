// This is an Unreal Script
class XComGameState_SquadStats extends XComGameState_BaseObject;

struct SquadDetails {
	var array<String> CurrentMembers;
	var array<String> PastMembers;
	var array<String> DeceasedMembers;
	var array<String> PastSquadNames;
	var array<String> MissionNames;
	var float MissionClearanceRate;
	var float WinRateAgainstWarlock;
	var float WinRateAgainstHunter;
	var float WinRateAgainstAssassin;
	var string SquadInceptionDate;
	var string SquadIcon;
	var string SquadName;
	var string CurrentSquadCommander; // First soldier Added to the Squad. Can change over time
	var TDateTime RawInception;
	var bool bIsActive; // If the user deletes a squad, don't display it. If they remake the squad, we can reaccess the old data.
	var StateObjectReference SquadID;
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
	local int Index;

	SquadMgr = XComGameState_LWSquadManager(`XCOMHISTORY.GetSingleGameStateObjectForClass(class 'XComGameState_LWSquadManager', true));
	Squad = XComGameState_LWPersistentSquad(`XCOMHISTORY.GetGameStateForObjectID(SquadMgr.LastMissionSquad.ObjectID));
	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class 'XComGameState_BattleData'));
	// Check if the Squad already exists in our Data
	Index = SquadData.Find('SquadID', SquadMgr.LastMissionSquad.ObjectID);
	if (Index == INDEX_NONE && BattleData.m_strOpName == "Operation Gatecrasher") {
	// Need to get a default image to use for the squad icon since its only used once.
	/*
		EntryData.SquadIcon = ;
		EntryData.SquadName = "XCOM"; // make this client facing so they can create the squad later on and keep these details
		EntryData.RawInception = ;
		EntryData.SquadInceptionDate;
		EntryData.MissionNames.AddItem(BattleData.m_strOpName);
	*/
	} else if (Index == INDEX_NONE) { // Not gatecrasher but the first time this squad went out on a mission
		EntryData.SquadID = SquadMgr.LastMissionSquad.ObjectID;
	} else { // any other time

	}
	// TODO: iterate through all the squads to see if any have been deleted.
	// foreach `XCOMHQ.Squad(UnitRef) // an array of unit refs. Might be easier to use the squad functions
	// EntryData.CurrentSquadCommander = Get the Squad that was deployed and use the first entry [0] in the array

	EntryData.
	// EntryData.SquadInceptionDate = // Set as the first mission they complete

	EntryData.SquadIcon = Squad.SquadImagePath ? Squad.SquadImagePath : Squad.DefaultSquadImagePath;

	EntryData.SquadName = Squad.sSquadName ? Squad.sSquadName : "XCOM";
	SquadData.AddItem(EntryData);

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