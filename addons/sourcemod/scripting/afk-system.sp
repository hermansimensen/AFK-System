#define DEBUG

#define PLUGIN_NAME           "AFK System"
#define PLUGIN_AUTHOR         "carnifex"
#define PLUGIN_DESCRIPTION    "Manages inactive players and timer states"
#define PLUGIN_VERSION        "1.0"
#define PLUGIN_URL            "https://github.com/hermansimensen/AFK-System"

#include <sourcemod>
#include <sdktools>
#include <shavit>
#include <cstrike>

#pragma semicolon 1

ConVar gCV_PunishmentType;
ConVar gCV_AFKTime;
ConVar gCV_TimeToWait;
ConVar gCV_UpdateInterval;
ConVar gCV_SaveTimerState;

int g_iTimesChecked[MAXPLAYERS + 1];
float g_fAngles[MAXPLAYERS + 1][3];
float g_fPos[MAXPLAYERS + 1][3];
bool g_bIsAFK[MAXPLAYERS + 1];
timer_snapshot_t g_hTimerSnapshot[MAXPLAYERS + 1]; 
bool g_bBeingChecked[MAXPLAYERS + 1];



public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public void OnPluginStart()
{
	gCV_PunishmentType = CreateConVar("afk_punishment_type", "1", "Punishment type? 1 = Move to spectators, 2 = kick", 0, true, 1.0, true, 2.0);
	gCV_AFKTime = CreateConVar("afk_time", "180", "Time in seconds for the player to be inactive users are prompted with AFK check.", 0, true, 1.0);
	gCV_TimeToWait = CreateConVar("afk_time_to_wait", "60", "Time to wait in seconds before AFK system gets enabled", 0, true, 1.0);
	gCV_UpdateInterval = CreateConVar("afk_update_interval", "10", "time in seconds between each time the plugin checks if player movement has changed", 0, true, 1.0);
	gCV_SaveTimerState = CreateConVar("afk_save_timer", "1", "Allow players  to resume pre-afk timer state?", 0, true, 0.0, true, 1.0);
	
	AutoExecConfig();
	
	HookEvent("player_spawn", SpawnEvent);
}

public Action SpawnEvent(Handle event, const char[] name, bool dontBroadcast)
{
    new client_id = GetEventInt(event, "userid");
    new client = GetClientOfUserId(client_id);

    if(g_bIsAFK[client])
   	{
   		
   		if(gCV_SaveTimerState.BoolValue)
   		{
   			OpenLoadSnapMenu(client);
   			g_bIsAFK[client] = false;
   			g_bBeingChecked[client] = false;
   		}
   	}
    
}



public OnMapStart()
{
	CreateTimer(gCV_TimeToWait.FloatValue, Timer_StartAFKSystem, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void OnClientPutInServer(int client)
{
	g_iTimesChecked[client] = 0;
	g_bIsAFK[client] = false;
	Shavit_SaveSnapshot(client, g_hTimerSnapshot[client]);
	g_bBeingChecked[client] = false;
}

public void OnClientDisconnect(int client)
{
	g_fPos[client][0] = 0.0;
	g_fPos[client][1] = 0.0;
	g_fPos[client][2] = 0.0;
}

public OpenLoadSnapMenu(int client)
{
	Menu menu = new Menu(Menu_LoadSnap);
	menu.SetTitle("Load pre-afk timer snapshot?");
	menu.AddItem("yes", "Yes.");
	menu.AddItem("no", "No.");
	
	menu.ExitButton = false;
	menu.Display(client, 30);
}

public int Menu_LoadSnap(Menu menu, MenuAction action, int client, int param2)	
{	
	
	if(action == MenuAction_Select)	
	{	
		char sInfo[32];	
		menu.GetItem(param2, sInfo, sizeof(sInfo));	
			
		float vel[3];
		vel[0] = 0.0;
		vel[1] = 0.0;
		vel[2] = 0.0;
		
		if(StrEqual(sInfo, "yes"))	
		{
			TeleportEntity(client, g_fPos[client], g_fAngles[client], vel);
			Shavit_LoadSnapshot(client, g_hTimerSnapshot[client]);
			g_bIsAFK[client] = false;
		}
		else if(StrEqual(sInfo, "no"))
		{
			Shavit_SaveSnapshot(client, g_hTimerSnapshot[client]);
			g_bIsAFK[client] = false;
		}
	}	
	
	if(action & MenuAction_End)	
	{	
		delete menu;	
	}	
	return 0;	
}


public Action Timer_StartAFKSystem(Handle timer)
{
	CreateTimer(gCV_UpdateInterval.FloatValue, Timer_CheckAFK, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_CheckAFK(Handle timer)
{
	for(int i = 1; i < MAXPLAYERS; i++)
	{
		if(IsClientConnected(i))
		{
			if(!IsFakeClient(i) && !IsClientObserver(i))
			{
				if(g_iTimesChecked[i]*gCV_UpdateInterval.FloatValue <= gCV_AFKTime.FloatValue)
				{
					float angles[3];
					GetClientEyeAngles(i, angles);
					
					
					for(int count = 0; count <= 1; count++)
					{
						if(g_fAngles[i][count] == angles[count])
						{
							//no update, increase timeschecked
							g_iTimesChecked[i]++;
						} else 
						{
							g_fAngles[i][count] = angles[count];
							//since we moved, we reset the timer
							g_iTimesChecked[i] = 0;
						}
					}
				}
				else 
				{
					float angles[3];
					GetClientEyeAngles(i, angles);
					
					for(int count = 0; count <= 1; count++)
					{
						if(!(g_fAngles[i][count] == angles[count]))
						{
							//user no longer afk
							g_iTimesChecked[i] = 0;
						} else 
						{
							//User probably afk
							if(!g_bBeingChecked[i])
							{
								OpenAFKMenu(i);
								g_bBeingChecked[i] = true;
							}
							
						}
					}
					
					
				}
			}
		}
		
	}
	return Plugin_Continue;
}

public void OpenAFKMenu(int client)
{
	Menu menu = new Menu(AFKMenu_Handler);
	menu.SetTitle("Are you still there? (AFK Checker)");
	
	menu.AddItem("yes", "Yes.");
	menu.ExitButton = false;
	menu.Display(client, 30);
}

public int AFKMenu_Handler(Menu menu, MenuAction action, int client, int param2)	
{	
	
	if(action == MenuAction_Select)	
	{	
		char sInfo[32];	
		menu.GetItem(param2, sInfo, sizeof(sInfo));	
			
		if(StrEqual(sInfo, "yes"))	
		{
			g_iTimesChecked[client] = 0;
			g_bBeingChecked[client] = false;
		}
	}	
	
	if(action == MenuAction_Cancel)
	{
		if(param2 == MenuCancel_Timeout)
		{
			//user fails to verify activity. Kick or change to specs
			if(gCV_PunishmentType.IntValue == 1)
			{
				float pos[3];	
				
				GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
				
				for(int i = 0; i < 3; i++)
				{
					g_fPos[client][i] = pos[i];
				}
				
				Shavit_SaveSnapshot(client, g_hTimerSnapshot[client]);
				ChangeClientTeam(client, CS_TEAM_SPECTATOR);
				g_bIsAFK[client] = true;
			}
			else
			{
				KickClient(client, "AFK");
			}
		}
	}
	
	if(action & MenuAction_End)	
	{	
		delete menu;	
	}	
	return 0;	
}

