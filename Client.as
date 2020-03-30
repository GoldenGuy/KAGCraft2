
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

f32 dir_x = 0.01f;
f32 dir_y = 0.01f;
float sensitivity = 0.16;

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
		player.Update();
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

float[] model;

void Render(int id)
{
	CRules@ rules = getRules();
	rules.set_f32("interFrameTime", Maths::Clamp01(rules.get_f32("interFrameTime")+getRenderApproximateCorrectionFactor()));
	rules.add_f32("interGameTime", getRenderApproximateCorrectionFactor());

	Render::ClearZ();
	Render::SetZBuffer(true, true);
	Render::SetAlphaBlend(true);
	Render::SetBackfaceCull(false);
	Render::SetTransformWorldspace();
	
	cam.render_update();
	Matrix::MakeIdentity(model);
	Render::SetTransform(model, cam.view, cam.projection);

	Vertex[] verts = {
		Vertex(0, 0, 0, 0, 1, color_white),
		Vertex(0, 0, map_width, 0, 0, color_white),
		Vertex(map_depth,	0, map_width,	1, 0, color_white),
		Vertex(map_depth,	0, 0, 1, 1, color_white)
	};

	Render::RawQuads("Blocks.png", verts);
}