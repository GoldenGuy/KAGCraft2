
#define CLIENT_ONLY

#include "Debug.as"
#include "Vec3f.as"
#include "World.as"
#include "Tree.as"
#include "ClientLoading.as"
#include "FrameTime.as"
#include "Raycast.as"
#include "Camera.as"
#include "Player.as"
#include "Scoreboard.as"
#include "UtilitySectors.as"

#include "Sound3D.as"

World@ world;

Camera@ camera;

Player@ my_player;
Player@[] other_players;

void onInit(CRules@ this)
{
	Loading::isLoading = true;
}

void onTick(CRules@ this)
{
	if(getLocalPlayer() is null || getLocalPlayerBlob() is null)
	{
		return;
	}
	
	HitBoxes.clear();
	this.set_f32("interGameTime", getGameTime());
	this.set_f32("interFrameTime", 0);

	if(Loading::isLoading)
	{
		Loading::Progress(this);
		return;
	}
	else
	{
		// game here
		camera.tick_update();
		my_player.Update();

		/*for(int i = 0; i < other_players.size(); i++)
		{
			Vec3f pos = other_players[i].pos;
			AABB _box(pos-Vec3f(player_radius,0,player_radius), pos+Vec3f(player_radius,player_height,player_radius));
			DrawHitbox(_box, 0x88FFFFFF);
		}*/

		diggers.clear();
		if(my_player.digging)
		{
			my_player.RenderDiggingBlock(diggers);
		}
		for(int i = 0; i < other_players.size(); i++)
		{
			if(other_players[i].digging)
			{
				other_players[i].RenderDiggingBlock(diggers);
			}
		}

		if(!isServer() && getPlayersCount() > 1)
		{
			CBitStream to_send;
			my_player.Serialize(@to_send);
			this.SendCommand(this.getCommandID("C_PlayerUpdate"), to_send, false);
		}

		tree.Check();

		//if(isDebug())
		{
			if(hold_frustum)
			{
				Vec3f FLU = camera.frustum.getFarLeftUp();
				Vec3f FLD = camera.frustum.getFarLeftDown();
				Vec3f FRU = camera.frustum.getFarRightUp();
				Vec3f FRD = camera.frustum.getFarRightDown();
				Vec3f NLU = camera.frustum.getNearLeftUp();
				Vec3f NLD = camera.frustum.getNearLeftDown();
				Vec3f NRU = camera.frustum.getNearRightUp();
				Vec3f NRD = camera.frustum.getNearRightDown();

				frustum_shape.clear();

				frustum_shape.push_back(Vertex(FLU.x, FLU.y, FLU.z, 0, 0, 0x45AA00AA));
				frustum_shape.push_back(Vertex(FRU.x, FRU.y, FRU.z, 1, 0, 0x45AA00AA));
				frustum_shape.push_back(Vertex(FRD.x, FRD.y, FRD.z,	1, 1, 0x45AA00AA));
				frustum_shape.push_back(Vertex(FLD.x, FLD.y, FLD.z, 0, 1, 0x45AA00AA));

				frustum_shape.push_back(Vertex(NLU.x, NLU.y, NLU.z, 0, 0, 0x45AA00AA));
				frustum_shape.push_back(Vertex(NRU.x, NRU.y, NRU.z, 1, 0, 0x45AA00AA));
				frustum_shape.push_back(Vertex(NRD.x, NRD.y, NRD.z,	1, 1, 0x45AA00AA));
				frustum_shape.push_back(Vertex(NLD.x, NLD.y, NLD.z, 0, 1, 0x45AA00AA));

				frustum_shape.push_back(Vertex(NLU.x, NLU.y, NLU.z, 0, 0, 0x4500AAAA));
				frustum_shape.push_back(Vertex(FLU.x, FLU.y, FLU.z, 1, 0, 0x4500AAAA));
				frustum_shape.push_back(Vertex(FLD.x, FLD.y, FLD.z,	1, 1, 0x4500AAAA));
				frustum_shape.push_back(Vertex(NLD.x, NLD.y, NLD.z, 0, 1, 0x4500AAAA));

				frustum_shape.push_back(Vertex(FRU.x, FRU.y, FRU.z, 0, 0, 0x4500AAAA));
				frustum_shape.push_back(Vertex(NRU.x, NRU.y, NRU.z, 1, 0, 0x4500AAAA));
				frustum_shape.push_back(Vertex(NRD.x, NRD.y, NRD.z,	1, 1, 0x4500AAAA));
				frustum_shape.push_back(Vertex(FRD.x, FRD.y, FRD.z, 0, 1, 0x4500AAAA));

				frustum_shape.push_back(Vertex(FLD.x, FLD.y, FLD.z, 0, 0, 0x45FF00AA));
				frustum_shape.push_back(Vertex(FRD.x, FRD.y, FRD.z, 1, 0, 0x45FF00AA));
				frustum_shape.push_back(Vertex(NRD.x, NRD.y, NRD.z,	1, 1, 0x45FF00AA));
				frustum_shape.push_back(Vertex(NLD.x, NLD.y, NLD.z, 0, 1, 0x45FF00AA));

				frustum_shape.push_back(Vertex(NLU.x, NLU.y, NLU.z, 0, 0, 0x45FF00AA));
				frustum_shape.push_back(Vertex(NRU.x, NRU.y, NRU.z, 1, 0, 0x45FF00AA));
				frustum_shape.push_back(Vertex(FRU.x, FRU.y, FRU.z,	1, 1, 0x45FF00AA));
				frustum_shape.push_back(Vertex(FLU.x, FLU.y, FLU.z, 0, 1, 0x45FF00AA));
				
				for(int i = 0; i < chunks_to_render.size(); i++)
				{
					Chunk@ chunk = chunks_to_render[i];
					DrawHitbox(chunks_to_render[i].box, 0x880000FF);
				}
			}
		}
		UpdateSectors();
	}
}

