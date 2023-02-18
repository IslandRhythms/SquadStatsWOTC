// This is an Unreal Script

class SquadScreen_ListItem extends UIButton dependson(XComGameState_SquadStats);

// var bool bNeedsAttention;	//from parent

var localized string m_StrStatusMIA, m_StrStatusMIAChosen, m_StrStatusKIA, m_StrStatusDIA, m_StrStatusKIABody, m_StrStatusDIABody;

var UIPanel BG;
var UIIcon HudHeadIcon;
var UIScrollingText LocStatusText;

var SquadDetails Data;
var EUIState i_eState;
var string m_StrStatus;

var bool bIsFocussed;

simulated function SquadScreen_ListItem InitListItem(SquadDetails Entry)
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

	SetHudHeadIcon(Data.AverageRank); // pass data.averagerank here

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
	FlagImage = Data.SquadIcon;

	//get and set display strings
	UnitsName = Data.SquadName;
	// Active or Decomissioned
	if (Data.bIsActive) {
		Classification = "Active";
	} else {
		Classification = "Decomissioned";
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

simulated function SetLocationOrStatusString(XComGameState_Unit Unit, name TemplateName)
{
	local EUIState eState;
	local string Status, TimeLabel, TimeValue;
	local int HideTime;

	if (Unit.IsSoldier() || (Unit.IsScientist() && TemplateName != 'HeadScientist') || (Unit.IsEngineer() && TemplateName != 'HeadEngineer') )
	{
		class'UIUtilities_Strategy'.static.GetPersonnelStatusStringParts(Unit, Status, eState, TimeLabel, TimeValue, HideTime);

		MC.ChildSetNum("NameFieldContainer.NameField", "_y", (GetLanguage() == "JPN" ? -15 :-12));

		//override if captured as split status may record needing augments etc
		//override if dead as split status may record needing augments etc
		if (Unit.bCaptured)
		{
			m_StrStatus = Unit.ChosenCaptorRef.ObjectID > 0 ? m_StrStatusMIAChosen : m_StrStatusMIA;
			i_eState = eUIState_Warning;
		}
		else if (Unit.IsDead())
		{
			m_StrStatus = WasUnitSpark(Unit.GetMyTemplate().DataName) ? (Unit.bBodyRecovered ? m_StrStatusDIABody : m_StrStatusDIA) : (Unit.bBodyRecovered ? m_StrStatusKIABody : m_StrStatusKIA) ;
			i_eState = Unit.bBodyRecovered ? eUIState_Warning2 : eUIState_Bad ;
		}
		else
		{
			//save this for focus switching
			m_StrStatus = Status;
			i_eState = eState;
		}
	}
}

simulated function bool WasUnitSpark(name TemplateName)
{
	if (TemplateName == 'SparkSoldier' || TemplateName == 'LostTowersSpark')
	{
		return true;
	}

	return false;
}

//gets a colour for the icon based on conditions
simulated function string GetIconColour(XComGameState_Unit Unit)
{
	local string Colour;
	local name TemplateName;

	TemplateName = Unit.GetMyTemplateName();

	//set default to red
	Colour = "BF1E2E"; // eUIState_Bad;

	if (bNeedsAttention)
	{
		 Colour = "E69831"; //eUIState_Warning2;
	}
	else if((Unit.IsSoldier() || TemplateName == 'StrategyCentral') )
	{
		Colour = "828282"; //grey

		if (TemplateName == 'SkirmisherSoldier') { Colour = "BF1E2E"; } //red
		if (TemplateName == 'TemplarSoldier') { Colour = "B6B3E3"; }   //psi
		if (TemplateName == 'ReaperSoldier') { Colour = "A28752"; }   //yellow
		if (TemplateName == 'SparkSoldier') { Colour = "546F6F"; }   //faded

		//if (TemplateName == 'StrategyCentral') { Colour = "ACD373"; } //ruler green
	}
	else if (Unit.IsScientist())
	{
		Colour = "27AAE1"; //Blue Science;

		if (TemplateName == 'HeadScientist') { Colour = "5CD16C"; } //dark Green
	}
	else if (Unit.IsEngineer())
	{
		Colour = "F7941E"; //Orange Engineer;

		if (TemplateName == 'HeadEngineer') { Colour = "53B45E"; } //light Green
	}

	return "0x" $ Colour;
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
