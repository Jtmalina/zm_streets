#using scripts\zm\_zm;
#using scripts\codescripts\struct;

#using scripts\shared\aat_shared;
#using scripts\shared\ai_puppeteer_shared;
#using scripts\shared\archetype_shared\archetype_shared;
#using scripts\shared\array_shared;
#using scripts\shared\callbacks_shared;
#using scripts\shared\clientfield_shared;
#using scripts\shared\demo_shared;
#using scripts\shared\flag_shared;
#using scripts\shared\hud_util_shared;
#using scripts\shared\laststand_shared;
#using scripts\shared\lui_shared;
#using scripts\shared\math_shared;
#using scripts\shared\scoreevents_shared;
#using scripts\shared\system_shared;
#using scripts\shared\util_shared;
#using scripts\shared\visionset_mgr_shared;
#using scripts\zm\gametypes\_globallogic;
#using scripts\zm\gametypes\_globallogic_vehicle;

//#using scripts\zm\_bb;

#using scripts\shared\ai\systems\gib;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;
#insert scripts\shared\ai\systems\gib.gsh;
#insert scripts\shared\archetype_shared\archetype_shared.gsh;

#using scripts\zm\gametypes\_weapons;
#using scripts\zm\gametypes\_zm_gametype;
#using scripts\zm\gametypes\_globallogic_spawn;
#using scripts\zm\gametypes\_globallogic_player;

#using scripts\zm\_util;
#using scripts\zm\_zm_attackables;
#using scripts\zm\_zm_audio;
#using scripts\zm\_zm_bgb;
#using scripts\zm\_zm_bgb_token;
#using scripts\zm\_zm_blockers;
#using scripts\zm\_zm_bot;
#using scripts\zm\_zm_daily_challenges;
#using scripts\zm\_zm_equipment;
#using scripts\zm\_zm_ffotd;
#using scripts\zm\_zm_game_module;
#using scripts\zm\_zm_hero_weapon;
#using scripts\zm\_zm_laststand;
#using scripts\zm\_zm_melee_weapon;
#using scripts\zm\_zm_perks;
#using scripts\zm\_zm_pers_upgrades;
#using scripts\zm\_zm_pers_upgrades_functions;
#using scripts\zm\_zm_pers_upgrades_system;
#using scripts\zm\_zm_placeable_mine;
#using scripts\zm\_zm_player;
#using scripts\zm\_zm_powerups;
#using scripts\zm\_zm_score;
#using scripts\zm\_zm_spawner;
#using scripts\zm\_zm_stats;
#using scripts\zm\_zm_timer;
#using scripts\zm\_zm_unitrigger;
#using scripts\zm\_zm_utility;
#using scripts\zm\_zm_weapons;
#using scripts\zm\_zm_zonemgr;
#using scripts\shared\ai_shared;

// AATs
#insert scripts\shared\aat_zm.gsh;
#using scripts\zm\aats\_zm_aat_blast_furnace;
#using scripts\zm\aats\_zm_aat_dead_wire;
#using scripts\zm\aats\_zm_aat_fire_works;
#using scripts\zm\aats\_zm_aat_thunder_wall;
#using scripts\zm\aats\_zm_aat_turned;

#using scripts\zm\craftables\_zm_craftables;

#using scripts\shared\ai\zombie_death;
#using scripts\shared\ai\zombie_utility;

#insert scripts\shared\ai\zombie.gsh;
#insert scripts\zm\_zm_laststand.gsh;
#insert scripts\zm\_zm_perks.gsh;
#insert scripts\zm\_zm_utility.gsh;

#namespace buyable_ending; 

function init()
{
	// ============ CHANGE YOUR SETTINGS BELOW ================
	level.end_game_cost = 100000; 												// This line is how much it will cost to end your game
	level.message_to_end = "Press and Hold ^3&&1^7 to Escape [Cost: "+level.end_game_cost+"]"; 	// This is the message a player will see to end the game
	level.failed_message = "You Do Not Have Enough Money";					// This the message a player will see if they dont have enough money
	level.end_game_message = "Thanks for Playing! You Have Escaped";			// This is the message the player will see at the end of the game 
	level.all_players_near_end = true; 											// Set this to false if all players do not need to be near the end game to end the game
	level.failed_all_players_message = "All Players Must Be Nearby to Escape";	// This is the message you will see if all players are not nearby the end game when activated
	// ============ CHANGE YOUR SETTINGS ABOVE ================
	main(); 
}

