// This is an Unreal Script

class FilteredScreen extends UIPersonnel dependson(XComGameState_SquadStats);

var UIPersonnel FilteredList;

var UINavigationHelp NavHelp;

simulated function InitFilterScreen(string ListType)
{
	FilteredList = Spawn(class'UIPersonnel', self);
	// FilteredList.OverrideInterpTime = 0.0;
	FilteredList.m_eListType = eUIPersonnel_Scientists;
	FilteredList.bIsNavigable = true;
	// FilteredList.OnItemClicked = OnSquadSelected;
	MC.FunctionString("SetScreenHeader", ListType@"List");
}
/*
// this function may be redundant for our purposes
simulated function OnListItemClicked(UIList ContainerList, int ItemIndex) {
	if (!FilteredScreen_ListItem(ContainerList.GetItem(ItemIndex)).IsDisabled) {
		OpenSquadDetails(SquadScreen_ListItem(ContainerList.GetItem(ItemIndex)));
	}
}

// same here
// I have the list item, but how do I get the data?
simulated function OpenSquadDetails(SquadScreen_ListItem Data) {
	
}
*/

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
	Movie.Stack.PopFirstInstanceOfClass(class'FilteredScreen');

	Movie.Pres.PlayUISound(eSUISound_MenuClose);
}

simulated function PopulateListInstantly() {
	local XComGameState_SquadStats Stats;
	local int i, Index;
	local array<SoldierDetails> List;
	Stats = XComGameState_SquadStats(`XCOMHISTORY.GetSingleGameStateObjectForClass(class 'XComGameState_SquadStats', true));
	Index = Stats.SquadData.Find('SquadName', Stats.SelectedSquad);
	`LOG("Index of the theoretically found squad"@Index);
	List = Stats.SelectedList == "Deceased" ? Stats.SquadData[Index].DeceasedMembers : Stats.SquadData[Index].PastMembers;
	`LOG("Length of the array"@List.Length);
	for (i = 0; i < List.Length; i++) {
		// m_kList.OnItemClicked = OnListItemClicked; // This is if we want to do something if they click on an entry
		Spawn(class'FilteredScreen_ListItem', m_kList.itemContainer).InitListItem(List[i]);
	}
	MC.FunctionString("SetEmptyLabel", List.Length == 0 ? "No Entries Found": "");
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