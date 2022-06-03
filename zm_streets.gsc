#using scripts\codescripts\struct;

#using scripts\shared\array_shared;
#using scripts\shared\callbacks_shared;
#using scripts\shared\clientfield_shared;
#using scripts\shared\compass;
#using scripts\shared\exploder_shared;
#using scripts\shared\flag_shared;
#using scripts\shared\laststand_shared;
#using scripts\shared\math_shared;
#using scripts\shared\scene_shared;
#using scripts\shared\util_shared;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;

#insert scripts\zm\_zm_utility.gsh;

#using scripts\zm\_load;
#using scripts\zm\_zm;
#using scripts\zm\_zm_audio;
#using scripts\zm\_zm_powerups;
#using scripts\zm\_zm_utility;
#using scripts\zm\_zm_weapons;
#using scripts\zm\_zm_zonemgr;

#using scripts\shared\ai\zombie_utility;

//Perks
#using scripts\zm\_zm_pack_a_punch;
#using scripts\zm\_zm_pack_a_punch_util;
#using scripts\zm\_zm_perk_additionalprimaryweapon;
#using scripts\zm\_zm_perk_doubletap2;
#using scripts\zm\_zm_perk_deadshot;
#using scripts\zm\_zm_perk_juggernaut;
#using scripts\zm\_zm_perk_quick_revive;
#using scripts\zm\_zm_perk_sleight_of_hand;
#using scripts\zm\_zm_perk_staminup;

//Powerups
#using scripts\zm\_zm_powerup_double_points;
#using scripts\zm\_zm_powerup_carpenter;
#using scripts\zm\_zm_powerup_fire_sale;
#using scripts\zm\_zm_powerup_free_perk;
#using scripts\zm\_zm_powerup_full_ammo;
#using scripts\zm\_zm_powerup_insta_kill;
#using scripts\zm\_zm_powerup_nuke;
//#using scripts\zm\_zm_powerup_weapon_minigun;

//Traps
#using scripts\zm\_zm_trap_electric;

#using scripts\zm\zm_usermap;
#using scripts\_NSZ\nsz_buyable_ending;
#define PAP_WEAPON_KNUCKLE_CRACK		"zombie_knuckle_crack"

//*****************************************************************************
// MAIN
//*****************************************************************************

function main()
{
	level thread buyable_ending::init(); 
	level thread set_perk_limit(10);  // This sets the perk limit to 10
	zm_usermap::main();
	
	level._zombie_custom_add_weapons =&custom_add_weapons;
	
	//Setup the levels Zombie Zone Volumes
	level.zones = [];
	level.zone_manager_init_func =&usermap_test_zone_init;
	init_zones[0] = "start_zone";
	level thread zm_zonemgr::manage_zones( init_zones );

	level.pathdist_type = PATHDIST_ORIGINAL;
	

	_INIT_ZCOUNTER();
	thread buildableinit();


}

function checkForPower()
{
 level util::set_lighting_state(0); /* set lighting state to [1] in Radiant (by default) */
 level waittill("power_on");
 level util::set_lighting_state(1); /* set lighting state to [2] in Radiant (turn lights on) */
}

function usermap_test_zone_init()
{
	zm_zonemgr::add_adjacent_zone("start_zone", "parking_zone", "enter_parking_zone");
	zm_zonemgr::add_adjacent_zone("parking_zone", "warehouse_zone", "enter_warehouse_zone");
	zm_zonemgr::add_adjacent_zone("parking_zone", "lobby_zone", "enter_lobby_zone");
	zm_zonemgr::add_adjacent_zone("lobby_zone", "warehouse_zone", "enter_warehouse_zone");
	zm_zonemgr::add_adjacent_zone("warehouse_zone", "warden_zone", "enter_warden_zone");
	zm_zonemgr::add_adjacent_zone("warehouse_zone", "upstairs_zone", "enter_upstairs_zone");
	zm_zonemgr::add_adjacent_zone("parking_zone", "clerk_zone", "enter_clerk_zone");
	zm_zonemgr::add_adjacent_zone("start_zone", "q_zone", "enter_q_zone");
	zm_zonemgr::add_adjacent_zone("q_zone", "elobby_zone", "enter_elobby_zone");
	zm_zonemgr::add_adjacent_zone("elobby_zone", "generator_zone", "enter_generator_zone");
	zm_zonemgr::add_adjacent_zone("generator_zone", "office_zone", "enter_office_zone");
	level flag::init( "always_on" );
	level flag::set( "always_on" );
}	

function custom_add_weapons()
{
	zm_weapons::load_weapon_spec_from_table("gamedata/weapons/zm/zm_levelcommon_weapons.csv", 1);
}



