#include <sourcemod>
#include <clientprefs>
#include <smlib>

new Handle:cVarGravity;
new Handle:cVarVersion;
new Handle:cVarMinGravity;
new Handle:cVarMaxGravity;

new Float:minGravity = 150.0;
new Float:maxGravity = 800.0;

#define COOKIE_GRAVITY "PlayerGrav-Grav"

new Handle:cookieGravity;


#define VERSION "0.98b"

public Plugin:myinfo = {
	name = "sm_player_grav",
	author = "[foo] bar",
	description = "Let players set their own gravity",
	url = "http://github.com/foobarhl/sm_player_grav",
	version = VERSION
};

new Float:playerGravities[MAXPLAYERS+1];

public OnPluginStart()
{
	cVarVersion = CreateConVar("sm_player_grav_version", VERSION, "Player Gravity Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	SetConVarString(cVarVersion, VERSION);	

	cVarGravity = FindConVar("sv_gravity");
	cookieGravity  = RegClientCookie(COOKIE_GRAVITY, "PlayerGravity: Persistent gravity you want to use", CookieAccess_Private);

	cVarMinGravity = CreateConVar("sm_player_grav_mingravity", "150.0", "Minimum gravity a player can set");
	cVarMaxGravity = CreateConVar("sm_player_grav_maxgravity", "800.0", "Maximum gravity a player can set");

        RegConsoleCmd("grav", Command_SetGravity, "Set your Gravity");
	AutoExecConfig(true);
}

public OnConfigsExecuted()
{
	minGravity = GetConVarFloat(cVarMinGravity);
	maxGravity = GetConVarFloat(cVarMaxGravity);	
}

public OnClientCookiesCached(client)
{
	loadPlayerSettings(client);
}

public OnClientPostAdminCheck(client)
{
	loadPlayerSettings(client);
}


loadPlayerSettings(client)
{
	playerGravities[client] = loadCookieOrDefFloat(client, cookieGravity, 1.0);
	SetGravity(client, playerGravities[client]);
}

SetGravity(client, Float:setGravity)
{
	new String:safeGravity[7];

	SetEntityGravity(client, setGravity);
	FloatToString(setGravity, safeGravity, sizeof(safeGravity));
	SetClientCookie(client, cookieGravity, safeGravity);
	playerGravities[client] = setGravity;

	Client_PrintToChat(client, true, "[{G}Player Gravity{N}] Your gravity has been set to %0.0f", GetConVarFloat(cVarGravity) * setGravity); 
	PrintToServer("Client %d set their gravity to %f / %f", client, setGravity, setGravity);
}



public Action:Command_SetGravity(client,args)
{
	new offset = FindDataMapOffs(client, "m_flGravity");
	new Float:temp = GetEntDataFloat(client, offset);

	if(GetCmdArgs()>0){
		new String:arg[20];
		new Float:grav;
		GetCmdArg(1, arg, sizeof(arg));
		if(StrEqual(arg, "reset", false)){
			grav = GetConVarFloat(cVarGravity);
		} else {
			grav = StringToFloat(arg);
		}

		if(grav>=minGravity && grav <= maxGravity ) {
			new Float:setGravity =  grav / GetConVarFloat(cVarGravity);


			SetGravity(client, setGravity);


		} else {
			Client_PrintToChat(client, true, "[{G}Player Gravity{N}] Specify an amount between %0.2f and %0.25f", minGravity, maxGravity);
		}
	} else {
		
		Client_PrintToChat(client, true, "[{G}]Player Gravity{N}] Your Current Gravity: {G}%0.2f{N}\n   To change use: {G}!grav <%0.2f - %0.2f>{O} or {G}!grav reset{O}", (temp == 0.0 ? GetConVarFloat(cVarGravity) : GetConVarFloat(cVarGravity) * temp), minGravity, maxGravity);
	}

	return Plugin_Handled;
}



Float:loadCookieOrDefFloat(client, Handle:cookie, Float:defaultValue)		// From damagesound.sp by Berni et al
{
	new String:buffer[64];
	
	if(AreClientCookiesCached(client)==false){
		return defaultValue;		
	}
	GetClientCookie(client, cookie, buffer, sizeof(buffer));
	
	if(!StrEqual(buffer, "")){
		
		return StringToFloat(buffer);
	}
	else {
		
		return defaultValue;
	}
}