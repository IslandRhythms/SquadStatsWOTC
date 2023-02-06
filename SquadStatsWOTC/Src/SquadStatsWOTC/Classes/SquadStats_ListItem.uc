// This is an Unreal Script

class SquadStats_ListItem extends UIPersonnel_ListItem dependson(XComGameState_SquadStats);

var SquadDetails Datum;

var UIBGBox BorderBox;

simulated function SquadStats_ListItem RefreshHistory(SquadDetails UpdateData) {
	InitPanel();
	Datum = UpdateData;
	FillTable();
	return self;
}

simulated function SetHighlighted(bool IsHighlighted)
{
	if (IsHighlighted)
		BorderBox.SetOutline(true, "0x00ffff");
	else
		BorderBox.SetOutline(true, "0x000000");

}

simulated function FillTable() {
	 local string shorten;
	MC.BeginFunctionOp("UpdateData");
	
	MC.QueueString(Datum.CurrentSquadCommander);	// Mission
	/*
	if (Len(Datum.SquadName) > 11) {
		shorten = Left(Datum.SquadName, 11);
		MC.QueueString(shorten); // Squad
	} else {
		MC.QueueString(Datum.SquadName);	// Squad
	}*/
	// MC.QueueString(Datum.SquadName);
	MC.QueueString(Datum.SquadInceptionDate);			// Date
	MC.QueueString(Datum.SquadName);				// Rating
	// MC.QueueString(Datum.SuccessRate);			// Rate
	
	MC.EndOp();
}

defaultproperties
{
	LibID = "DeceasedListItem";
	height = 40;
}