function _INIT_ZCOUNTER()
{
	ZombieCounterHuds = [];
	ZombieCounterHuds["LastZombieText"] 	= "Zombie Left";
	ZombieCounterHuds["ZombieText"]			= "Zombie's Left";
	ZombieCounterHuds["LastDogText"]		= "Dog Left";
	ZombieCounterHuds["DogText"]			= "Dog's Left";
	ZombieCounterHuds["DefaultColor"]		= (1,1,1);
	ZombieCounterHuds["HighlightColor"]		= (1, 0.55, 0);
	ZombieCounterHuds["FontScale"]			= 1.5;
	ZombieCounterHuds["DisplayType"]		= 0; // 0 = Shows Total Zombies and Counts down, 1 = Shows Currently spawned zombie count

	ZombieCounterHuds["counter"] = createNewHudElement("left", "top", 2, 10, 1, 1.5);
	ZombieCounterHuds["text"] = createNewHudElement("left", "top", 2, 10, 1, 1.5);

	ZombieCounterHuds["counter"] hudRGBA(ZombieCounterHuds["DefaultColor"], 0);
	ZombieCounterHuds["text"] hudRGBA(ZombieCounterHuds["DefaultColor"], 0);

	level thread _THINK_ZCOUNTER(ZombieCounterHuds);
}

function _THINK_ZCOUNTER(hudArray)
{
	level endon("end_game");
	for(;;)
	{
		level waittill("start_of_round");
		level _ROUND_COUNTER(hudArray);
		hudArray["counter"] SetValue(0);
		hudArray["text"] thread hudMoveTo((2, 10, 0), 4);
		
		hudArray["counter"] thread hudRGBA(hudArray["DefaultColor"], 0, 1);
		hudArray["text"] SetText("End of round"); hudArray["text"] thread hudRGBA(hudArray["DefaultColor"], 0, 3);
	}
}

function _ROUND_COUNTER(hudArray)
{
	level endon("end_of_round");
	lastCount = 0;
	numberToString = "";

	hudArray["counter"] thread hudRGBA(hudArray["DefaultColor"], 1.0, 1);
	hudArray["text"] thread hudRGBA(hudArray["DefaultColor"], 1.0, 1);
	hudArray["text"] SetText(hudArray["ZombieText"]);
	if(level flag::get("dog_round"))
		hudArray["text"] SetText(hudArray["DogText"]);

	for(;;)
	{
		zm_count = (zombie_utility::get_current_zombie_count() + level.zombie_total);
		if(hudArray["DisplayType"] == 1) zm_count = zombie_utility::get_current_zombie_count();
		if(zm_count == 0) {wait(1); continue;}
		hudArray["counter"] SetValue(zm_count);
		if(lastCount != zm_count)
		{
			lastCount = zm_count;
			numberToString = "" + zm_count;
			hudArray["text"] thread hudMoveTo((10 + (4 * numberToString.Size), 10, 0), 4);
			if(zm_count == 1 && !level flag::get("dog_round")) hudArray["text"] SetText(hudArray["LastZombieText"]);
			else if(zm_count == 1 && level flag::get("dog_round")) hudArray["text"] SetText(hudArray["LastDogText"]);

			hudArray["counter"].color = hudArray["HighlightColor"]; hudArray["counter"].fontscale = (hudArray["FontScale"] + 0.5);
			hudArray["text"].color = hudArray["HighlightColor"]; hudArray["text"].fontscale = (hudArray["FontScale"] + 0.5);
			hudArray["counter"] thread hudRGBA(hudArray["DefaultColor"], 1, 0.5); hudArray["counter"] thread hudFontScale(hudArray["FontScale"], 0.5);
			hudArray["text"] thread hudRGBA(hudArray["DefaultColor"], 1, 0.5); hudArray["text"] thread hudFontScale(hudArray["FontScale"], 0.5);
		}
		wait(0.1);
	}
}

function createNewHudElement(xAlign, yAlign, posX, posY, foreground, fontScale)
{
	hud = newHudElem();
	hud.horzAlign = xAlign; hud.alignX = xAlign;
	hud.vertAlign = yAlign; hug.alignY = yAlign;
	hud.x = posX; hud.y = posY;
	hud.foreground = foreground;
	hud.fontscale = fontScale;
	return hud;
}

function hudRGBA(newColor, newAlpha, fadeTime)
{
	if(isDefined(fadeTime))
		self FadeOverTime(fadeTime);

	self.color = newColor;
	self.alpha = newAlpha;
}

function hudFontScale(newScale, fadeTime)
{
	if(isDefined(fadeTime))
		self ChangeFontScaleOverTime(fadeTime);

	self.fontscale = newScale;
}

function hudMoveTo(posVector, fadeTime) // Just because MoveOverTime doesn't always work as wanted
{
	initTime = GetTime();
	hudX = self.x;
	hudY = self.y;
	hudVector = (hudX, hudY, 0);
	while(hudVector != posVector)
	{
		time = GetTime();
		hudVector = VectorLerp(hudVector, posVector, (time - initTime) / (fadeTime * 1000));
		self.x = hudVector[0];
		self.y = hudVector[1];
		wait(0.0001);
	}
}