void onCommand(CRules@ this, uint8 cmd, CBitStream@ params)
{
	if(cmd == this.getCommandID("S_SendMapParams"))
	{
		world.chunk_width = params.read_u32();
		world.chunk_depth = params.read_u32();
		world.chunk_height = params.read_u32();
		world.chunk_size = world.chunk_width*world.chunk_depth*world.chunk_height;

		world.world_width = params.read_u32();
		world.world_depth = params.read_u32();
		world.world_height = params.read_u32();
		world.world_width_depth = world.world_width * world.world_depth;
		world.world_size = world.world_width_depth * world.world_height;

		world.map_width = world.world_width * world.chunk_width;
		world.map_depth = world.world_depth * world.chunk_depth;
		world.map_height = world.world_height * world.chunk_height;
		world.map_width_depth = world.map_width * world.map_depth;
		world.map_size = world.map_width_depth * world.map_height;

		world.map_packet_size = world.chunk_width*world.chunk_depth*world.chunk_height*8;
		world.map_packets_amount = world.map_size / world.map_packet_size;

		world.block_faces_packets_amount = world.map_packets_amount;
		world.block_faces_packet_size = world.map_size / world.block_faces_packets_amount;

		world.chunks_packets_amount = world.world_depth*world.world_height;
		world.chunks_packet_size = world.world_size / world.chunks_packets_amount;

		uint8 sky_color_R = params.read_u8();
		uint8 sky_color_G = params.read_u8();
		uint8 sky_color_B = params.read_u8();
		world.sky_color = SColor(255, sky_color_R, sky_color_G, sky_color_B);

		Fill[0].col = Fill[1].col = Fill[2].col = Fill[3].col = world.sky_color;

		Loading::mapParamsReady = true;
	}
	else if(cmd == this.getCommandID("S_SendMapPacket"))
	{
		CBitStream map_packet;
		map_packet = params;
		map_packet.SetBitIndex(params.getBitIndex());
		world.map_packets.push_back(@map_packet);
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
					new_player.pos = Vec3f(world.map_width/2, world.map_height-4, world.map_depth/2);
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
				temp_bool = params.read_bool();
				if(temp_bool)
				{
					temp_float = params.read_f32();
					temp_float = params.read_f32();
					temp_float = params.read_f32();
					temp_float = params.read_f32();
				}
			}
		}
	}
	else if(cmd == this.getCommandID("S_ChangeBlock"))
	{
		uint8 block = params.read_u8();
		float x = params.read_f32();
		float y = params.read_f32();
		float z = params.read_f32();

		if(Loading::isLoading)
		{
			Loading::addBlockToQueue(Vec3f(x,y,z), block);
		}
		else
		{
			uint8 old_block = world.getBlock(x, y, z);
			world.setBlock(x, y, z, block);
    		world.UpdateBlocksAndChunks(x, y, z);
			world.BlockUpdate(x, y, z, block, old_block);
		}
	}
	else if(cmd == this.getCommandID("C_PlaySound3D"))
	{
		u16 netid = params.read_netid();
		CPlayer@ _player = getPlayerByNetworkId(netid);
		if(_player !is null && _player is getLocalPlayer())
		{
			string sound_name = params.read_string();
			float x = params.read_f32();
			float y = params.read_f32();
			float z = params.read_f32();

			Sound3D(sound_name, Vec3f(x,y,z));
		}
	}
	else if(cmd == this.getCommandID("C_RequestMap") || cmd == this.getCommandID("C_ChangeBlock"))
	{
		return;
	}
}

