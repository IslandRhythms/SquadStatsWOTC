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

}