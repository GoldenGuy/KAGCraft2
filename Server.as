
#define SERVER_ONLY

#include "Debug.as"
#include "World.as"
#include "Vec3f.as"

World@ world;

void onInit(CRules@ this)
{
	Debug("Server init");

	InitBlocks();

	World temp;
	temp.GenerateMap();
	if(isClient()) this.set("world", @temp);
	@world = @temp;
}

void onTick(CRules@ this)
{
	
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	Debug("Command: "+cmd+" : "+this.getNameFromCommandID(cmd), 1);
	if(cmd == this.getCommandID("C_RequestMap"))
	{
		if(isClient())
		{
			Debug("Localhost, ignore.");
			//this.get("Blocks", @Blocks);
			this.SendCommand(this.getCommandID("S_SendMap"), CBitStream(), true);
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
		Debug("Creating player blob.");
		blob.server_SetPlayer(player);
	}
}

void onPlayerLeave(CRules@ this, CPlayer@ player)
{
	CBlob@ blob = player.getBlob();
	if(blob !is null)
	{
		Debug("Removing player blob.");
		blob.server_Die();
	}
}