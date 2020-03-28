
#define CLIENT_ONLY

#include "World.as"
#include "Vec3f.as"

World world;

void onInit(CRules@ this)
{
	Texture::createFromFile("Default_Textures", "Textures/Blocks.png");
	debug("Client init");
	InitBlocks();
}

bool ask_map = false;
bool map_ready = false;
bool map_renderable = false;

void onTick(CRules@ this)
{
	if(getGameTime() > 1 && !ask_map)
	{
		debug("Asking for map.");
		this.SendCommand(this.getCommandID("C_RequestMap"), CBitStream(), false);
		ask_map = true;
		return;
	}
	if(!map_ready) return;
	else if(!map_renderable)
	{

	}
	else
	{
		// game here
	}
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	debug("Client.as - Command: "+cmd+" : "+this.getNameFromCommandID(cmd));
	if(cmd == this.getCommandID("S_SendMap"))
	{
		world.UnSerialize(params);
		map_ready = true;
	}
}