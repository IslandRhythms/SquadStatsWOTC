// This is an Unreal Script

class SquadScreen extends UIPersonnel dependson(XComGameState_SquadStats);

var UIPersonnel SquadList;
var UINavigationHelp NavHelp;
var SquadScreen_ListItem LastHighlighted;


simulated function InitSquadScreen()
{
	SquadList = Spawn(class'UIPersonnel', self);
	// SquadList.OverrideInterpTime = 0.0;
	SquadList.m_eListType = eUIPersonnel_Scientists;
	SquadList.bIsNavigable = true;
	// SquadList.OnItemClicked = OnSquadSelected;
	MC.FunctionString("SetScreenHeader", "Squads");
}

simulated function OnListItemClicked(UIList ContainerList, int ItemIndex) {
	if (!SquadScreen_ListItem(ContainerList.GetItem(ItemIndex)).IsDisabled) {
		OpenSquadDetails(SquadScreen_ListItem(ContainerList.GetItem(ItemIndex)));
	}
}

// I have the list item, but how do I get the data?
simulated function OpenSquadDetails(SquadScreen_ListItem Data) {
	local TDialogueBoxData DialogData;
	local String StrDetails;
	local SquadDetails Detail;
	local Texture2D StaffPicture;
	Detail = Data.Data;
	DialogData.eType = eDialog_Normal;
	DialogData.strTitle = Detail.SquadName;
	DialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
	StrDetails = "";
	DialogData.strText = StrDetails;
	DialogData.strImagePath = class'UIUtilities_Image'.static.ValidateImagePath(Detail.SquadIcon);
	Movie.Pres.UIRaiseDialog( DialogData );
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