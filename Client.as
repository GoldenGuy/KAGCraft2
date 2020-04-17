
#define CLIENT_ONLY

#include "Debug.as"
#include "World.as"
#include "Tree.as"
#include "Vec3f.as"
#include "ClientLoading.as"
#include "FrameTime.as"
#include "Raycast.as"
#include "Camera.as"
#include "Player.as"

float sensitivity = 0.16;

World@ world;
Camera@ cam;
Player player;

void onInit(CRules@ this)
{
	Debug("Client init");
	Texture::createFromFile("Default_Textures", "Textures/Blocks_Jenny.png");
	InitBlocks();

	if(this.exists("world"))
	{
		this.get("world", @world);
	}
	else
	{
		World _world;
		@world = @_world;
		world.ClientSetUp();
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
		player.Update();
		tree.Check();
		//print("size: "+chunks_to_render.size());
	}
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	Debug("Command: "+cmd+" : "+this.getNameFromCommandID(cmd), 1);
	if(cmd == this.getCommandID("S_SendMap"))
	{
		if(params.Length() > 40)
		{
			//CBitStream temp;
			//temp = params;
			//print("temp len: "+temp.Length());
			ready_unser = true;
			@map_packet = @params;
			//map_packets.push_back(params);
			//world.UnSerialize(@params, got_packets);
			//got_packets++;
		}
	}
}

float[] model;

void Render(int id)
{
	CRules@ rules = getRules();
	rules.set_f32("interFrameTime", Maths::Clamp01(rules.get_f32("interFrameTime")+getRenderApproximateCorrectionFactor()));
	rules.add_f32("interGameTime", getRenderApproximateCorrectionFactor());

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

	Render::ClearZ();
	Render::SetZBuffer(true, true);
	Render::SetAlphaBlend(false);
	Render::SetBackfaceCull(true);

	Render::RawQuads("Blocks.png", verts);

	if(!getControls().isKeyPressed(KEY_KEY_Q))
	{
		int generated = 0;
		for(int i = 0; i < chunks_to_render.size(); i++)
		{
			Chunk@ chunk = chunks_to_render[i];
			if(chunk.rebuild)
			{
				if(generated < max_generate)
				{
					chunk.GenerateMesh();
					generated++;
				}
			}
			//else
			{
				chunks_to_render[i].Render();
			}
		}
	}

	GUI::SetFont("menu");
	GUI::DrawShadowedText("Pos: "+player.pos.IntString(), Vec2f(20,20), color_white);
	GUI::DrawShadowedText("Vel: "+player.vel.FloatString(), Vec2f(20,40), color_white);
	GUI::DrawShadowedText("Ang: "+player.look_dir.FloatString(), Vec2f(20,60), color_white);

	GUI::DrawShadowedText("dir_x: "+player.dir_x, Vec2f(20,80), color_white);
}

int max_generate = 3;