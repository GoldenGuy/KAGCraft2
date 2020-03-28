
#define CLIENT_ONLY

#include "World.as"
#include "Vec3f.as"

World@ world;

void onInit(CRules@ this)
{
	debug("Client init");
	Texture::createFromFile("Default_Textures", "Textures/Blocks.png");
	InitBlocks();

	if(this.exists("world")) this.get("world", @world);
	else
	{
		World _world;
		@world = @_world;
	}
}

bool ask_map = false;
bool map_ready = false;
bool map_renderable = false;
bool faces_generated = false;
int ask_map_in = 0;

void onTick(CRules@ this)
{
	if(!ask_map)
	{
		ask_map_in++;
		if(ask_map_in == 15)
		{
			if(isServer())
			{
				debug("No need to ask for map, already generated.");
				ask_map = true;
				map_ready = true;
			}
			else
			{
				debug("Asking for map.");
				this.SendCommand(this.getCommandID("C_RequestMap"), CBitStream(), true);
				ask_map = true;
			}
		}
		return;
	}
	if(!map_ready) return;
	else if(!map_renderable)
	{
		if(!faces_generated)
		{
			debug("Generating block faces.");
			world.GenerateBlockFaces();
			debug("Done.");
			faces_generated = true;
			return;
		}
		else
		{
			// mesh here
		}
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