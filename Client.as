
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
#include "Scoreboard.as"
#include "UtilitySectors.as"

World@ world;

Camera@ camera;

Player@ my_player;
Player@[] other_players;

void onInit(CRules@ this)
{
	Debug("Client init");
	this.set_bool("ClientLoading", true);
	block_queue.clear();

	Texture::createFromFile("Block_Textures", "Textures/Blocks_Jenny.png");
	Texture::createFromFile("Block_Digger", "Textures/Digging.png");
	Texture::createFromFile("Sky_Texture", "Textures/SkyBox.png");
	Texture::createFromFile("BLOCK_MOUSE", "Textures/BlockMouse.png");
	Texture::createFromFile("DEBUG", "Textures/Debug.png");
	Texture::createFromFile("SOLID", "Sprites/pixel.png");
	InitBlocks();
	this.addCommandID("pick_block");
	this.addCommandID("pick_block_reset");

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
		world.FacesSetUp();
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

		if(isDebug())
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
	//Debug("Command: "+cmd+" : "+this.getNameFromCommandID(cmd), 1);
	if(cmd == this.getCommandID("S_SendMapPacket"))
	{
		//ready_unser = true;
		//map_packet.Clear();
		//map_packet = params;
		//map_packet.SetBitIndex(params.getBitIndex());
		CBitStream map_packet;
		map_packet = params;
		map_packet.SetBitIndex(params.getBitIndex());
		map_packets.push_back(@map_packet);
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
	else if(cmd == this.getCommandID("C_ChangeBlock"))
	{
		uint8 block = params.read_u8();
		float x = params.read_f32();
		float y = params.read_f32();
		float z = params.read_f32();

		if(this.get_bool("ClientLoading"))
		{
			block_queue.push_back(BlockToPlace(Vec3f(x,y,z), block));
		}
		else
		{
			world.map[y][z][x] = block;
    		world.UpdateBlocksAndChunks(x, y, z);
		}
	}
	else if(cmd == this.getCommandID("pick_block"))
	{
		uint16 netid = params.read_netid();
		CPlayer@ _player = getPlayerByNetworkId(netid);
		if(_player is getLocalPlayer())
		{
			uint8 _block = params.read_u8();
			my_player.hand_block = _block;
			getHUD().ClearMenus(true);
			getControls().setMousePosition(getDriver().getScreenCenterPos());
			block_menu = false;
			block_menu_created = false;
		}
	}
	else if(cmd == this.getCommandID("pick_block_reset"))
	{
		uint16 netid = params.read_netid();
		CPlayer@ _player = getPlayerByNetworkId(netid);
		if(_player is getLocalPlayer())
		{
			getHUD().ClearMenus(true);
			getControls().setMousePosition(getDriver().getScreenCenterPos());
			block_menu = false;
			block_menu_created = false;
		}
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
	camera.render_update();
	rules.set_f32("interFrameTime", Maths::Clamp01(rules.get_f32("interFrameTime")+getRenderApproximateCorrectionFactor()));
	rules.add_f32("interGameTime", getRenderApproximateCorrectionFactor());

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

	if(!getControls().isKeyPressed(KEY_KEY_K))
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
		Matrix::MakeIdentity(model);
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
	if(this.get_bool("ClientLoading"))
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
	else if(block_menu)
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

Vertex[] Fill = {	Vertex(0, 0, 0, 0, 0, sky_color),
					Vertex(getScreenWidth(), 0, 0, 1, 0, sky_color),
					Vertex(getScreenWidth(), getScreenHeight(), 0, 1, 1, sky_color),
					Vertex(0, getScreenHeight(), 0, 0, 1, sky_color)
};