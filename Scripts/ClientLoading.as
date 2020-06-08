
namespace Loading
{
	bool isLoading = false;
	bool mapParamsReady = false;
	int state = 0;
	string loading_string = "Init.";

	SMesh into_model_head;
	SMesh into_model_body;
	int intro_timer = 0;

	enum val
	{
		init,
		intro,
		request_map_params,
		waiting_for_map_params,
		ask_for_map,
		map_unserialization,
		block_faces_gen,
		chunk_gen,
		octree_gen,
		press_enter,
		set_player,
		done
	}

	BlockToPlace[] block_queue;

	class BlockToPlace
	{
		Vec3f pos;
		uint8 block;

		BlockToPlace(){}

		BlockToPlace(const Vec3f&in _pos, uint8 _block)
		{
			pos = _pos;
			block = _block;
		}
	}

	void addBlockToQueue(const Vec3f&in _pos, uint8 _block)
	{
		block_queue.push_back(BlockToPlace(_pos, _block));
	}

	void Progress(CRules@ this)
	{
		switch(state)
		{
			case init:
			{
				mapParamsReady = false;
				
				@camera = @Camera();
				
				block_queue.clear();

				Texture::createFromFile("Block_Textures", "Textures/Blocks_Jenny.png");
				Texture::createFromFile("Block_Digger", "Textures/Digging.png");
				Texture::createFromFile("Sky_Texture", "Textures/SkyBox.png");
				Texture::createFromFile("BLOCK_MOUSE", "Textures/BlockMouse.png");
				Texture::createFromFile("DEBUG", "Textures/Debug.png");
				Texture::createFromFile("SOLID", "Sprites/pixel.png");
				Texture::createFromFile("NickNamesFont", "NickNamesFont.png");
				Texture::createFromFile("LOGO", "Textures/Logo.png");

				InitBlocks();

				Sound::SetListenerPosition(Vec2f_zero);
				Sound::SetCutOff(220);

				if(this.exists("world"))
				{
					this.get("world", @world);
					world.FacesSetUp();
					world.SetUpMaterial();
				}
				else
				{
					@world = @World();
					world.SetUpMaterial();
				}

				world.map_packets.clear();
				world.current_map_packet = 0;
				world.current_block_faces_packet = 0;
				world.current_chunks_packet = 0;
				Fill[0].col = Fill[1].col = Fill[2].col = Fill[3].col = color_black;

				intro_timer = 0;
				into_model_head.LoadObjIntoMesh("Models/Misc/Intro/intro_head.obj");
				into_model_head.GetMaterial().SetFlag(SMaterial::LIGHTING, false);
				into_model_head.GetMaterial().SetFlag(SMaterial::BACK_FACE_CULLING, false);
				into_model_head.GetMaterial().SetFlag(SMaterial::BILINEAR_FILTER, false);
				into_model_head.GetMaterial().SetFlag(SMaterial::BLEND_OPERATION, true);
				into_model_head.GetMaterial().SetFlag(SMaterial::FOG_ENABLE, true);
				into_model_body.LoadObjIntoMesh("Models/Misc/Intro/intro_body.obj");
				into_model_body.GetMaterial().SetFlag(SMaterial::LIGHTING, false);
				into_model_body.GetMaterial().SetFlag(SMaterial::BACK_FACE_CULLING, false);
				into_model_body.GetMaterial().SetFlag(SMaterial::BILINEAR_FILTER, false);
				into_model_body.GetMaterial().SetFlag(SMaterial::BLEND_OPERATION, true);
				into_model_body.GetMaterial().SetFlag(SMaterial::FOG_ENABLE, true);

				Render::addScript(Render::layer_background, "Client.as", "Render", 1);
				
				state = intro;
				loading_string = "Intro.";
				return;
			}

			case intro:
			{
				if(intro_timer == 0)
				{
					CMixer@ mixer = getMixer();
					mixer.ResetMixer();
					mixer.AddTrack("Sounds/intro_music.ogg", 1);
					mixer.PlayRandom(1);

					camera.move(Vec3f(-3,2,-6), true);
					camera.turn(30,-20,0, true);
				}
				camera.tick_update();
				if(intro_timer < 420)
				{
					float fog_modif = 7.5f;
					if(intro_timer > 360)
					{
						fog_modif = Maths::Max(0, 7.5f-7.5f*((intro_timer-360)/120.0f));
					}
					if(intro_timer % 2 == 0) Render::SetFog(0x0000000, SMesh::LINEAR, fog_modif*(0.20f+float(XORRandom(20))/100.0f), fog_modif, 0, true, false);
				}
				else if(intro_timer >= 420)
				{
					Render::SetFog(0xFFFFFFFF, SMesh::LINEAR, 0, 8000, 0, false, false);
				}
				intro_timer++;
				if(getControls().isKeyJustPressed(KEY_SPACE) || intro_timer == 790)
				{
					intro_timer = 0;
					getMixer().FadeOut(1, 2);
					loading_string = "Requesting map parameters.";
					state = isServer() ? block_faces_gen : request_map_params;
				}
				return;
			}

			case request_map_params:
			{
				CBitStream to_send;
				to_send.write_netid(getLocalPlayer().getNetworkID());
				this.SendCommand(this.getCommandID("C_RequestMapParams"), to_send, false);
				state = waiting_for_map_params;
				loading_string = "Waiting for map parameters.";
				return;
			}

			case waiting_for_map_params:
			{
				if(mapParamsReady)
				{
					world.ClientMapSetUp();
					world.FacesSetUp();
					state = ask_for_map;
					loading_string = "Asking for map.";
					return;
				}
				else
				{
					return;
				}
			}

			case ask_for_map:
			{
				CBitStream to_send;
				to_send.write_netid(getLocalPlayer().getNetworkID());
				this.SendCommand(this.getCommandID("C_RequestMap"), to_send, false);

				state = map_unserialization;
				loading_string = "Loading map.";
				return;
			}

			case map_unserialization:
			{
				if(world.map_packets.size() > 0)
				{
					world.UnSerialize(world.map_packets[0], world.current_map_packet);
					world.map_packets.removeAt(0);
					world.current_map_packet++;
				}
				else if(world.current_map_packet >= world.map_packets_amount)
				{
					state = chunk_gen;
					loading_string = "Setting up chunks.";
					return;
				}

				int percent = (float(world.current_map_packet)/float(world.map_packets_amount))*100;
				loading_string = "Loading map. "+percent+"%";

				return;
			}

			case block_faces_gen:
			{
				world.GenerateBlockFaces(world.current_block_faces_packet);
				world.current_block_faces_packet++;
				if(world.current_block_faces_packet >= world.block_faces_packets_amount)
				{
					state = chunk_gen;
					loading_string = "Setting up chunks.";
					return;
				}

				int percent = (float(world.current_block_faces_packet)/float(world.block_faces_packets_amount))*100;
				loading_string = "Setting up block faces. "+percent+"%";

				return;
			}

			case chunk_gen:
			{
				world.SetUpChunks(world.current_chunks_packet);
				world.current_chunks_packet++;
				if(world.current_chunks_packet >= world.chunks_packets_amount)
				{
					state = octree_gen;
					loading_string = "Setting up tree.";
					return;
				}

				int percent = (float(world.current_chunks_packet)/float(world.chunks_packets_amount))*100;
				loading_string = "Setting up chunks. "+percent+"%";

				return;
			}

			case octree_gen:
			{
				SetUpTree();
				loading_string = "Press Spacebar to continue.";
				state = press_enter;

				return;
			}

			case press_enter:
			{
				if(getControls().isKeyJustPressed(KEY_SPACE))
				{
					loading_string = "Setting up player.";
					state = set_player;
				}
				return;
			}

			case set_player:
			{
				@my_player = @Player();
				
				my_player.pos = Vec3f(world.map_width/2, world.map_height-4, world.map_depth/2);
				my_player.SetBlob(getLocalPlayerBlob());
				my_player.SetPlayer(getLocalPlayer());
				my_player.MakeModel();
				my_player.GenerateBlockMenu();

				getControls().setMousePosition(Vec2f(float(getScreenWidth()) / 2.0f, float(getScreenHeight()) / 2.0f));

				Render::SetFog(world.sky_color, SMesh::LINEAR, camera.z_far*0.76f, camera.z_far, 0, false, false);
				Fill[0].col = Fill[1].col = Fill[2].col = Fill[3].col = world.sky_color;

				for(int i = 0; i < block_queue.size(); i++)
				{
					Vec3f pos = block_queue[i].pos;
					uint8 block = block_queue[i].block;
					world.setBlockSafe(pos.x, pos.y, pos.z, block);
					world.UpdateBlocksAndChunks(pos.x, pos.y, pos.z);
				}
				block_queue.clear();

				for(int i = 0; i < getPlayersCount(); i++)
				{
					CPlayer@ pl = getPlayer(i);
					if(pl !is getLocalPlayer())
					{
						Player new_player();
						new_player.pos = Vec3f(world.map_width/2, world.map_height-4, world.map_depth/2);
						new_player.SetPlayer(pl);
						new_player.MakeNickname();
						new_player.MakeModel();
						other_players.push_back(@new_player);
					}
				}

				string seclev = getSecurity().getPlayerSeclev(getLocalPlayer()).getName();
				if (seclev == "Admin")
				{
					admin = true;
				}

				CBitStream to_send;
				to_send.write_netid(getLocalPlayer().getNetworkID());
				this.SendCommand(this.getCommandID("C_CreatePlayer"), to_send);

				getDriver().ForceStartShaders();
				getDriver().AddShader("mc_cursor");
				getDriver().SetShaderInt("mc_cursor", "screenWidth", getScreenWidth());
				getDriver().SetShaderInt("mc_cursor", "screenHeight", getScreenHeight());
				getDriver().SetShader("mc_cursor", true);

				loading_string = "Done!";
				state = done;

				return;
			}

			case done:
			{
				isLoading = false;
				return;
			}
		}
	}
}