float[] model;

void Render(int id)
{
	CRules@ rules = getRules();
	camera.render_update();
	rules.set_f32("interFrameTime", Maths::Clamp01(rules.get_f32("interFrameTime")+getRenderApproximateCorrectionFactor()));
	rules.add_f32("interGameTime", getRenderApproximateCorrectionFactor());

	Vertex[] players_verts;
	if(thirdperson)
	{
		my_player.RenderUpdate();
		my_player.Render(players_verts);
	}
	for(int i = 0; i < other_players.size(); i++)
	{
		other_players[i].RenderUpdate();
		other_players[i].Render(players_verts);
	}

	Render::SetTransformScreenspace();

	Render::RawQuads("SOLID", Fill);

	Render::SetTransformWorldspace();

	Render::SetZBuffer(false, false);
	Render::SetAlphaBlend(false);
	Render::SetBackfaceCull(true);
	
	//Matrix::MakeIdentity(model);
	//Matrix::SetTranslation(model, camera.interpolated_pos.x, camera.interpolated_pos.y, camera.interpolated_pos.z);
	//Render::SetTransform(model, camera.view, camera.projection);
	//Render::RawQuads("Sky_Texture", SkyBox);
	Matrix::MakeIdentity(model);
	//Render::SetModelTransform(model);
	Render::SetTransform(model, camera.view, camera.projection);

	Render::ClearZ();
	Render::SetZBuffer(true, true);

	Render::SetAlphaBlend(true);
	world.map_material.SetVideoMaterial();

	//if(!getControls().isKeyPressed(KEY_KEY_K))
	{
		for(int i = 0; i < chunks_to_render.size(); i++)
		{
			/*Chunk@ chunk = chunks_to_render[i];
			if(chunk.rebuild)
			{
				if(generated < max_generate)
				{
					chunk.GenerateMesh();
					generated++;
				}
			}*/
			chunks_to_render[i].Render();
		}
		Render::RawQuads("SOLID", players_verts);
	}

	Render::SetAlphaBlend(true);
	Render::RawQuads("Block_Digger", diggers);

	if(draw_block_mouse)
	{
		Matrix::MakeIdentity(model);
		Matrix::SetTranslation(model, block_mouse_pos.x, block_mouse_pos.y, block_mouse_pos.z);
		Render::SetModelTransform(model);
		Render::RawQuads("BLOCK_MOUSE", block_mouse);
		Matrix::MakeIdentity(model);
		Render::SetModelTransform(model);
	}

	//Render::RawQuads("SOLID", HitBoxes);
	RenderSectors();
	if(hold_frustum)
	{
		Render::SetBackfaceCull(false);
		Matrix::MakeIdentity(model);
		Matrix::SetTranslation(model, camera.frustum_pos.x, camera.frustum_pos.y, camera.frustum_pos.z);
		Render::SetModelTransform(model);
		Render::RawQuads("SOLID", frustum_shape);

		//Matrix::MakeIdentity(model);
		Matrix::SetRotationDegrees(model, -camera.frustum_dir_y, camera.frustum_dir_x, 0);
		Render::SetModelTransform(model);
		camera.camera_model.RenderMeshWithMaterial();

		Render::SetModelTransform(model);
		Render::SetBackfaceCull(true);
	}
	Render::SetAlphaBlend(false);

	Render::SetTransformScreenspace();
	
	GUI::SetFont("menu");
	GUI::DrawShadowedText("Pos: "+my_player.pos.IntString(), Vec2f(20,20), color_white);
	GUI::DrawShadowedText("Vel: "+my_player.vel.FloatString(), Vec2f(20,40), color_white);
	GUI::DrawShadowedText("Ang: "+my_player.look_dir.FloatString(), Vec2f(20,60), color_white);

	GUI::DrawShadowedText("dir_x: "+my_player.dir_x, Vec2f(20,80), color_white);
}

