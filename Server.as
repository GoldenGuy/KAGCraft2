
#define SERVER_ONLY

#include "World.as"
#include "Vec3f.as"

World world;

void onInit(CRules@ this)
{
	if(isClient()) error("egg");
	debug("Server init");
	world.GenerateMap();
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
			CBitStream params_;
			world.Serialize(@params_);
			this.SendCommand(this.getCommandID("S_SendMap"), params_, true);
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