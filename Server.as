
#define SERVER_ONLY

#include "World.as"
#include "Vec3f.as"

World@ world;

void onInit(CRules@ this)
{
	debug("Server init");
	World _world;
	_world.GenerateMap();
	if(isClient()) this.set("world", @_world);
	@world = @_world;
}

void onTick(CRules@ this)
{
	
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	debug("Server.as - Command: "+cmd+" : "+this.getNameFromCommandID(cmd));
	if(cmd == this.getCommandID("C_RequestMap"))
	{
		if(isClient())
		{
			debug("Localhost, ignore.");
			return;
		}
		else
		{
			//CPlayer@ sender = getNet().getActiveCommandPlayer();
			CBitStream _params;
			world.Serialize(@_params);
			this.SendCommand(this.getCommandID("S_SendMap"), _params, true);
		}
	}
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	CBlob@ blob = server_CreateBlob("husk");
	if(blob !is null)
	{
		debug("Creating player blob.");
		blob.server_SetPlayer(player);
	}
}

void onPlayerLeave(CRules@ this, CPlayer@ player)
{
	CBlob@ blob = player.getBlob();
	if(blob !is null)
	{
		debug("Removing player blob.");
		blob.server_Die();
	}
}