int max_generate = 4;
int generated = 0;

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
	if(Loading::isLoading)
	{
		float percent;
		if(Loading::state == Loading::map_unserialization) percent = float(world.current_map_packet)/float(world.map_packets_amount);
		else if(Loading::state == Loading::block_faces_gen) percent = float(world.current_block_faces_packet)/float(world.block_faces_packets_amount);
		else if(Loading::state == Loading::chunk_gen) percent = float(world.current_chunks_packet)/float(world.chunks_packets_amount);
		else percent = 1;

		GUI::DrawProgressBar(Vec2f(getScreenWidth()/2-200, getScreenHeight()/2-16), Vec2f(getScreenWidth()/2+200, getScreenHeight()/2+16), percent);
		GUI::SetFont("menu");
		GUI::DrawTextCentered(Loading::loading_string, Vec2f(getScreenWidth()/2, getScreenHeight()/2), color_white);
	}
	else if(block_menu_open)
	{
		Render::SetTransformScreenspace();
		Render::SetBackfaceCull(false);
		GUI::DrawRectangle(block_menu_start, block_menu_end, 0xAA404040);
		GUI::DrawPane(block_menu_mouse, block_menu_mouse+block_menu_tile_size);
		GUI::DrawPane(picked_block_pos, picked_block_pos+block_menu_tile_size, 0xFF30AA30);
		Render::RawQuads("Block_Textures", block_menu_verts);
	}
}

Vertex[] frustum_shape;

Vertex[] diggers; // ...maybe change the name...

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

					Vertex(-1, -1, -1, 0.25f, 0.75f, color_white), // bottom face
					Vertex(-1, -1, 1, 0.25f, 0.5f, color_white),
					Vertex(1, -1, 1, 0.5f, 0.5f, color_white),
					Vertex(1, -1, -1, 0.5f, 0.75f, color_white)
};

Vertex[] Fill = {	Vertex(0, 0, 0, 0, 0, color_white),
					Vertex(getScreenWidth(), 0, 0, 1, 0, color_white),
					Vertex(getScreenWidth(), getScreenHeight(), 0, 1, 1, color_white),
					Vertex(0, getScreenHeight(), 0, 0, 1, color_white)
};