function main()
{
	trig = GetEnt( "end_game_trig", "targetname" ); 
	trig SetCursorHint( "HINT_NOICON" );
	trig UseTriggerRequireLookAt(); 
	cost = level.end_game_cost;

	while(1)
	{
		trig SetHintString( level.message_to_end ); 
		trig waittill( "trigger", player ); 
		if( isDefined(cost) && isDefined(player) && player.score >= cost )
		{
			if( level.all_players_near_end )
			{
				if( trig all_players_near_end() )
				{
					player zm_score::minus_to_player_score( cost );
					trig SetHintString(""); 
					end_it_now();
				}
				else
				{
					trig SetHintString( level.failed_all_players_message ); 
					wait(1); 
				}
			}
			else
			{
				player zm_score::minus_to_player_score( cost );
				trig SetHintString("");
				end_it_now();
			}
		}
		else if( isDefined(cost) && isDefined(player) && player.score < cost )
		{
			trig SetHintString( "You Do Not Have Enough Money" ); 
			wait(1); 
		}
	}
}

function all_players_near_end()
{
	players = getplayers(); 
	foreach( player in players )
	{
		if( Distance(self.origin, player.origin) > 500 )
			return false; 
	}
	return true; 
}

function end_it_now()
{
	zm::check_end_game_intermission_delay();

	setmatchflag( "game_ended", 1 );

	level clientfield::set("gameplay_started", 0);
	level clientfield::set("game_end_time", int( ( GetTime() - level.n_gameplay_start_time + 500 ) / 1000 ) );

	util::clientnotify( "zesn" );
	
	level thread zm_audio::sndMusicSystem_PlayState( "game_over" );
	
	//AYERS: Turn off ANY last stand audio at the end of the game
	players = GetPlayers();
	for ( i = 0; i < players.size; i++ )
	{
		players[i] clientfield::set( "zmbLastStand", 0 );
	}

	for ( i = 0; i < players.size; i++ )
	{	
		if ( players[i] laststand::player_is_in_laststand() )
		{
			players[i] RecordPlayerDeathZombies();
			players[i] zm_stats::increment_player_stat( "deaths" );
			players[i] zm_stats::increment_client_stat( "deaths" );
		}
		
		//clean up the revive text hud if it's active
		if( isdefined( players[i].reviveTextHud ) )
		{
			players[i].reviveTextHud destroy();
		}
	}

	StopAllRumbles();

	level.intermission = true;
	level.zombie_vars["zombie_powerup_insta_kill_time"] = 0;
	level.zombie_vars["zombie_powerup_fire_sale_time"] = 0;
	level.zombie_vars["zombie_powerup_double_points_time"] = 0;
	wait 0.1;

	game_over = [];
	survived = [];

	players = GetPlayers();

	//disabled the ingame pause menu from opening after a game ends
	setMatchFlag( "disableIngameMenu", 1 );
	foreach( player in players )
	{
		player closeInGameMenu();
		player CloseMenu( "StartMenu_Main" );
	}


	//AAR - set stat for each player (this will show the menu)
	foreach( player in players )
	{
		player setDStat( "AfterActionReportStats", "lobbyPopup", "summary" );
	}
	
	if(!isDefined(level._supress_survived_screen))
	{
		
		for( i = 0; i < players.size; i++ )
		{
			game_over[i] = NewClientHudElem( players[i] );
			survived[i] = NewClientHudElem( players[i] );
			if ( IsDefined( level.custom_game_over_hud_elem ) )
			{
				[[ level.custom_game_over_hud_elem ]]( players[i], game_over[i], survived[i] );
			}
			else
			{
				game_over[i].alignX = "center";
				game_over[i].alignY = "middle";
				game_over[i].horzAlign = "center";
				game_over[i].vertAlign = "middle";
				game_over[i].y -= 130;
				game_over[i].foreground = true;
				game_over[i].fontScale = 3;
				game_over[i].alpha = 0;
				game_over[i].color = ( 1.0, 1.0, 1.0 );
				game_over[i].hidewheninmenu = true;
				game_over[i] SetText( level.end_game_message );
	
				game_over[i] FadeOverTime( 1 );
				game_over[i].alpha = 1;
				if ( players[i] isSplitScreen() )
				{
					game_over[i].fontScale = 2;
					game_over[i].y += 40;
				}

				survived[i].alignX = "center";
				survived[i].alignY = "middle";
				survived[i].horzAlign = "center";
				survived[i].vertAlign = "middle";
				survived[i].y -= 100;
				survived[i].foreground = true;
				survived[i].fontScale = 2;
				survived[i].alpha = 0;
				survived[i].color = ( 1.0, 1.0, 1.0 );
				survived[i].hidewheninmenu = true;
				if ( players[i] isSplitScreen() )
				{
					survived[i].fontScale = 1.5;
					survived[i].y += 40;
				}
			}
	

			//OLD COUNT METHOD
			if( level.round_number < 2 )
			{
				{
					survived[i] SetText( &"ZOMBIE_SURVIVED_ROUND" );
				}
			}
			else
			{
				survived[i] SetText( &"ZOMBIE_SURVIVED_ROUNDS", level.round_number );
			}
	
			survived[i] FadeOverTime( 1 );
			survived[i].alpha = 1;
		}
	}
	

	//check to see if we are in a game module that wants to do something with PvP damage
	if(isDefined(level.custom_end_screen))
	{
		level [[level.custom_end_screen]]();
	}

	for (i = 0; i < players.size; i++)
	{
		players[i] SetClientUIVisibilityFlag( "weapon_hud_visible", 0 );
		players[i] SetClientMiniScoreboardHide( true );
		//players[i] setDStat( "AfterActionReportStats", "lobbyPopup", "summary" );

		players[i] notify( "report_bgb_consumption" );
	}

	//LUINotifyEvent( &"force_scoreboard", 0 );

	UploadStats();
	zm_stats::update_players_stats_at_match_end( players );
	zm_stats::update_global_counters_on_match_end();
	zm::upload_leaderboards();
	
	recordGameResult( "draw" );
	globallogic::recordZMEndGameComScoreEvent( "draw" );
	globallogic_player::recordActivePlayersEndGameMatchRecordStats();
	
	// Finalize Match Record
	finalizeMatchRecord();
	
	//zm_utility::play_sound_at_pos( "end_of_game", ( 0, 0, 0 ) );

	players = GetPlayers();
	foreach( player in players )
	{
		if( IsDefined( player.sessionstate ) && player.sessionstate == "spectator" )
		{
			player.sessionstate = "playing";
			player thread zm::end_game_player_was_spectator();
		}
	}
	WAIT_SERVER_FRAME;

	players = GetPlayers();

	LUINotifyEvent( &"force_scoreboard", 1, 1 );
	
	zm::intermission();

	wait( level.zombie_vars["zombie_intermission_time"] );

	// hide the gameover message
	if ( !isDefined( level._supress_survived_screen ) )
	{
		for ( i = 0; i < players.size; i++ )
		{
			survived[i] Destroy();
			game_over[i] Destroy();
		}
	}
	else
	{
		for ( i = 0; i < players.size; i++ )
		{
			if(isDefined(players[i].survived_hud ) )
				players[i].survived_hud  Destroy();
			if (isDefined( players[i].game_over_hud ) )
				players[i].game_over_hud Destroy();
		}
	}
	
	level notify( "stop_intermission" );
	array::thread_all( GetPlayers(), &player_exit_level );

	wait( 1.5 );

	players = GetPlayers();
	for ( i = 0; i < players.size; i++ )
	{
		players[i] CameraActivate( false );
	}
	
	ExitLevel( false );

	// Let's not exit the function
	wait( 666 );
}

function player_exit_level()
{
	self AllowStand( true );
	self AllowCrouch( false );
	self AllowProne( false );

	//self thread lui::screen_fade_out( 1 );
}