
#define CLIENT_ONLY

#include "Debug.as"
#include "World.as"
#include "Tree.as"
#include "Vec3f.as"
#include "ClientLoading.as"
#include "FrameTime.as"
#include "Camera.as"
#include "Player.as"

float sensitivity = 0.16;

World@ world;
Camera@ cam;
Player player;

void onInit(CRules@ this)
{
	Debug("Client init");
	Texture::createFromFile("Default_Textures", "Textures/Blocks.png");
	InitBlocks();

	if(this.exists("world"))
	{
		this.get("world", @world);
	}
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
		player.Update();
		tree.Check();
		//clearChunks();
		//getChunksToRender();
		print("size: "+chunks_to_render.size());
	}
}

/*Chunk@[] chunks_to_render;

void clearChunks()
{
	//for(int i = 0; i < chunks_to_render.size(); i++)
	//{
	//	Chunk@ temp;
	//	@temp = @chunks_to_render[i];
	//	//print("chunk: "+temp.x+","+temp.y+","+temp.z);
	//	temp.visible = false;
	//}
	world.clearVisibility();
	chunks_to_render.clear();
}

Vec3f look_dir;

void getChunksToRender()
{
	Vec3f initial_pos = player.pos + Vec3f(chunk_width/2, chunk_height/2, chunk_depth/2);
	initial_pos = Vec3f(int(initial_pos.x/chunk_width), int(initial_pos.y/chunk_height), int(initial_pos.z/chunk_depth));

	Chunk@ temp = world.getChunk(initial_pos.x, initial_pos.y, initial_pos.z);
	if(temp !is null)
	{
		//temp.visible = true;
		//print("size: "+temp.mesh.size());
		temp.SetVisible();
		if(temp.rebuild) temp.GenerateMesh();
		chunks_to_render.push_back(@temp);
	}

	look_dir = Vec3f(	int(Maths::Sin((player.dir_x)*Maths::Pi/180.0f)*Maths::Cos(player.dir_y*Maths::Pi/180.0f)+0.1f),
							int(Maths::Sin(player.dir_y*Maths::Pi/180.0f)+0.1f),
							int(Maths::Cos((player.dir_x)*Maths::Pi/180.0f)*Maths::Cos(player.dir_y*Maths::Pi/180.0f)+0.1f));

	addChunk(initial_pos+look_dir);

	addChunk(initial_pos+Vec3f(1,0,0));
	addChunk(initial_pos+Vec3f(0,1,0));
	addChunk(initial_pos+Vec3f(0,0,1));
	addChunk(initial_pos+Vec3f(-1,0,0));
	addChunk(initial_pos+Vec3f(0,-1,0));
	addChunk(initial_pos+Vec3f(0,0,-1));
}

void addChunk(Vec3f pos)
{
	//print("----------------------------pos: "+pos.x+","+pos.y+","+pos.z);
	if(chunks_to_render.size() > 64) return;//{print("------------size over."); return;}
	if(!world.inChunkBounds(pos.x, pos.y, pos.z)) return;//{print("------------not in bounds."); return;}
	Chunk@ temp = world.getChunk(pos.x, pos.y, pos.z);
	if(temp is null) return;//{print("------------null."); return;}
	if(temp.visible) return;//{print("------------visible already."); return;}

	Vec3f point = Vec3f(temp.world_x+chunk_width/2,temp.world_y+chunk_height/2,temp.world_z+chunk_depth/2)-cam.pos;
	if(point.Length() > 30) return;
	//point.Print();
	if(cam.frustum.ContainsSphere(point, 12))
	{
		//print("------------added.");
		temp.visible = true;
		if(temp.rebuild) temp.GenerateMesh();
		if(!temp.empty) chunks_to_render.push_back(@temp);

		addChunk(pos+look_dir);
		
		addChunk(pos+Vec3f(1,0,0));
		addChunk(pos+Vec3f(0,1,0));
		addChunk(pos+Vec3f(0,0,1));
		addChunk(pos+Vec3f(-1,0,0));
		addChunk(pos+Vec3f(0,-1,0));
		addChunk(pos+Vec3f(0,0,-1));
	}
	//else print("------------not in frustum.");
}*/

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	Debug("Command: "+cmd+" : "+this.getNameFromCommandID(cmd), 1);
	if(cmd == this.getCommandID("S_SendMap"))
	{
		if(params.Length() > 90) world.UnSerialize(@params);
		map_ready = true;
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
	Render::SetZBuffer(true, false);
	Render::SetAlphaBlend(false);
	Render::SetBackfaceCull(true);

	Render::RawQuads("Blocks.png", verts);

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
		else
		{
			chunks_to_render[i].Render();
		}
	}
}

int max_generate = 3;