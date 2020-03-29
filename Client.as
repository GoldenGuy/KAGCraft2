
#define CLIENT_ONLY

#include "Debug.as"
#include "World.as"
#include "Vec3f.as"
#include "ClientLoading.as"
#include "FrameTime.as"
#include "Camera.as"
#include "Player.as"

World@ world;
Camera@ cam;
Player player;
int[] chunks_to_render;

void onInit(CRules@ this)
{
	Debug("Client init");
	Texture::createFromFile("Default_Textures", "Textures/Blocks.png");
	InitBlocks();

	if(this.exists("world")) this.get("world", @world);
	else
	{
		World _world;
		@world = @_world;
	}
}

void onTick(CRules@ this)
{
	this.set_f32("interGameTime", getGameTime());
	this.set_f32("interFrameTime", 0);
	if(isLoading(this))
	{
		return;
	}
	else
	{
		// game here
	}
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	Debug("Client.as - Command: "+cmd+" : "+this.getNameFromCommandID(cmd));
	if(cmd == this.getCommandID("S_SendMap"))
	{
		world.UnSerialize(params);
		map_ready = true;
	}
}

void getChunksToRender()
{

}

void Render(int id)
{
	CRules@ rules = getRules();
	rules.set_f32("interFrameTime", Maths::Clamp01(rules.get_f32("interFrameTime")+getRenderApproximateCorrectionFactor()));
	rules.add_f32("interGameTime", getRenderApproximateCorrectionFactor());
}