function buildableinit()
{
	buildTable = getEnt("powcraft_crafting_trig", "targetname");
	buildTable SetHintString("Missing parts");
	buildTable SetCursorHint("HINT_NOICON");

	level.allParts = 0;
	level.finishedCraft = 2;

	power_trigger = GetEnt("use_elec_switch", "targetname");
	power_trigger TriggerEnable( false );
	power_handle_model = GetEnt("elec_switch", "script_noteworthy");
	power_handle_model hide();
	power_clip = GetEnt("powcraft_clip_build", "targetname");
	power_clip hide();
	power_shaft_model = GetEnt("powcraft_build1", "targetname");
	power_shaft_model hide();

	level thread pick1();
	level thread pick2();
}

function pick1()
{
	pick_trig1 = getent("powcraft_pick1_trig", "targetname");
	pick_trig1 SetHintString("Press and hold &&1 to pickup part");
	pick_trig1 SetCursorHint("HINT_NOICON");
	pick_model1 = getent("powcraft_pick1", "targetname");

	while(1)
	{
		pick_trig1 waittill("trigger", player);

		playfx(level._effect["powerup_grabbed"] ,GetEnt("powcraft_pick1","targetname").origin);

		level.allParts++;

		//IPrintLnBold(level.allParts);

		thread build();
 
		break;
	}

	pick_trig1 delete();
	pick_model1 delete();
}

function pick2()
{
	pick_trig2 = getent("powcraft_pick2_trig", "targetname");
	pick_trig2 SetHintString("Press and hold &&1 to pickup part");
	pick_trig2 SetCursorHint("HINT_NOICON");
	pick_model2 = getent("powcraft_pick2", "targetname");

	while(1)
	{
		pick_trig2 waittill("trigger", player);
 
		playfx(level._effect["powerup_grabbed"] ,GetEnt("powcraft_pick2","targetname").origin);

		level.allParts++;

		//IPrintLnBold(level.allParts);

		thread build();

		break;
	}

	pick_trig2 delete();
	pick_model2 delete();
}

function build()
{

	while(1)
	{
		self waittill( level.allParts >= level.finishedCraft );
 
		if ( level.allParts >= level.finishedCraft )
		{
			buildTable = GetEnt("powcraft_crafting_trig", "targetname");
			buildTable SetHintString("Press and hold &&1 to craft");
			buildTable SetCursorHint("HINT_NOICON");
			buildTable waittill("trigger", player);

			buildTable SetHintString("");

			//playfx(level._effect["powerup_grabbed"] ,GetEnt("powcraft_crafting_trig","targetname").origin);

			player thread do_knuckle_crack();

			wait(2.7);

			thread power_crafted();

			buildTable delete();
		}
		break;
	}
}

function power_crafted()
{
	power_trigger = GetEnt("use_elec_switch", "targetname");
	power_trigger TriggerEnable( true );
	playfx(level._effect["powerup_grabbed"] ,GetEnt("use_elec_switch","targetname").origin);
	power_handle_model = GetEnt("elec_switch", "script_noteworthy");
	power_handle_model show();
	power_clip = GetEnt("powcraft_clip_build", "targetname");
	power_clip show();
	power_shaft_model = GetEnt("powcraft_build1", "targetname");
	power_shaft_model show();
}

/*
		KNUCKLE CRACK SCRIPT
*/
function private do_knuckle_crack()
{
	self endon("disconnect");
	self upgrade_knuckle_crack_begin();
 
	self util::waittill_any( "fake_death", "death", "player_downed", "weapon_change_complete" );
 
	self upgrade_knuckle_crack_end();
 
}


//	Switch to the knuckles
//
function private upgrade_knuckle_crack_begin()
{
	self zm_utility::increment_is_drinking();
 
	self zm_utility::disable_player_move_states(true);

	primaries = self GetWeaponsListPrimaries();

	original_weapon = self GetCurrentWeapon();
	weapon = GetWeapon( PAP_WEAPON_KNUCKLE_CRACK );
 
 

	self GiveWeapon( weapon );
	self SwitchToWeapon( weapon );
}

//	Anim has ended, now switch back to something
//
function private upgrade_knuckle_crack_end()
{
	self zm_utility::enable_player_move_states();
 
	weapon = GetWeapon( PAP_WEAPON_KNUCKLE_CRACK );

	// TODO: race condition?
	if ( self laststand::player_is_in_laststand() || IS_TRUE( self.intermission ) )
	{
		self TakeWeapon(weapon);
		return;
	}

	self zm_utility::decrement_is_drinking();

	self TakeWeapon(weapon);
	primaries = self GetWeaponsListPrimaries();
	if( IS_DRINKING(self.is_drinking) )
	{
		return;
	}
	else
	{
		self zm_weapons::switch_back_primary_weapon();
	}
}
/*
						KNUCKLE CRACK SCRIPT END
*/



function set_perk_limit(num)
{
	wait( 30 ); 
	level.perk_purchase_limit = num;
}


