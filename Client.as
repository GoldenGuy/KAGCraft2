
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
#include "UtilityStuff.as"
#include "Sound3D.as"

World@ world;

Camera@ camera;

Player@ my_player;
Player@[] other_players;

Vertex[] diggers; // ...maybe change the name...

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

	if(Loading::isLoading)
	{
		Loading::Progress(this);
		return;
	}
	else // game here
	{
		this.set_f32("interGameTime", getGameTime());
		this.set_f32("interFrameTime", 0);

		HitBoxes.clear();
		
		camera.tick_update();
		my_player.Update();

		// sync your player
		if(!isServer() && getPlayersCount() > 1)
		{
			CBitStream to_send;
			my_player.Serialize(@to_send);
			this.SendCommand(this.getCommandID("C_PlayerUpdate"), to_send, false);
		}

		// draw block digging cursors for each player
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

		tree.Check(); // gather chunks to render in to an array

		// draw frustum shape
		if(hold_frustum)
		{
			camera.frustum.GenerateShape();
			
			/*for(int i = 0; i < chunks_to_render.size(); i++)
			{
				Chunk@ chunk = chunks_to_render[i];
				DrawHitbox(chunks_to_render[i].box, 0x880000FF);
			}*/
		}

		UpdateSectors();
		UpdateUTexts();

		if(getControls().isKeyJustPressed(KEY_F1)) show_help = !show_help;

		if(thirdperson || !isWindowActive() || !isWindowFocused() || Menu::getMainMenu() !is null || block_menu_open || IsChatPromptActive() || scoreboard_open)
		{
			getDriver().SetShader("mc_cursor", false);
		}
		else
		{
			getDriver().SetShader("mc_cursor", true);
		}
	}
	scoreboard_open = false;
}

Vec2f Project(Vec3f&in p)
{
	p = MultiplyVec3fMatrix(camera.view, p);
	p = MultiplyVec3fMatrix(camera.projection, p);
	Vec2f output = Vec2f(int(((p.x/p.z + 1.0)/2.0) * getScreenWidth() + 0.5f), int(((1.0 - p.y/p.z)/2.0) * getScreenHeight() + 0.5f));
	return output;
}

