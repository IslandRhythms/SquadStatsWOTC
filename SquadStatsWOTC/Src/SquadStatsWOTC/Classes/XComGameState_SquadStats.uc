// This is an Unreal Script
class XComGameState_SquadStats extends XComGameState_BaseObject;

struct SquadDetails {
	var array<String> CurrentMembers;
	var array<String> PastMembers;
	var array<String> DeceasedMembers;
	var array<String> MissionNames;
	var float MissionClearanceRate;
	var float WinRateAgainstWarlock;
	var float WinRateAgainstHunter;
	var float WinRateAgainstAssassin;
	var string SquadIcon;
	var string SquadName;
	var string CurrentSquadCommander; // First soldier Added to the Squad. Can change over time
};

struct ChosenInformation {
	var string ChosenType;
	var string ChosenName;
	var float NumEncounters;
	var float NumDefeats;
	var int CampaignIndex;
}


var array<SquadDetails> SquadData;

var array<ChosenInformation> TheChosen;

function UpdateSquadData() {

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