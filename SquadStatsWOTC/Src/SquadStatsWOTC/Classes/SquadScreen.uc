// This is an Unreal Script

class SquadScreen extends UIPersonnel dependson(XComGameState_SquadStats);

var UIPersonnel SquadList;
var UINavigationHelp NavHelp;
var SquadScreen_ListItem LastHighlighted;
var UIButton Deceased;
var UIButton Former;

simulated function InitSquadScreen()
{
	SquadList = Spawn(class'UIPersonnel', self);
	// SquadList.OverrideInterpTime = 0.0;
	SquadList.m_eListType = eUIPersonnel_Scientists;
	SquadList.bIsNavigable = true;
	// SquadList.OnItemClicked = OnSquadSelected;
	MC.FunctionString("SetScreenHeader", "Squad History and Stats");
}

simulated function OnListItemClicked(UIList ContainerList, int ItemIndex) {
	if (!SquadScreen_ListItem(ContainerList.GetItem(ItemIndex)).IsDisabled) {
		OpenSquadDetails(SquadScreen_ListItem(ContainerList.GetItem(ItemIndex)));
	}
}

simulated function DeceasedButtonClicked(UIButton ButtonClicked) {
	local FilteredScreen FS;
	local UIDialogueBox Box;
	local XComGameState_SquadStats Stats;
	Stats = XComGameState_SquadStats(`XCOMHISTORY.GetSingleGameStateObjectForClass(class 'XComGameState_SquadStats', true));
	`LOG("THE DECEASED BUTTON WORKS");
	if( `HQPRES.ScreenStack.IsNotInStack(class'FilteredScreen') )
	{
		Stats.SelectedList = "Deceased";
		Deceased.Remove();
		Former.Remove();
		Box = UIDialogueBox(Movie.Pres.ScreenStack.GetCurrentScreen());
		Box.RemoveDialog();
		`HQPRES.ScreenStack.PopFirstInstanceOfClass(class'SquadScreen', false); // may not want to pop this
		FS = `HQPRES.Spawn(class'FilteredScreen',`HQPRES);

        `HQPRES.ScreenStack.Push(FS);
		FS.InitFilterScreen(Stats.SelectedList);
	}
}

simulated function FormerButtonClicked(UIButton ButtonClicked) {
	/*
	local FilteredScreen FS;
	local UIDialogueBox Box;
	`LOG("THE FORMER BUTTON WORKS");
	if( `HQPRES.ScreenStack.IsNotInStack(class'FilteredScreen') )
	{
		Box = UIDialogueBox(Movie.Pres.ScreenStack.GetCurrentScreen());
		Box.RemoveDialog();
		`HQPRES.ScreenStack.PopFirstInstanceOfClass(class'SquadScreen', false);
		FS = `HQPRES.Spawn(class'FilteredScreen',`HQPRES);

        `HQPRES.ScreenStack.Push(FS);
		FS.InitFilteredScreen("Former", SquadName);
	}
	*/
}


// I have the list item, but how do I get the data?
simulated function OpenSquadDetails(SquadScreen_ListItem Data) {
	local TDialogueBoxData DialogData;
	local XComGameState_SquadStats Stats;
	local String StrDetails;
	local SquadDetails Detail;
	local Texture2D StaffPicture;
	local int i;
	Detail = Data.Data;
	DialogData.eType = eDialog_Normal;
	DialogData.strTitle = Detail.SquadName;
	DialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
	StrDetails = "Squad Launched on"@Detail.SquadInceptionDate;
	StrDetails = StrDetails $ "\nCurrent Squad Leader: "@Detail.CurrentSquadLeader;
	StrDetails = StrDetails $ "\nTotal Troops in Squad:"@Detail.NumSoldiers;
	// commenting out fields that don't really add anything/overflow the allotted space
	/*StrDetails = StrDetails $ "\nCurrent Members:";
	for (i = 0; i < Detail.CurrentMembers.Length;i++) {
		StrDetails = StrDetails $ "\n"@Detail.CurrentMembers[i].FullName;
	}*/
	if (Detail.PastMembers.Length > 0) StrDetails = StrDetails $ "\nFormer Members:";
	for (i = 0; i < Detail.PastMembers.Length; i++) {
		StrDetails = StrDetails $ "\n"@Detail.PastMembers[i].FullName;
	}
	if (Detail.DeceasedMembers.Length > 0) StrDetails = StrDetails $ "\nDeceased Members:";
	for (i = 0; i < Detail.DeceasedMembers.Length; i++) {
		StrDetails = StrDetails $ "\n"@Detail.DeceasedMembers[i].FullName;
	}
	StrDetails = StrDetails $ "\nSuccess Rate:"@Detail.MissionClearanceRate;
	if (Detail.WinRateAgainstWarlock != "") {
		StrDetails = StrDetails $ "\nSuccess Rate Against Warlock:"@Detail.WinRateAgainstWarlock;
	}
	if (Detail.DefeatedWarlock) {
		StrDetails = StrDetails $ "\nExterminated the Warlock";
	}
	if (Detail.WinRateAgainstHunter != "") {
		StrDetails = StrDetails $ "\nSuccess Rate Against Hunter:"@Detail.WinRateAgainstHunter;
	}
	if (Detail.DefeatedHunter) {
		StrDetails = StrDetails $ "\nExterminated the Hunter";
	}
	if (Detail.WinRateAgainstAssassin != "") {
		StrDetails = StrDetails $ "\nSuccess Rate Against Assassin:"@Detail.WinRateAgainstAssassin;
	}
	if (Detail.DefeatedAssassin) {
		StrDetails = StrDetails $ "\nExterminated the Assassin";
	}
	if (Detail.PastSquadNames.Length > 0) {
		StrDetails = StrDetails $ "\nPast Names of the Squad:";
	}
	for (i = 0; i < Detail.PastSquadNames.Length; i++) {
		StrDetails = StrDetails $ "\n"@Detail.PastSquadNames[i];
	}
	StrDetails = StrDetails $ "\nNumber of Missions Deployed:"@Detail.NumMissions;
	if (Detail.MissionNamesWins.Length > 0) StrDetails = StrDetails $ "\nSuccessful Operations:"@Detail.MissionNamesWins.Length;
	/*
	for (i = 0; i < Detail.MissionNamesWins.Length; i++) {
		StrDetails = StrDetails $ "\n"@Detail.MissionNamesWins[i];
	}*/
	if (Detail.MissionNamesLosses.Length > 0) StrDetails = StrDetails $ "\nFailed Operations:"@Detail.MissionNamesLosses.Length;
	/*
	for (i = 0; i < Detail.MissionNamesLosses.Length; i++) {
		StrDetails = StrDetails $ "\n"@Detail.MissionNamesLosses[i];
	}*/

	DialogData.strText = StrDetails;
	DialogData.strImagePath = class'UIUtilities_Image'.static.ValidateImagePath(Detail.SquadIcon);
	Movie.Pres.UIRaiseDialog( DialogData );
	Stats = XComGameState_SquadStats(`XCOMHISTORY.GetSingleGameStateObjectForClass(class 'XComGameState_SquadStats', true));
	Stats.SelectedSquad = Detail.SquadName;
	// UIDialogueBox_4
	// Would probably be _3 if we called it before the dialogue was raised.
	`LOG(Movie.Pres.ScreenStack.GetCurrentScreen());
	// theoretically we should be able to find the instance in the stack and add that there.
	Deceased = Spawn(class'UIButton', Movie.Pres.ScreenStack.GetCurrentScreen());
	Deceased.InitButton('DeceasedList', "View Deceased Soldiers", DeceasedButtonClicked, eUIButtonStyle_NONE);
	Deceased.SetPosition(50, 880);
	Former = Spawn(class 'UIButton', Movie.Pres.ScreenStack.GetCurrentScreen());
	Former.InitButton('FormerList', "View Former Squad Mates", FormerButtonClicked, eUIButtonStyle_NONE);
	Former.SetPosition(150, 770);
}

simulated function CreateSortHeaders()
{
	//1st two are 'not needed' but is for the flash stuff ? Dunno, the whole dropdown menu goes haywire without them
	m_kSoldierSortHeader = Spawn(class'UIPanel', self);
	m_kSoldierSortHeader.bIsNavigable = false;
	m_kSoldierSortHeader.InitPanel('soldierSort', 'SoldierSortHeader');
	m_kSoldierSortHeader.Hide();

	m_kDeceasedSortHeader = Spawn(class'UIPanel', self);
	m_kDeceasedSortHeader.bIsNavigable = false;
	m_kDeceasedSortHeader.InitPanel('deceasedSort', 'DeceasedSortHeader');
	m_kDeceasedSortHeader.Hide();

	//the one we actually want to adjust
	m_kPersonnelSortHeader = Spawn(class'UIPanel', self);
	m_kPersonnelSortHeader.bIsNavigable = false;
	m_kPersonnelSortHeader.InitPanel('personnelSort', 'PersonnelSortHeader');
	m_kPersonnelSortHeader.Hide();

	// Create Bestiary header 
	if(m_arrNeededTabs.Find(eUIPersonnel_Scientists) != INDEX_NONE)
	{
		Spawn(class'UIFlipSortButton', m_kPersonnelSortHeader).InitFlipSortButton("nameButton", ePersonnelSoldierSortType_Name, "name");
		Spawn(class'UIFlipSortButton', m_kPersonnelSortHeader).InitFlipSortButton("statusButton", ePersonnelSoldierSortType_Status, "status");
	}
}


simulated function OnCancel()
{
	// Deceased.Remove();
	// Former.Remove();
	Movie.Stack.PopFirstInstanceOfClass(class'SquadScreen');
	Movie.Pres.PlayUISound(eSUISound_MenuClose);
}

simulated function PopulateListInstantly() {
	local XComGameState_SquadStats Stats;
	local int i;
	Stats = XComGameState_SquadStats(`XCOMHISTORY.GetSingleGameStateObjectForClass(class 'XComGameState_SquadStats', true));
	for (i = 0; i < Stats.SquadData.Length; i++) {
		m_kList.OnItemClicked = OnListItemClicked;
		Spawn(class'SquadScreen_ListItem', m_kList.itemContainer).InitListItem(Stats.SquadData[i]);
	}
	MC.FunctionString("SetEmptyLabel", Stats.SquadData.Length == 0 ? "No Squads Created": "");
}

simulated function PopulateListSequentially(UIPanel Control) {
	PopulateListInstantly();
}

simulated function UpdateData() {
	local XComGameState_SquadStats SquadStats;
	local XComGameStateHistory History;
	local XComGameState_Unit Unit;
	local int i;
    	
	History = `XCOMHISTORY;

	// Destroy old data
	m_arrSoldiers.Length = 0;	m_arrScientists.Length = 0;	m_arrEngineers.Length = 0;	m_arrDeceased.Length = 0;

}

defaultproperties
{
	MCName          = "theScreen";
	Package = "/ package/gfxSoldierList/SoldierList";
	bConsumeMouseEvents = true;
	m_eListType=eUIPersonnel_Scientists;
}