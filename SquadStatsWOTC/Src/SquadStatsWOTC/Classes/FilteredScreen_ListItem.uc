// This is an Unreal Script
class FilteredScreen_ListItem extends UIButton dependson(XComGameState_SquadStats);

// var bool bNeedsAttention;	//from parent

var localized string m_StrStatusMIA, m_StrStatusMIAChosen, m_StrStatusKIA, m_StrStatusDIA, m_StrStatusKIABody, m_StrStatusDIABody;

var UIPanel BG;
var UIIcon HudHeadIcon;
var UIScrollingText LocStatusText;

var SoldierDetails Data;
var EUIState i_eState;
var string m_StrStatus;

var bool bIsFocussed;

simulated function FilteredScreen_ListItem InitListItem(SoldierDetails Entry)
{

	InitPanel(); // must do this before adding children or setting data
	Data = Entry;
	//BG is spawned by the button/flash control done by UIButton
	/*BG = Spawn(class'UIPanel', self);
	BG.InitPanel('BGButton');
	BG.ProcessMouseEvents(onMouseEventDelegate); // processes all our Mouse Events
	*/

    LocStatusText = Spawn(class'UIScrollingText', self);
    LocStatusText.InitScrollingText('',"", 375, 174, 22, true); //name, string, width, x, y, title

	CreateHudHeadIcon();

	UpdateData(); // this is really 'set initial data' as the listitem gets destroyed and recreateds

	SetHudHeadIcon(Data.SoldierRankImage);

	return self;
}

simulated function CreateHudHeadIcon()
{
	HudHeadIcon = Spawn(class'UIIcon', self);
	HudHeadIcon.bAnimateOnInit = false;
	HudHeadIcon.bIsNavigable = false;
	HudHeadIcon.bDisableSelectionBrackets = true;
	HudHeadIcon.InitIcon(,,false,true, 26); //'RustyHudHeadIcon'
	HudHeadIcon.SetX(HudHeadIcon.X + 108);
	HudHeadIcon.SetY(HudHeadIcon.Y + 12);

	// HudHeadIcon.SetForegroundColor(class'UIUtilities_Colors'.const.BLACK_HTML_COLOR);

}

simulated function SetHudHeadIcon(optional string NewPath)
{
	local XComGameState_Unit    Unit;
	local X2CharacterTemplate   CharTemplate;
	local string UnitTypeImage;

	// Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
	// CharTemplate = Unit.GetMyTemplate();

	//Add Target Head Icon
	UnitTypeImage = NewPath;

	// if(CharTemplate.StrTargetIconImage != "")	{ UnitTypeImage = "img:///" $ CharTemplate.StrTargetIconImage; }
	// if(NewPath != "")							{ UnitTypeImage = "img:///" $ NewPath; }

	// HudHeadIcon.SetBGColor(GetIconColour(Unit));	

	// HudHeadIcon.LoadIconBG(UnitTypeImage $ "_bg");
	HudHeadIcon.LoadIcon(UnitTypeImage);
}

simulated function UpdateData()
{
	local XComGameState_SquadStats SquadStats;
	local EUIPersonnelType      UnitPersonnelType; 
	local string FlagImage, UnitsName, Classification;
	local name TemplateName;

	//kinda cheating but all Bestiary are displayed as Scientist to not show Extended Personnel Info Wings
	UnitPersonnelType = eUIPersonnel_Scientists;

	// Need to get the latest state here, else you may have old data in the list upon refreshing via OnReceiveFocus, such as still showing dismissed soldiers. 
	// SquadStats = XComGameState_SquadStats(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_SquadStats'));
	/*if (BestiaryHQ.NewEntries.Find(TemplateName) != INDEX_NONE)
	{
		bNeedsAttention = true;
	}*/

	//get country/affiliation flag, or attention flag
	// do something else here to get the squad logo
	// make sure logo has img:/// prefix
	FlagImage = Data.SoldierFlag;

	//get and set display strings
	UnitsName = Data.FullName;
	// Active or Decomissioned
	if (Data.bIsAlive) {
		Classification = "Active";
	} else {
		Classification = "KIA";
	}

	// SetLocationOrStatusString(Unit, TemplateName);
	// LocStatusText.SetTitle(class'UIUtilities_Text'.static.GetColoredText(Caps(m_StrStatus), i_eState, 18, "RIGHT") );
	
	//colour strings if needed "E69831"; // Orange .. not working, makes name be [name...] ??
	/*if (bNeedsAttention)
	{
		UnitsName = "<font color='#E69831'>" $UnitsName $"</font>";
		Classification = "<font color='#E69831'>" $Classification $"</font>";
	}*/

	//Send information to flash aspects
	// 			(UnitName, UnitSkill, UnitStatus, UnitStatusValue, UnitLocation, UnitCountryFlagPath, bIsDisabled, UnitType, UnitTypeIcon )
	// either unit location or unit status value could put squad strength
	AS_UpdateData(UnitsName, "0", Classification, "", "", FlagImage, false, UnitPersonnelType, "");
}

//Send it to Flash
simulated function AS_UpdateData(string UnitName, string UnitSkill, 
								 string UnitStatus, string UnitStatusValue, 
								 string UnitLocation, string UnitCountryFlagPath,
								 bool bIsDisabled, 
								 EUIPersonnelType UnitType, string UnitTypeIcon )
{
	MC.BeginFunctionOp("UpdateData");

	MC.QueueString(UnitName);
	MC.QueueString(UnitSkill);
	MC.QueueString(UnitStatus);
	MC.QueueString(UnitStatusValue);
	MC.QueueString(UnitLocation);
	MC.QueueString(UnitCountryFlagPath);
	MC.QueueBoolean(bIsDisabled);
	MC.QueueNumber(int(UnitType));
	MC.QueueString(UnitTypeIcon);

	MC.EndOp();
}

/*
simulated function AnimateIn(optional float delay = -1.0)
{
	// this needs to be percent of total time in sec 
	if( delay == -1.0)
    {
		delay = ParentPanel.GetChildIndex(self) * class'UIUtilities'.const.INTRO_ANIMATION_DELAY_PER_INDEX; 
    }

	AddTweenBetween( "_alpha", 0, alpha, class'UIUtilities'.const.INTRO_ANIMATION_TIME, delay );
	AddTweenBetween( "_y", Y+10, Y, class'UIUtilities'.const.INTRO_ANIMATION_TIME*2, delay, "easeoutquad" );
}*/

//adjust text for highlight
simulated function UpdateItemsForFocus(bool Focussed)
{
	local bool bReverse;
	bIsFocussed = Focussed;
	bReverse = bIsFocussed && !IsDisabled;

	if(m_StrStatus != "")
	{
		if(bReverse)	{ LocStatusText.SetTitle(class'UIUtilities_Text'.static.GetColoredText( m_StrStatus, -1, 18, "RIGHT" ) 			); } //BLACK
		else 			{ LocStatusText.SetTitle(class'UIUtilities_Text'.static.GetColoredText( m_StrStatus, i_eState, 18, "RIGHT" ) 	); } //COLOURED
	}
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	UpdateItemsForFocus(true);
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	UpdateItemsForFocus(false);
}

// all mouse events get processed by bg
simulated function UIPanel ProcessMouseEvents(optional delegate<onMouseEventDelegate> mouseEventDelegate)
{
	onMouseEventDelegate = mouseEventDelegate;
	return self;
}

defaultproperties
{
	LibID = "PersonnelListItem";
	bAnimateOnInit = false;

	width = 1111;
	height = 56;
	bProcessesMouseEvents = true;
	bIsNavigable = true;
}