Vec3f MultiplyVec3fMatrix(const float[]&in M, Vec3f&in point)
{
	Vec3f output;
	output.x = point.x*M[0] + point.y*M[4] + point.z*M[8] + M[12];
	output.y = point.x*M[1] + point.y*M[5] + point.z*M[9] + M[13];
	output.z = point.x*M[2] + point.y*M[6] + point.z*M[10] + M[14];
	return output;
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
	else if(cmd == this.getCommandID("C_CreatePlayer"))
	{
		u16 netid = params.read_netid();
		CPlayer@ _player = getPlayerByNetworkId(netid);
		if(_player !is null && _player !is getLocalPlayer())
		{
			print("created "+_player.getUsername());
			Player new_player();
			new_player.pos = Vec3f(world.map_width/2, world.map_height-4, world.map_depth/2);
			new_player.SetPlayer(_player);
			new_player.MakeNickname();
			new_player.MakeModel();
			other_players.push_back(@new_player);
		}
	}
	else if(cmd == this.getCommandID("S_PlayerUpdate"))
	{
		// ignore while loading
		if(Loading::isLoading)
		{
			return;
		}
		
		u16 size = params.read_u16();
		for(int i = 0; i < size; i++)
		{
			u16 netid = params.read_netid();
			CPlayer@ _player = getPlayerByNetworkId(netid);
			if(_player !is null && _player !is getLocalPlayer())
			{
				for(int i = 0; i < other_players.size(); i++)
				{
					Player@ __player = other_players[i];
					if(__player.player is _player)
					{
						__player.UnSerialize(params);
						break;
					}
				}
			}
			else
			{
				float temp_float = params.read_f32();
				temp_float = params.read_f32();
				temp_float = params.read_f32();
				temp_float = params.read_f32();
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
	else if(cmd == this.getCommandID("S_FreezePlayer"))
	{
		u16 netid = params.read_netid();
		CPlayer@ _player = getPlayerByNetworkId(netid);
		if(_player !is null)
		{
			bool freeze = params.read_bool();
			if(_player is getLocalPlayer())
			{
				my_player.Frozen = freeze;
			}
			else
			{
				for(int i = 0; i < other_players.size(); i++)
				{
					Player@ __player = other_players[i];
					if(__player.player is _player)
					{
						__player.Frozen = freeze;
					}
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
	else if(cmd == this.getCommandID("SC_ChangeSky"))
	{
		u8 r = params.read_u8();
		u8 g = params.read_u8();
		u8 b = params.read_u8();
		world.sky_color.setRed(r);
		world.sky_color.setGreen(g);
		world.sky_color.setBlue(b);

		Render::SetFog(world.sky_color, SMesh::LINEAR, camera.z_far*0.76f, camera.z_far, 0, false, false);
		Fill[0].col = Fill[1].col = Fill[2].col = Fill[3].col = world.sky_color;
	}
	else if(cmd == this.getCommandID("S_UText"))
	{
		string text = params.read_string();
		u8 r = params.read_u8();
		u8 g = params.read_u8();
		u8 b = params.read_u8();
		u16 timer = params.read_u16();

		SColor col(255,r,g,b);

		AddUText(text, col.color, timer);
	}
}

float[] model;

void Render(int id)
{
	CRules@ rules = getRules();

	if(getLocalPlayer() is null) return;
	if(Loading::isLoading)
	{
		if(Loading::state == Loading::intro && Loading::intro_timer > 0)
		{
			camera.render_update();
			Render::SetTransformScreenspace();
			Render::RawQuads("SOLID", Fill);
			if(Loading::intro_timer < 420)
			{
				Render::SetTransformWorldspace();
				Matrix::MakeIdentity(model);
				Render::SetTransform(model, camera.view, camera.projection);
				
				Loading::into_model_body.RenderMeshWithMaterial();

				float look_at_me = 0;
				if(Loading::intro_timer >= 100 && Loading::intro_timer <= 250)
				{
					look_at_me = float(Loading::intro_timer-100)*(-0.3);
				}
				else if(Loading::intro_timer > 250 && Loading::intro_timer <= 310)
				{
					look_at_me = -45;
				}
				else if(Loading::intro_timer > 310 && Loading::intro_timer <= 340)
				{
					look_at_me = XORRandom(50)*(-1);
				}
				Matrix::SetRotationDegrees(model, 18, 0, 0);
				float[] temp_mat;
				Matrix::MakeIdentity(temp_mat);
				Matrix::SetRotationDegrees(temp_mat, 0, -look_at_me, 0);
				model = Matrix_Multiply(model, temp_mat);
				Render::SetModelTransform(model);
				Loading::into_model_head.RenderMeshWithMaterial();
				Matrix::MakeIdentity(model);
				Render::SetModelTransform(model);

				Render::SetTransformScreenspace();
				GUI::SetFont("menu");
				GUI::DrawText("Press spacebar to skip.", Vec2f(5, getScreenHeight()-28), 0xFF505050);
			}
			else
			{
				Render::ClearZ();
				SColor logo_color = SColor(0xFFFFFFFF);
				Render::SetAlphaBlend(true);
				if(Loading::intro_timer < 548) logo_color.setAlpha(Maths::Min((Loading::intro_timer-420)*2, 255));
				if(Loading::intro_timer > 670) logo_color.setAlpha(Maths::Max(255-(Loading::intro_timer-670)*3, 0));
				Vec2f center = getDriver().getScreenCenterPos();
				Vertex[] Logo = {	Vertex(center.x-76, center.y+20, 0, 0, 1, logo_color),
									Vertex(center.x-76, center.y-20, 0, 0, 0, logo_color),
									Vertex(center.x+76, center.y-20, 0, 1, 0, logo_color),
									Vertex(center.x+76, center.y+20, 0, 1, 1, logo_color)
				};
				Render::RawQuads("LOGO", Logo);
			}
		}
		else
		{
			float percent;
			if(Loading::state == Loading::map_unserialization) percent = float(world.current_map_packet)/float(world.map_packets_amount);
			else if(Loading::state == Loading::block_faces_gen) percent = float(world.current_block_faces_packet)/float(world.block_faces_packets_amount);
			else if(Loading::state == Loading::chunk_gen) percent = float(world.current_chunks_packet)/float(world.chunks_packets_amount);
			else percent = 1;

			if(Loading::state == Loading::press_enter)
			{
				GUI::DrawPane(Vec2f(getScreenWidth()/2-200, getScreenHeight()/2-16), Vec2f(getScreenWidth()/2+200, getScreenHeight()/2+16), 0xFF30EE30);
			}
			else
			{
				GUI::DrawProgressBar(Vec2f(getScreenWidth()/2-200, getScreenHeight()/2-16), Vec2f(getScreenWidth()/2+200, getScreenHeight()/2+16), percent);
			}
			GUI::SetFont("menu");
			GUI::DrawTextCentered(Loading::loading_string, Vec2f(getScreenWidth()/2, getScreenHeight()/2), color_white);

			Vec2f help_dim;
			GUI::GetTextDimensions(help_text, help_dim);
			Vec2f help_start = getDriver().getScreenCenterPos()-Vec2f(help_dim.x/2, help_dim.y+40);
			help_start.y += 40;
			Vec2f help_end = help_start+help_dim;
			help_end.y -= 40;
			GUI::DrawWindow(help_start-Vec2f(6,6), help_end+Vec2f(6,6));
			GUI::DrawText(help_text, help_start, color_black);
		}
		return;
	}

	camera.render_update();

	Render::SetTransformScreenspace();

	Render::RawQuads("SOLID", Fill); // fill screen with solid color (sky color)

	Render::SetTransformWorldspace();
	Render::ClearZ();
	Render::SetZBuffer(true, true);
	Render::SetAlphaBlend(false);
	Render::SetBackfaceCull(true);
	
	Matrix::MakeIdentity(model);
	Render::SetTransform(model, camera.view, camera.projection);

	// render map
	world.map_material.SetVideoMaterial();
	for(int i = 0; i < chunks_to_render.size(); i++)
	{
		chunks_to_render[i].Render();
	}

	// render yourself only while in thirdperson
	if(thirdperson)
	{
		Vec3f temp_1 = my_player.render_pos;
		temp_1.y += player_height+0.5f;
		Vec2f nnpos = Project(temp_1);
		GUI::DrawTextCentered("GoldenGuy", nnpos, color_white);
		my_player.RenderUpdate();
		my_player.RenderPlayer();
	}
	// render other players
	for(int i = 0; i < other_players.size(); i++)
	{
		other_players[i].RenderUpdate();
		other_players[i].RenderPlayer();
		other_players[i].RenderNickname();
	}

	Render::SetAlphaBlend(true);
	Matrix::MakeIdentity(model);
	Render::SetModelTransform(model);

	// render all block diggers
	Render::RawQuads("Block_Digger", diggers);

	// render your block cursor
	if(draw_block_mouse)
	{
		Matrix::MakeIdentity(model);
		Matrix::SetTranslation(model, block_mouse_pos.x, block_mouse_pos.y, block_mouse_pos.z);
		Render::SetModelTransform(model);
		Render::RawQuads("BLOCK_MOUSE", block_mouse);
	}

	Matrix::MakeIdentity(model);
	Render::SetModelTransform(model);
	RenderSectors();

	// render frustum shape
	if(hold_frustum)
	{
		Render::SetBackfaceCull(false);
		//Matrix::MakeIdentity(model);
		Matrix::SetTranslation(model, camera.frustum_pos.x, camera.frustum_pos.y, camera.frustum_pos.z);
		Render::SetModelTransform(model);
		Render::RawQuads("SOLID", camera.frustum.frustum_shape);
		Render::SetBackfaceCull(true);
		
		// actual camera model (thanks jenny :3 )
		Matrix::SetRotationDegrees(model, -camera.frustum_dir_y, camera.frustum_dir_x, 0);
		Render::SetModelTransform(model);
		camera.camera_model.RenderMeshWithMaterial();
	}

	// calculate interpolation multiplier	
	rules.set_f32("interFrameTime", Maths::Clamp01(rules.get_f32("interFrameTime")+getRenderApproximateCorrectionFactor()));
	rules.add_f32("interGameTime", getRenderApproximateCorrectionFactor());

	Render::SetTransformScreenspace();
	Render::ClearZ();
	
	GUI::SetFont("menu");

	if(block_menu_open)
	{
		Render::SetTransformScreenspace();
		Render::SetBackfaceCull(false);
		GUI::DrawRectangle(block_menu_start, block_menu_end, 0xAA404040);
		GUI::DrawPane(block_menu_mouse, block_menu_mouse+block_menu_tile_size);
		GUI::DrawPane(picked_block_pos, picked_block_pos+block_menu_tile_size, 0xFF30AA30);
		Render::RawQuads("Block_Textures", block_menu_verts);
	}

	if(show_help)
	{
		Vec2f help_dim;
		GUI::GetTextDimensions(help_text, help_dim);
		Vec2f help_start = Vec2f(20, 20);
		Vec2f help_end = help_start+help_dim;
		help_end.y -= 60;
		GUI::DrawRectangle(help_start-Vec2f(6,6), help_end+Vec2f(6,6), 0xAA404040);
		GUI::DrawText(help_text, help_start, color_white);
	}

	if(!g_videorecording)
	{
		RenderUTexts();
		my_player.RenderHandBlock();
	}
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

// temp solution probably
/*Vertex[] SkyBox = {	Vertex(-1, -1, 1, 0.25f, 0.5f, color_white), // front face
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
};*/

Vertex[] Fill = {	Vertex(0, 0, 0, 0, 0, color_white),
					Vertex(getScreenWidth(), 0, 0, 1, 0, color_white),
					Vertex(getScreenWidth(), getScreenHeight(), 0, 1, 1, color_white),
					Vertex(0, getScreenHeight(), 0, 0, 1, color_white)
};

bool show_help = false;
string help_text =  "Welcome to KagCraft2!"+"\n\n"+
					"Rules: Dont grief, dont build forbidden structures (dicks, swastikas, etc.)."+"\n\n"+
					"Controls:"+"\n"+
					"Left click - dig block,"+"\n"+
					"Right click - place block,"+"\n"+
					"Middle click - copy block you looking at,"+"\n"+
					"Mouse wheel up/down - change block,"+"\n"+
					"E - block menu,"+"\n"+
					"Shift - crouch,"+"\n"+
					"Ctrl - sprint,"+"\n"+
					"Tab - scoreboard,"+"\n"+
					"F1 - show this text in game."+"\n\n"+
					"Type /commands in chat to see available commands.";