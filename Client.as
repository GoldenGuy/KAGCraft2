
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

World@ world;

Camera@ camera;

Player@ my_player;
Player@[] other_players;

void onInit(CRules@ this)
{
	Debug("Client init");
	this.set_bool("ClientLoading", true);
	Texture::createFromFile("Block_Textures", "Textures/Blocks_Jenny.png");
	Texture::createFromFile("Sky_Texture", "Textures/SkyBox.png");
	Texture::createFromFile("DEBUG", "Textures/Debug.png");
	InitBlocks();

	Camera _camera;
	@camera = @_camera;

	if(this.exists("world"))
	{
		this.get("world", @world);
		ask_map = true;
		map_ready = true;
	}
	else
	{
		World _world;
		@world = @_world;
		world.ClientMapSetUp();
	}
}

void onTick(CRules@ this)
{
	HitBoxes.clear();
	this.set_f32("interGameTime", getGameTime());
	this.set_f32("interFrameTime", 0);
	if(isLoading(this))
	{
		this.set_bool("ClientLoading", true);
		return;
	}
	else
	{
		if(this.get_bool("ClientLoading"))
		{
			this.set_bool("ClientLoading", false);
		}
		// game here
		my_player.Update();
		if(!isServer() && getPlayersCount() > 1)
		{
			CBitStream to_send;
			my_player.Serialize(@to_send);
			this.SendCommand(this.getCommandID("C_PlayerUpdate"), to_send, false);
		}

		tree.Check();

		if(isDebug())
		{
			for(int i = 0; i < other_players.size(); i++)
			{
				Vec3f pos = other_players[i].pos;
				AABB _box(pos-Vec3f(player_radius,0,player_radius), pos+Vec3f(player_radius,player_height,player_radius));
				DrawHitbox(_box, 0x88FFFFFF);
			}

			if(hold_frustum)
			{
				for(int i = 0; i < chunks_to_render.size(); i++)
				{
					Chunk@ chunk = chunks_to_render[i];
					DrawHitbox(chunks_to_render[i].box, 0x880000FF);
				}
			}
		}
	}
}

void onCommand(CRules@ this, uint8 cmd, CBitStream@ params)
{
	Debug("Command: "+cmd+" : "+this.getNameFromCommandID(cmd), 1);
	if(cmd == this.getCommandID("S_SendMapPacket"))
	{
		ready_unser = true;
		map_packet.Clear();
		map_packet = params;
		map_packet.SetBitIndex(params.getBitIndex());
	}
	else if(cmd == this.getCommandID("S_PlayerUpdate"))
	{
		u16 size = params.read_u16();
		for(int i = 0; i < size; i++)
		{
			u16 netid = params.read_netid();
			CPlayer@ _player = getPlayerByNetworkId(netid);
			if(_player !is null && _player !is getLocalPlayer())
			{
				bool exists = false;
				for(int i = 0; i < other_players.size(); i++)
				{
					Player@ __player = other_players[i];
					if(__player.player is _player)
					{
						__player.UnSerialize(params);
						exists = true;
						break;
					}
				}
				// doesnt exists yet
				if(!exists)
				{
					Player new_player();
					new_player.pos = Vec3f(map_width/2, map_height-4, map_depth/2);
					new_player.SetPlayer(_player);
					other_players.push_back(@new_player);
				}
				
			}
			else
			{
				float temp_float = params.read_f32();
				temp_float = params.read_f32();
				temp_float = params.read_f32();
				temp_float = params.read_f32();
				temp_float = params.read_f32();
				bool temp_bool = params.read_bool();
			}
		}
	}
	else if(cmd == this.getCommandID("C_ChangeBlock"))
	{
		uint8 block = params.read_u8();
		float x = params.read_f32();
		float y = params.read_f32();
		float z = params.read_f32();

		world.map[y][z][x] = block;
    	world.UpdateBlocksAndChunks(x, y, z);
	}
	else if(cmd == this.getCommandID("C_RequestMap") || cmd == this.getCommandID("C_RequestMapPacket"))
	{
		return;
	}
}

float[] model;

