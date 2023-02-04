// This is an Unreal Script

class SquadScreen extends UIPersonnel;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, option name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	class'UIUtilities'.static.DisplayUI3D(DisplayTag, CameraTag, OverrideInterpTime != -1 ? OverrideInterpTime : `HQINTERPTIME);

	UpdateNavHelp();

}



simulated function UpdateNavHelp()
{
	local UINavigationHelp NavHelp;
	local int i;

	NavHelp = `HQPRES.m_kAvengerHUD.NavHelp;

	//CANT call super as it doesn't get the right order
	//super.UpdateNavHelp();

	NavHelp.ClearButtonHelp();
	NavHelp.bIsVerticalHelp = `ISCONTROLLERACTIVE; //Stack LeftSide Help if Controller

	NavHelp.AddBackButton(OnCancel);	// controller[B]
	NavHelp.AddSelectNavHelp(); 		// controller[A]

	if(HQState.IsObjectiveCompleted('T0_M2_WelcomeToArmory'))
	{
		// Don't allow jumping to the geoscape from the armory in the tutorial or when coming from squad select
		if (class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T0_M7_WelcomeToGeoscape') != eObjectiveState_InProgress && !`SCREENSTACK.IsInStack(class'UISquadSelect'))
		{
			NavHelp.AddGeoscapeButton();	// controller[Y]
		}
	}

	// controller[X] and [D-Pad] for only if controller on
	if( `ISCONTROLLERACTIVE )
	{
		NavHelp.AddLeftHelp(m_strToggleSort, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_X_SQUARE);
		NavHelp.AddLeftHelp(m_strChangeColumn, class'UIUtilities_Input'.const.ICON_DPAD_HORIZONTAL); //bsg-crobinson (5.15.17): Add change column icon

		NavHelp.AddCenterHelp( m_strTabNavHelp, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_LBRB_L1R1);
	}
	else // ... for mouse .. if( Movie.IsMouseActive())
	{
		NavHelp.SetButtonType("XComButtonIconPC");
		i = eButtonIconPC_Prev_Soldier;
		NavHelp.AddCenterHelp( string(i), "", PrevBestiary, false, m_strTabNavHelp);
		i = eButtonIconPC_Next_Soldier; 
		NavHelp.AddCenterHelp( string(i), "", NextBestiary, false, m_strTabNavHelp);
		NavHelp.SetButtonType("");
	}

}