void Render(int id)
{
	CRules@ rules = getRules();
	rules.set_f32("interFrameTime", Maths::Clamp01(rules.get_f32("interFrameTime")+getRenderApproximateCorrectionFactor()));
	rules.add_f32("interGameTime", getRenderApproximateCorrectionFactor());

	Render::SetTransformWorldspace();

	Render::ClearZ();
	Render::SetZBuffer(false, false);
	Render::SetAlphaBlend(false);
	Render::SetBackfaceCull(true);
	
	camera.render_update();
	Matrix::MakeIdentity(model);
	Matrix::SetTranslation(model, camera.interpolated_pos.x, camera.interpolated_pos.y, camera.interpolated_pos.z);
	Render::SetTransform(model, camera.view, camera.projection);
	Render::RawQuads("Sky_Texture", SkyBox);
	Matrix::MakeIdentity(model);
	Render::SetModelTransform(model);

	Render::SetZBuffer(true, true);

	if(!getControls().isKeyPressed(KEY_KEY_K))
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
			chunks_to_render[i].Render();
		}
	}

	Render::SetAlphaBlend(true);
	Render::RawQuads("DEBUG", HitBoxes);
	Render::SetAlphaBlend(false);

	GUI::SetFont("menu");
	GUI::DrawShadowedText("Pos: "+my_player.pos.IntString(), Vec2f(20,20), color_white);
	GUI::DrawShadowedText("Vel: "+my_player.vel.FloatString(), Vec2f(20,40), color_white);
	GUI::DrawShadowedText("Ang: "+my_player.look_dir.FloatString(), Vec2f(20,60), color_white);

	GUI::DrawShadowedText("dir_x: "+my_player.dir_x, Vec2f(20,80), color_white);
}

int max_generate = 3;

// hook doesnt work

/*void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	if(player is null || player is getLocalPlayer()) return;

	for(int i = 0; i < other_players.size(); i++)
	{
		Player@ _player = other_players[i];
		if(_player.player is player)
		{
			Debug("onNewPlayerJoin: Player already in list!", 3);
			return;
		}
	}

	Player new_player();
	new_player.pos = Vec3f(map_width/2, map_height-4, map_depth/2);
	new_player.SetPlayer(player);
	other_players.push_back(@new_player);
}*/

void onPlayerLeave(CRules@ this, CPlayer@ player)
{
	if(player is null) return;

	for(int i = 0; i < other_players.size(); i++)
	{
		Player@ _player = other_players[i];
		if(_player.player is player)
		{
			other_players.removeAt(i);
			return;
		}
	}
}

void onRender(CRules@ this)
{
	if(getLocalPlayer() is null) return;
	if(isLoading(this))
	{
		float percent = 0;
		if(!ask_map) percent = 1;
		else if(!map_ready) percent = float(got_packets)/float(amount_of_packets);
		else if(!faces_generated) percent = float(gf_packet)/float(gf_amount_of_packets);
		else percent = 1;

		GUI::DrawProgressBar(Vec2f(getScreenWidth()/2-200, getScreenHeight()/2-16), Vec2f(getScreenWidth()/2+200, getScreenHeight()/2+16), percent);
		GUI::SetFont("menu");
		GUI::DrawTextCentered(loading_string, Vec2f(getScreenWidth()/2, getScreenHeight()/2), color_white);
	}
}

// temp solution probably
Vertex[] SkyBox = {	Vertex(-1, -1, 1, 0.25f, 0.5f, color_white), // front face
					Vertex(-1, 1, 1, 0.25f, 0.25f, color_white),
					Vertex(1, 1, 1, 0.5f, 0.25f, color_white),
					Vertex(1, -1, 1, 0.5f, 0.5f, color_white),

					Vertex(1, -1, -1, 0.75f, 0.5f, color_white), // back face
					Vertex(1, 1, -1, 0.75f, 0.25f, color_white),
					Vertex(-1, 1, -1, 1.0f, 0.25f, color_white),
					Vertex(-1, -1, -1, 1.0f, 0.5f, color_white),

					Vertex(1, -1, 1, 0.5f, 0.5f, color_white), // right face
					Vertex(1, 1, 1, 0.5f, 0.25f, color_white),
					Vertex(1, 1, -1, 0.75f, 0.25f, color_white),
					Vertex(1, -1, -1, 0.75f, 0.5f, color_white),

					Vertex(-1, -1, -1, 0.0f, 0.5f, color_white), // left face
					Vertex(-1, 1, -1, 0.0f, 0.25f, color_white),
					Vertex(-1, 1, 1, 0.25f, 0.25f, color_white),
					Vertex(-1, -1, 1, 0.25f, 0.5f, color_white),

					Vertex(-1, 1, 1, 0.25f, 0.25f, color_white), // top face
					Vertex(-1, 1, -1, 0.25f, 0.0f, color_white),
					Vertex(1, 1, -1, 0.5f, 0.0f, color_white),
					Vertex(1, 1, 1, 0.5f, 0.25f, color_white),

					Vertex(-1, -1, -1, 0.25f, 0.5f, color_white), // bottom face
					Vertex(-1, -1, 1, 0.25f, 0.75f, color_white),
					Vertex(1, -1, 1, 0.5f, 0.75f, color_white),
					Vertex(1, -1, -1, 0.5f, 0.5f, color_white)
};