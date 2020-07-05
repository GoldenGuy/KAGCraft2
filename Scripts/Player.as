
#include "PlayerRenderings.as"
#include "NickNames.as"

const float acceleration = 0.06f;
const float jump_acceleration = 0.35f;
const float friction = 0.75f;
const float air_friction = 0.8f;
const float eye_height = 1.7f;
const float player_height = 1.85f;
const float player_radius = 0.35f;
const float player_diameter = player_radius*2;
const float arm_distance = 5.0f;
const float max_dig_time = 100;
const float mouse_sensitivity = 0.16;

bool move_mouse = false;

bool thirdperson = false;
bool block_menu_open = false;
bool fly = false;
bool hold_frustum = false;

Vec3f block_mouse_pos = Vec3f();
bool draw_block_mouse = false;

Vec2f block_menu_start = Vec2f_zero;
Vec2f block_menu_end = Vec2f_zero;
Vec2f block_menu_size = Vec2f(8,5);
Vec2f block_menu_tile_size = Vec2f(56,56);
Vec2f block_menu_icon_size = Vec2f(64,64);
Vec2f block_menu_mouse = Vec2f_zero;
Vec2f picked_block_pos = Vec2f_zero;
uint8[] block_menu_blocks;
Vertex[] block_menu_verts;

class Player
{
    Vec3f pos, vel, old_pos, render_pos, moving_vec;
	CBlob@ blob;
	CPlayer@ player;
	bool admin = false;
	bool render = false;
    bool onGround = false;
	bool Jump = false;
	bool Crouch = false;
	bool Frozen = false;
	bool Run = false;
	float dir_x = 0.01f;
	float dir_y = 0.01f;
	Vec3f look_dir;
	bool digging = false;
	Vec3f digging_pos;
	float dig_timer;
	uint8 hand_block = Block::stone;

	SMaterial player_material;
	SMaterial player_frozen_material;
	
	SMesh mesh_nickname;
	
	SMesh mesh_head;
	SMesh mesh_body;
	SMesh mesh_arm_right;
	SMesh mesh_arm_left;
	SMesh mesh_leg_right;
	SMesh mesh_leg_left;

	Player(){}

	void SetBlob(CBlob@ _blob)
	{
		@blob = @_blob;
	}

	void SetPlayer(CPlayer@ _player)
	{
		@player = @_player;
		string seclev = getSecurity().getPlayerSeclev(_player).getName();
		if(seclev == "Admin")
		{
			admin = true;
		}
	}

	void MakeModel()
	{
		if(	player.getUsername() == "Turtlecake" ||
			player.getUsername() == "MintMango" ||
			player.getUsername() == "Mazey" ||
			player.getUsername() == "epsilon" ||
			player.getUsername() == "dragonfriend18" ||
			player.getUsername() == "Vamist" ||
			player.getUsername() == "guift" ||
			player.getUsername() == "Netormozi_snekersni" ||
			player.getUsername() == "GoldenGuy")
		{
			player_material.AddTexture("Textures/Skins/skin_"+player.getUsername()+".png", 0);
			player_frozen_material.AddTexture("Textures/Skins/skin_"+player.getUsername()+".png", 0);
		}
		else
		{
			player_material.AddTexture("Textures/Skins/Default/skin"+XORRandom(8)+".png", 0);
			player_frozen_material.AddTexture("Textures/Skins/Default/skin"+XORRandom(8)+".png", 0);
		}

		player_material.DisableAllFlags();
		player_material.SetFlag(SMaterial::COLOR_MASK, true);
		player_material.SetFlag(SMaterial::ZBUFFER, true);
		player_material.SetFlag(SMaterial::ZWRITE_ENABLE, true);
		player_material.SetFlag(SMaterial::BACK_FACE_CULLING, true);
		player_material.SetFlag(SMaterial::FOG_ENABLE, true);
		player_material.SetMaterialType(SMaterial::TRANSPARENT_ALPHA_CHANNEL_REF);

		player_frozen_material.DisableAllFlags();
		player_frozen_material.SetFlag(SMaterial::COLOR_MASK, true);
		player_frozen_material.SetFlag(SMaterial::ZBUFFER, true);
		player_frozen_material.SetFlag(SMaterial::ZWRITE_ENABLE, true);
		player_frozen_material.SetFlag(SMaterial::BACK_FACE_CULLING, true);
		player_frozen_material.SetFlag(SMaterial::FOG_ENABLE, true);
		player_frozen_material.SetMaterialType(SMaterial::TRANSPARENT_ALPHA_CHANNEL_REF);
		player_frozen_material.SetFlag(SMaterial::LIGHTING, true);
		player_frozen_material.SetEmissiveColor(0xFFFF6060);

		mesh_head.Clear();
		mesh_head.SetMaterial(player_material);
		mesh_head.SetVertex(player.getUsername() == "Turtlecake" ? player_head_jenny : player_head);
		mesh_head.SetIndices(player_IDs);
		mesh_head.SetDirty(SMesh::VERTEX_INDEX);
		mesh_head.SetHardwareMapping(SMesh::STATIC);
		mesh_head.BuildMesh();

		mesh_body.Clear();
		mesh_body.SetMaterial(player_material);
		mesh_body.SetVertex(player_body);
		mesh_body.SetIndices(player_IDs);
		mesh_body.SetDirty(SMesh::VERTEX_INDEX);
		mesh_body.SetHardwareMapping(SMesh::STATIC);
		mesh_body.BuildMesh();

		mesh_arm_right.Clear();
		mesh_arm_right.SetMaterial(player_material);
		mesh_arm_right.SetVertex(player_arm_right);
		mesh_arm_right.SetIndices(player_IDs);
		mesh_arm_right.SetDirty(SMesh::VERTEX_INDEX);
		mesh_arm_right.SetHardwareMapping(SMesh::STATIC);
		mesh_arm_right.BuildMesh();

		mesh_arm_left.Clear();
		mesh_arm_left.SetMaterial(player_material);
		mesh_arm_left.SetVertex(player_arm_left);
		mesh_arm_left.SetIndices(player_IDs);
		mesh_arm_left.SetDirty(SMesh::VERTEX_INDEX);
		mesh_arm_left.SetHardwareMapping(SMesh::STATIC);
		mesh_arm_left.BuildMesh();
		
		mesh_leg_right.Clear();
		mesh_leg_right.SetMaterial(player_material);
		mesh_leg_right.SetVertex(player_leg_right);
		mesh_leg_right.SetIndices(player_IDs);
		mesh_leg_right.SetDirty(SMesh::VERTEX_INDEX);
		mesh_leg_right.SetHardwareMapping(SMesh::STATIC);
		mesh_leg_right.BuildMesh();
		
		mesh_leg_left.Clear();
		mesh_leg_left.SetMaterial(player_material);
		mesh_leg_left.SetVertex(player_leg_left);
		mesh_leg_left.SetIndices(player_IDs);
		mesh_leg_left.SetDirty(SMesh::VERTEX_INDEX);
		mesh_leg_left.SetHardwareMapping(SMesh::STATIC);
		mesh_leg_left.BuildMesh();
	}

	void MakeNickname()
	{
		MakeNickName(player.getUsername(), mesh_nickname);
	}

    void Update()
    {
        HandleKeyboard();
		UpdatePhysics();
		HandleCamera();
	}

	void HandleCamera()
	{
		CControls@ c = getControls();
		Driver@ d = getDriver();

		if(blob !is null && isWindowActive() && isWindowFocused() && Menu::getMainMenu() is null && !block_menu_open && !IsChatPromptActive() && !scoreboard_open && !Frozen)
		{
			if(!move_mouse)
			{
				Vec2f ScrMid = d.getScreenCenterPos();
				Vec2f dir = (c.getMouseScreenPos() - ScrMid);
				
				dir_x += dir.x*mouse_sensitivity;
				if(dir_x < 0) dir_x += 360;
				dir_x = dir_x % 360;
				dir_y = Maths::Clamp(dir_y-(dir.y*mouse_sensitivity),-90,90);
				
				c.setMousePosition(ScrMid/*-Vec2f(3,26)*/);

				look_dir = Vec3f(	Maths::Sin((dir_x)*piboe)*Maths::Cos(dir_y*piboe),
									Maths::Sin(dir_y*piboe),
									Maths::Cos((dir_x)*piboe)*Maths::Cos(dir_y*piboe));
			}
			else
			{
				c.setMousePosition(d.getScreenCenterPos()/*-Vec2f(3,26)*/);
				move_mouse = false;
			}
			getHUD().HideCursor();
		}
		else
		{
			getHUD().ShowCursor();
			move_mouse = true;
		}

		Vec3f cam_pos = pos+Vec3f(0,eye_height,0);
		Vec3f hit_pos = Vec3f();
		if(thirdperson)
		{
			uint8 check = RaycastPrecise(pos+Vec3f(0,eye_height,0), look_dir*(-1), 7.5, hit_pos, true);
			if(check != 0)
			{
				cam_pos = hit_pos+look_dir*0.35;
			}
		}
		camera.move(cam_pos, false);
		camera.turn(dir_x, dir_y, 0, false);
	}

	void HandleKeyboard()
	{
		CControls@ c = getControls();
		Driver@ d = getDriver();

		if(!Frozen)
		{
			// block menu ---
			if(c.isKeyJustPressed(KEY_KEY_E))
			{
				block_menu_open = !block_menu_open;
				if(!block_menu_open)
				{
					c.setMousePosition(d.getScreenCenterPos());
				}
				else
				{
					for(int i = 0; i < block_menu_blocks.size(); i++)
					{
						if(block_menu_blocks[i] == hand_block)
						{
							picked_block_pos = block_menu_start + Vec2f((i % block_menu_size.x) * block_menu_tile_size.x, int(i / block_menu_size.x) * block_menu_tile_size.y);
							break;
						}
					}
				}
			}
			if(block_menu_open)
			{
				block_menu_mouse = c.getMouseScreenPos()-block_menu_start;
				block_menu_mouse = Vec2f(Maths::Clamp(int(block_menu_mouse.x/block_menu_tile_size.x), 0, block_menu_size.x-1), Maths::Clamp(int(block_menu_mouse.y/block_menu_tile_size.y), 0, block_menu_size.y-1));
				// check for click
				if(blob !is null && blob.isKeyJustPressed(key_action1))
				{
					int index = block_menu_mouse.x + block_menu_mouse.y*block_menu_size.x;
					if(index < block_menu_blocks.size())
					{
						hand_block = block_menu_blocks[index];
						picked_block_pos = block_menu_start + Vec2f((index % block_menu_size.x) * block_menu_tile_size.x, int(index / block_menu_size.x) * block_menu_tile_size.y);
					}
				}
				block_menu_mouse.x *= block_menu_tile_size.x;
				block_menu_mouse.y *= block_menu_tile_size.y;
				block_menu_mouse += block_menu_start;
			}
			// ---

			// player controls ---
			if(blob !is null && isWindowActive() && isWindowFocused() && Menu::getMainMenu() is null && !block_menu_open && !IsChatPromptActive() && !scoreboard_open)
			{
				// block manipulations ---
				{
					draw_block_mouse = false;
					Vec3f hit_pos;
					uint8 check = RaycastWorld(pos+Vec3f(0,eye_height,0), look_dir, arm_distance, hit_pos);
					if(check == Raycast::S_HIT)
					{
						uint8 block_looking_at = world.getBlock(hit_pos.x, hit_pos.y, hit_pos.z);
						draw_block_mouse = true;
						block_mouse_pos = hit_pos;
						//DrawHitbox(int(hit_pos.x), int(hit_pos.y), int(hit_pos.z), 0x88FFC200);
						// block placing ---
						if(blob.isKeyJustPressed(key_action2))
						{
							Vec3f pos_to_place = hit_pos;
							bool place = true;
							if(block_looking_at != Block::grass) // replace grass block instead of building near it
							{
								Vec3f prev_hit_pos;
								check = RaycastWorld_Previous(pos+Vec3f(0,eye_height,0), look_dir, arm_distance, prev_hit_pos);
								if(check == Raycast::S_HIT)
								{
									pos_to_place = prev_hit_pos;
								}
								else
								{
									place = false;
								}
							}
							if(place)
							{
								if(!testAABBAABB(AABB((pos+vel)-Vec3f(player_radius,0,player_radius), (pos+vel)+Vec3f(player_radius,player_height,player_radius)), AABB(pos_to_place, pos_to_place+Vec3f(1,1,1))))
								{
									bool place = true;
									for(int i = 0; i < other_players.size(); i++)
									{
										Vec3f _pos = other_players[i].pos;
										if(testAABBAABB(AABB(_pos-Vec3f(player_radius,0,player_radius), _pos+Vec3f(player_radius,player_height,player_radius)), AABB(pos_to_place, pos_to_place+Vec3f(1,1,1))))
										{
											place = false;
											Sound::Play("NoAmmo.ogg");
											AddSector(AABB(pos_to_place, pos_to_place+Vec3f(1,1,1)), 0x45FF0000, 20);
											AddSector(AABB(_pos-Vec3f(player_radius,0,player_radius), _pos+Vec3f(player_radius,player_height,player_radius)), 0x45FF0000, 20);
											break;
										}
									}
									if(place)
									{
										if(pos_to_place.y >= world.map_height)
										{
											AddUText("Cant build higher than map height limit! ("+world.map_height+" blocks)", 0xFFFF0000, 60);
										}
										else
										{
											client_SetBlock(player, hand_block, pos_to_place);
										}
									}
								}
								else
								{
									Sound::Play("NoAmmo.ogg");
									AddSector(AABB(pos_to_place, pos_to_place+Vec3f(1,1,1)), 0x45FF0000, 20);
									AddSector(AABB(pos-Vec3f(player_radius,0,player_radius), pos+Vec3f(player_radius,player_height,player_radius)), 0x45FF0000, 20);
								}
							}
						}
						// ---

						// block picking ---
						else if(c.isKeyJustPressed(KEY_MBUTTON))
						{
							uint8 block_looking_at = world.getBlock(hit_pos.x, hit_pos.y, hit_pos.z);
							hand_block = block_looking_at;
						}
						// ---

						// block digging ---
						else if(blob.isKeyPressed(key_action1))
						{
							if(digging)
							{
								if(digging_pos == hit_pos)
								{
									dig_timer += Block::dig_speed[block_looking_at];
									if(dig_timer >= max_dig_time)
									{
										client_SetBlock(player, Block::air, hit_pos);
										digging = false;
									}
								}
								else
								{
									digging = false;
								}
							}
							else
							{
								digging = true;
								dig_timer = 0;
								digging_pos = hit_pos;
							}
						}
						// ---
						else if(digging)
						{
							digging = false;
							dig_timer = 0;
						}
					}
					else if(digging)
					{
						digging = false;
						dig_timer = 0;
					}

					/*if(c.isKeyPressed(KEY_KEY_N))
					{
						Vec3f _hit_pos;
						uint8 _check = RaycastWorld(pos+Vec3f(0,eye_height,0), look_dir, 999, _hit_pos);
						if(_check == Raycast::S_HIT)
						{
							//client_SetBlock(player, Block::air, hit_pos);
							for(int _x = -1; _x < 2; _x++)
								for(int _y = -1; _y < 2; _y++)
									for(int _z = -1; _z < 2; _z++)
										client_SetBlock(player, Block::air, _hit_pos+Vec3f(_x,_y,_z));
						}
					}*/
				}
				// ---

				// player movement ---
				{
					moving_vec = Vec3f();
					Crouch = false;
					Run = false;

					if(blob.isKeyPressed(key_up))
					{
						moving_vec.z += 1;
					}
					if(blob.isKeyPressed(key_down))
					{
						moving_vec.z -= 1;
					}
					if(blob.isKeyPressed(key_left))
					{
						moving_vec.x -= 1;
					}
					if(blob.isKeyPressed(key_right))
					{
						moving_vec.x += 1;
					}
					moving_vec.RotateXZ(-dir_x);
					moving_vec.Normalize();
					if(fly)
					{
						if(c.isKeyPressed(KEY_SPACE))
						{
							moving_vec.y += 1;
						}
						if(c.isKeyPressed(KEY_LSHIFT))
						{
							moving_vec.y -= 1;
						}
					}
					else
					{
						if(c.isKeyPressed(KEY_SPACE) && !Jump)
						{
							Jump = true;
						}
						if(c.isKeyPressed(KEY_LSHIFT))
						{
							Crouch = true;
						}
						else if(c.isKeyPressed(KEY_LCONTROL))
						{
							Run = true;
						}
					}
				}
				// ---
			}
			// ---

			// misc
			{
				if(c.isKeyJustPressed(MOUSE_SCROLL_UP) || c.isKeyJustPressed(MOUSE_SCROLL_DOWN))
				{
					if(c.isKeyJustPressed(MOUSE_SCROLL_UP))
					{
						hand_block = Maths::Max(1, hand_block-1);
						while(!Block::allowed_to_build[hand_block])
						{
							hand_block -= 1;
						}
					}
					else if(c.isKeyJustPressed(MOUSE_SCROLL_DOWN))
					{
						hand_block = Maths::Min(Block::blocks_count-2, hand_block+1);
						while(!Block::allowed_to_build[hand_block])
						{
							hand_block += 1;
						}
					}

					for(int i = 0; i < block_menu_blocks.size(); i++)
					{
						if(block_menu_blocks[i] == hand_block)
						{
							picked_block_pos = block_menu_start + Vec2f((i % block_menu_size.x) * block_menu_tile_size.x, int(i / block_menu_size.x) * block_menu_tile_size.y);
							break;
						}
					}
				}
			}
			// ---
		}

		// misc stuff that is also allowed when frozen
		if(c.isKeyJustPressed(KEY_F5))
		{
			thirdperson = !thirdperson;
			/*if(thirdperson)
			{
				getDriver().SetShader("mc_cursor", false);
			}
			else
			{
				getDriver().SetShader("mc_cursor", true);
			}*/
		}

		if(scoreboard_open)
		{
			if(getRules().get_bool("scoreboard_hover"))
			{
				if(blob.isKeyJustPressed(key_action2))
				{
					string name = getRules().get_string("scoreboard_clipboard");
					CopyToClipboard(name);
					AddUText("Copied \""+name+"\" to clipboard!", 0xFF60FF60, 70);
				}
				else if(admin)
				{
					if(blob.isKeyJustPressed(key_action1))
					{
						CPlayer@ pl_hovering;
						getRules().get("scoreboard_player", @pl_hovering);
						if(pl_hovering !is null)
						{
							if(c.isKeyPressed(KEY_LSHIFT))
							{
								if(pl_hovering is getLocalPlayer())
								{
									AddUText("Cant teleport to yourself!", 0xFFFF0000, 50);
								}
								else
								{
									for(int i = 0; i < other_players.size(); i++)
									{
										Player@ _player = other_players[i];
										if(_player.player is pl_hovering)
										{
											pos = _player.pos + Vec3f(0,0.5,0);
											string name = pl_hovering.getUsername();
											AddUText("Teleporting to "+name+"!", 0xFF40FF90, 70);
											break;
										}
									}
								}
							}
							else if(c.isKeyPressed(KEY_F3))
							{
								CBitStream to_send;
								to_send.write_netid(pl_hovering.getNetworkID());
								to_send.write_bool(true);
								getRules().SendCommand(getRules().getCommandID("C_FreezePlayer"), to_send, false);
								AddUText("Frozen "+pl_hovering.getUsername()+"!", 0xFF2050FF, 80);
							}
							else if(c.isKeyPressed(KEY_F2))
							{
								CBitStream to_send;
								to_send.write_netid(pl_hovering.getNetworkID());
								to_send.write_bool(false);
								getRules().SendCommand(getRules().getCommandID("C_FreezePlayer"), to_send, false);
								AddUText("Unfrozen "+pl_hovering.getUsername()+"!", 0xFF2050FF, 80);
							}
						}
					}
				}
			}
		}
		else if(admin)
		{
			if(c.isKeyJustPressed(KEY_XBUTTON2)) fly = !fly;
			else if(c.isKeyJustPressed(KEY_XBUTTON1))
			{
				Vec3f hit_pos;
				uint8 check = RaycastWorld(pos+Vec3f(0,eye_height,0), look_dir, 999, hit_pos);
				if(check == Raycast::S_HIT)
				{
					client_SetBlock(player, Block::air, hit_pos);
				}
			}
			else if(c.isKeyJustPressed(KEY_F8)) hold_frustum = !hold_frustum;
			else if(c.isKeyJustPressed(KEY_F3) || c.isKeyJustPressed(KEY_F2))
			{
				bool freeze = c.isKeyJustPressed(KEY_F3);
				float[] distances;
				for(int i = 0; i < other_players.size(); i++)
				{
					Player@ pl_to_test = other_players[i];
					if(pl_to_test.player is null) continue;
					AABB box(pl_to_test.pos-Vec3f(player_radius, 0, player_radius), pl_to_test.pos+Vec3f(player_radius, player_height, player_radius));
					if(box.intersectsWithLine(camera.pos, look_dir, 50000))
					{
						distances.push_back((pl_to_test.pos - pos).Length());
					}
					else
					{
						distances.push_back(9999999);
					}
				}

				int min_value = 9999999;
				int min_id = 999;
				for(int i = 0; i < distances.size(); i++)
				{
					if(distances[i] < min_value)
					{
						min_value = distances[i];
						min_id = i;
					}
				}

				if(min_id != 999)
				{
					Player@ pl_to_test = other_players[min_id];
					CBitStream to_send;
					to_send.write_netid(pl_to_test.player.getNetworkID());
					to_send.write_bool(freeze);
					getRules().SendCommand(getRules().getCommandID("C_FreezePlayer"), to_send, false);
					AddUText((freeze ? "F" : "Unf")+"rozen "+pl_to_test.player.getUsername()+"!", 0xFF2050FF, 80);
				}
			}
		}
		// ---
	}

	void UpdatePhysics()
	{
		old_pos = pos;
		if(!Frozen)
		{
			float temp_friction = friction;
			float temp_acceleration = acceleration;
			if(fly)
			{
				temp_friction = air_friction;
				temp_acceleration = acceleration*3.0f;
				moving_vec *= temp_acceleration;
				vel += moving_vec;

				vel.x *= temp_friction;
				vel.z *= temp_friction;
				vel.y *= temp_friction;

				pos += vel;
			}
			else
			{
				onGround = false;

				Vec3f[] floor_check = {	Vec3f(pos.x-(player_diameter/2.0f), pos.y-0.0002f, pos.z-(player_diameter/2.0f)),
										Vec3f(pos.x+(player_diameter/2.0f), pos.y-0.0002f, pos.z-(player_diameter/2.0f)),
										Vec3f(pos.x+(player_diameter/2.0f), pos.y-0.0002f, pos.z+(player_diameter/2.0f)),
										Vec3f(pos.x-(player_diameter/2.0f), pos.y-0.0002f, pos.z+(player_diameter/2.0f))};
				
				Vec2f crouching_pos_min = Vec2f(-1, -1);
				Vec2f crouching_pos_max = Vec2f(-1, -1);

				for(int i = 0; i < 4; i++)
				{
					Vec3f temp_pos = floor_check[i];
					if(world.isTileSolid(temp_pos.x, temp_pos.y, temp_pos.z) || temp_pos.y <= 0)
					{
						onGround = true;
						if(crouching_pos_min.x == -1)
						{
							crouching_pos_min.x = int(temp_pos.x);
							crouching_pos_min.y = int(temp_pos.z);
							crouching_pos_max.x = int(temp_pos.x)+1;
							crouching_pos_max.y = int(temp_pos.z)+1;
						}
						else
						{
							crouching_pos_min.x = Maths::Min(int(crouching_pos_min.x), int(temp_pos.x));
							crouching_pos_min.y = Maths::Min(int(crouching_pos_min.y), int(temp_pos.z));
							crouching_pos_max.x = Maths::Max(int(crouching_pos_max.x), int(temp_pos.x)+1);
							crouching_pos_max.y = Maths::Max(int(crouching_pos_max.y), int(temp_pos.z)+1);
						}
					}
				}
				
				if(onGround)
				{
					if(Jump)
					{
						if(!world.isTileSolid(pos.x, pos.y, pos.z))
						{
							vel.y += jump_acceleration;
							onGround = false;
						}
						else
						{
							pos.y = int(pos.y+1);
						}
						Jump = false;
					}
					if(Crouch)
					{
						temp_acceleration *= 0.5f;
					}
					else if(Run)
					{
						temp_acceleration *= 1.8f;
					}
				}
				if(!onGround)
				{
					temp_friction = air_friction;
					vel.y = Maths::Max(vel.y-0.04f, -0.8f);
					Jump = false;
				}
				moving_vec *= temp_acceleration;
				vel += moving_vec;
				vel.x *= temp_friction;
				vel.z *= temp_friction;

				if(vel.x < 0.0001f && vel.x > -0.0001f) vel.x = 0;
				if(vel.y < 0.0001f && vel.y > -0.0001f) vel.y = 0;
				if(vel.z < 0.0001f && vel.z > -0.0001f) vel.z = 0;

				CollisionResponse(pos, vel);

				if(Crouch && onGround)
				{
					crouching_pos_min.x -= player_radius-0.01f;
					crouching_pos_min.y -= player_radius-0.01f;
					crouching_pos_max.x += player_radius-0.01f;
					crouching_pos_max.y += player_radius-0.01f;
					pos = Vec3f(Maths::Clamp(pos.x, crouching_pos_min.x, crouching_pos_max.x), pos.y, Maths::Clamp(pos.z, crouching_pos_min.y, crouching_pos_max.y));
				}
			}
		}
	}

	void RenderUpdate()
	{
		render_pos = old_pos.Lerp(pos, getInterFrameTime());
	}

	void RenderPlayer()
	{
		if(Frozen)
		{
			player_frozen_material.SetVideoMaterial();
		}
		else
		{
			player_material.SetVideoMaterial();
		}
		
		float[] model_matr;
		Matrix::MakeIdentity(model_matr);
		Matrix::SetTranslation(model_matr, render_pos.x, render_pos.y, render_pos.z);
		Matrix::SetRotationDegrees(model_matr, 0, dir_x, 0);
		Render::SetModelTransform(model_matr);
		mesh_body.RenderMesh();

		Matrix::SetTranslation(model_matr, render_pos.x, render_pos.y+1.5f, render_pos.z);
		Matrix::SetRotationDegrees(model_matr, -dir_y, dir_x, 0);
		Render::SetModelTransform(model_matr);
		mesh_head.RenderMesh();

		f32 vem_mult = Maths::Min(Maths::Pow(vel.Length()*30.0f, 1.75f), 75);
		f32 limb_rotation = Maths::Cos(getInterGameTime()/3.5f)*vem_mult;

		Matrix::SetRotationDegrees(model_matr, limb_rotation, dir_x, 0);
		Render::SetModelTransform(model_matr);
		mesh_arm_left.RenderMesh();
		Matrix::SetRotationDegrees(model_matr, -limb_rotation, dir_x, 0);
		Render::SetModelTransform(model_matr);
		mesh_arm_right.RenderMesh();

		Matrix::SetTranslation(model_matr, render_pos.x, render_pos.y+0.75f, render_pos.z);
		Matrix::SetRotationDegrees(model_matr, limb_rotation, dir_x, 0);
		Render::SetModelTransform(model_matr);
		mesh_leg_left.RenderMesh();
		Matrix::SetRotationDegrees(model_matr, -limb_rotation, dir_x, 0);
		Render::SetModelTransform(model_matr);
		mesh_leg_right.RenderMesh();
	}

	void RenderNickname()
	{
		float[] billboard_model;
		Matrix::MakeIdentity(billboard_model);
		Matrix::SetTranslation(billboard_model, render_pos.x, render_pos.y+player_height+0.4f, render_pos.z);
		Matrix::SetRotationDegrees(billboard_model, -camera.interpolated_dir_y, camera.interpolated_dir_x, 0);
		Render::SetModelTransform(billboard_model);
		Render::SetAlphaBlend(true);
		mesh_nickname.RenderMeshWithMaterial();
		Render::SetAlphaBlend(false);
	}

	void Serialize(CBitStream@ to_send)
	{
		to_send.write_netid(player.getNetworkID());
		to_send.write_f32(pos.x);
		to_send.write_f32(pos.y);
		to_send.write_f32(pos.z);
		to_send.write_f32(vel.x);
		to_send.write_f32(vel.y);
		to_send.write_f32(vel.z);
		to_send.write_f32(dir_x);
		to_send.write_f32(dir_y);
		to_send.write_bool(Crouch);
		to_send.write_bool(digging);
		if(digging)
		{
			to_send.write_f32(digging_pos.x);
			to_send.write_f32(digging_pos.y);
			to_send.write_f32(digging_pos.z);
			to_send.write_f32(dig_timer);
		}
	}

	void UnSerialize(CBitStream@ received)
	{
		old_pos = pos;
		pos.x = received.read_f32();
		pos.y = received.read_f32();
		pos.z = received.read_f32();
		vel.x = received.read_f32();
		vel.y = received.read_f32();
		vel.z = received.read_f32();
		dir_x = received.read_f32();
		dir_y = received.read_f32();
		Crouch = received.read_bool();
		digging = received.read_bool();
		if(digging)
		{
			digging_pos.x = received.read_f32();
			digging_pos.y = received.read_f32();
			digging_pos.z = received.read_f32();
			dig_timer = received.read_f32();
		}
	}

	void RenderDiggingBlock(Vertex[]&inout verts)
	{
		float u = float(int((dig_timer / max_dig_time) * 8.0f)) / 8.0f;
		float u_step = 1.0f / 8.0f + u;
		float s = 0.02f;
		
		verts.push_back(Vertex(digging_pos.x-s,		digging_pos.y-s,	digging_pos.z-s,	u,	1,	color_white));
		verts.push_back(Vertex(digging_pos.x-s,		digging_pos.y+1+s,	digging_pos.z-s,	u,	0,	color_white));
		verts.push_back(Vertex(digging_pos.x+1+s,	digging_pos.y+1+s,	digging_pos.z-s,	u_step,	0,	color_white));
		verts.push_back(Vertex(digging_pos.x+1+s,	digging_pos.y-s,	digging_pos.z-s,	u_step,	1,	color_white));

		verts.push_back(Vertex(digging_pos.x+1+s,	digging_pos.y-s,	digging_pos.z+1+s,	u,	1,	color_white));
		verts.push_back(Vertex(digging_pos.x+1+s,	digging_pos.y+1+s,	digging_pos.z+1+s,	u,	0,	color_white));
		verts.push_back(Vertex(digging_pos.x-s,		digging_pos.y+1+s,	digging_pos.z+1+s,	u_step,	0,	color_white));
		verts.push_back(Vertex(digging_pos.x-s,		digging_pos.y-s,	digging_pos.z+1+s,	u_step,	1,	color_white));

		verts.push_back(Vertex(digging_pos.x-s,		digging_pos.y-s,	digging_pos.z+1+s,	u,	1,	color_white));
		verts.push_back(Vertex(digging_pos.x-s,		digging_pos.y+1+s,	digging_pos.z+1+s,	u,	0,	color_white));
		verts.push_back(Vertex(digging_pos.x-s,		digging_pos.y+1+s,	digging_pos.z-s,	u_step,	0,	color_white));
		verts.push_back(Vertex(digging_pos.x-s,		digging_pos.y-s,	digging_pos.z-s,	u_step,	1,	color_white));

		verts.push_back(Vertex(digging_pos.x+1+s,	digging_pos.y-s,	digging_pos.z-s,	u,	1,	color_white));
		verts.push_back(Vertex(digging_pos.x+1+s,	digging_pos.y+1+s,	digging_pos.z-s,	u,	0,	color_white));
		verts.push_back(Vertex(digging_pos.x+1+s,	digging_pos.y+1+s,	digging_pos.z+1+s,	u_step,	0,	color_white));
		verts.push_back(Vertex(digging_pos.x+1+s,	digging_pos.y-s,	digging_pos.z+1+s,	u_step,	1,	color_white));

		verts.push_back(Vertex(digging_pos.x-s,		digging_pos.y+1+s,	digging_pos.z-s,	u,	1,	color_white));
		verts.push_back(Vertex(digging_pos.x-s,		digging_pos.y+1+s,	digging_pos.z+1+s,	u,	0,	color_white));
		verts.push_back(Vertex(digging_pos.x+1+s,	digging_pos.y+1+s,	digging_pos.z+1+s,	u_step,	0,	color_white));
		verts.push_back(Vertex(digging_pos.x+1+s,	digging_pos.y+1+s,	digging_pos.z-s,	u_step,	1,	color_white));

		verts.push_back(Vertex(digging_pos.x-s,		digging_pos.y-s,	digging_pos.z+1+s,	u,	1,	color_white));
		verts.push_back(Vertex(digging_pos.x-s,		digging_pos.y-s,	digging_pos.z-s,	u,	0,	color_white));
		verts.push_back(Vertex(digging_pos.x+1+s,	digging_pos.y-s,	digging_pos.z-s,	u_step,	0,	color_white));
		verts.push_back(Vertex(digging_pos.x+1+s,	digging_pos.y-s,	digging_pos.z+1+s,	u_step,	1,	color_white));
	}

	void RenderHandBlock()
	{
		float u1 = Block::u_sides_start[hand_block];
		float u2 = Block::u_sides_end[hand_block];
		float v1 = Block::v_sides_start[hand_block];
		float v2 = Block::v_sides_end[hand_block];

		Vec2f screen_pos = Vec2f(80, 140);
		Vec2f scale = Vec2f(150,150);

		Vertex[] verts;

		if(Block::plant[hand_block])
		{
			verts.push_back(Vertex(screen_pos.x-scale.x*0.34f,	screen_pos.y+scale.y*0.34f, 0, u1,	v2,	top_scol));
			verts.push_back(Vertex(screen_pos.x-scale.x*0.34f,	screen_pos.y-scale.y*0.34f, 0, u1,	v1,	top_scol));
			verts.push_back(Vertex(screen_pos.x+scale.x*0.34f,	screen_pos.y-scale.y*0.34f, 0, u2,	v1,	top_scol));
			verts.push_back(Vertex(screen_pos.x+scale.x*0.34f,	screen_pos.y+scale.y*0.34f, 0, u2,	v2,	top_scol));
		}
		else
		{
			verts.push_back(Vertex(screen_pos.x-scale.x*0.35f,	screen_pos.y+scale.y*0.27f-scale.y*0.05f,	0, u1,	v2,	front_scol));
			verts.push_back(Vertex(screen_pos.x-scale.x*0.35f,	screen_pos.y-scale.y*0.18f,					0, u1,	v1,	front_scol));
			verts.push_back(Vertex(screen_pos.x, 				screen_pos.y,								0, u2,	v1,	front_scol));
			verts.push_back(Vertex(screen_pos.x,				screen_pos.y+scale.y*0.45f-scale.y*0.05f,	0, u2,	v2,	front_scol));

			verts.push_back(Vertex(screen_pos.x,				screen_pos.y+scale.y*0.45f-scale.y*0.05f,	0, u1,	v2,	left_scol));
			verts.push_back(Vertex(screen_pos.x,				screen_pos.y,								0, u1,	v1,	left_scol));
			verts.push_back(Vertex(screen_pos.x+scale.x*0.35f, 	screen_pos.y-scale.y*0.18f,					0, u2,	v1,	left_scol));
			verts.push_back(Vertex(screen_pos.x+scale.x*0.35f,	screen_pos.y+scale.y*0.27f-scale.y*0.05f,	0, u2,	v2,	left_scol));

			u1 = Block::u_top_start[hand_block];
			u2 = Block::u_top_end[hand_block];
			v1 = Block::v_top_start[hand_block];
			v2 = Block::v_top_end[hand_block];

			verts.push_back(Vertex(screen_pos.x-scale.x*0.35f,	screen_pos.y-scale.y*0.18f,	0, u1,	v1,	top_scol));
			verts.push_back(Vertex(screen_pos.x,				screen_pos.y-scale.y*0.36f,	0, u2,	v1,	top_scol));
			verts.push_back(Vertex(screen_pos.x+scale.x*0.35f,	screen_pos.y-scale.y*0.18f,	0, u2,	v2,	top_scol));
			verts.push_back(Vertex(screen_pos.x,				screen_pos.y,				0, u1,	v2,	top_scol));
		}

		Render::RawQuads("Block_Textures", verts);
	}

	void GenerateBlockMenu()
	{
		block_menu_blocks.clear();
		block_menu_verts.clear();
		int len = block_menu_size.x*block_menu_size.y;
		Vec2f screen_mid = getDriver().getScreenCenterPos();
		block_menu_start = screen_mid-Vec2f(block_menu_size.x/2.0f*block_menu_tile_size.x, block_menu_size.y/2.0f*block_menu_tile_size.y);
		block_menu_end = screen_mid+Vec2f(block_menu_size.x/2.0f*block_menu_tile_size.x, block_menu_size.y/2.0f*block_menu_tile_size.y);
		uint8 pos_index = 0;

		for(int i = 0; i < len; i++)
		{
			if(i >= Block::blocks_count)
			{
				return;
			}
			if((!Block::allowed_to_build[i] && !admin) || i == 0)
			{
				continue;
			}
			addBlockToMenu(Vec2f(((pos_index % block_menu_size.x) - block_menu_size.x/2)*block_menu_tile_size.x + screen_mid.x, (int(pos_index / int(block_menu_size.x)) - block_menu_size.y/2)*block_menu_tile_size.y + screen_mid.y) + Vec2f((block_menu_tile_size.x/2), (block_menu_tile_size.y/2)), i);
			block_menu_blocks.push_back(i);
			pos_index++;
		}
	}

	void addBlockToMenu(Vec2f pos, uint8 id)
	{
		if(Block::plant[id])
		{
			float u1 = Block::u_sides_start[id];
			float u2 = Block::u_sides_end[id];
			float v1 = Block::v_sides_start[id];
			float v2 = Block::v_sides_end[id];
			
			block_menu_verts.push_back(Vertex(pos.x-block_menu_icon_size.x*0.34f,	pos.y+block_menu_icon_size.y*0.34f, 0, u1,	v2,	top_scol));
			block_menu_verts.push_back(Vertex(pos.x-block_menu_icon_size.x*0.34f,	pos.y-block_menu_icon_size.y*0.34f, 0, u1,	v1,	top_scol));
			block_menu_verts.push_back(Vertex(pos.x+block_menu_icon_size.x*0.34f,	pos.y-block_menu_icon_size.y*0.34f, 0, u2,	v1,	top_scol));
			block_menu_verts.push_back(Vertex(pos.x+block_menu_icon_size.x*0.34f,	pos.y+block_menu_icon_size.y*0.34f, 0, u2,	v2,	top_scol));
		}
		else
		{
			float u1 = Block::u_sides_start[id];
			float u2 = Block::u_sides_end[id];
			float v1 = Block::v_sides_start[id];
			float v2 = Block::v_sides_end[id];
			
			block_menu_verts.push_back(Vertex(pos.x-block_menu_icon_size.x*0.35f,	pos.y+block_menu_icon_size.y*0.27f-block_menu_icon_size.y*0.05f,	0, u1,	v2,	front_scol));
			block_menu_verts.push_back(Vertex(pos.x-block_menu_icon_size.x*0.35f,	pos.y-block_menu_icon_size.y*0.18f,									0, u1,	v1,	front_scol));
			block_menu_verts.push_back(Vertex(pos.x, 								pos.y,																0, u2,	v1,	front_scol));
			block_menu_verts.push_back(Vertex(pos.x,								pos.y+block_menu_icon_size.y*0.45f-block_menu_icon_size.y*0.05f,	0, u2,	v2,	front_scol));

			block_menu_verts.push_back(Vertex(pos.x,								pos.y+block_menu_icon_size.y*0.45f-block_menu_icon_size.y*0.05f,	0, u1,	v2,	left_scol));
			block_menu_verts.push_back(Vertex(pos.x,								pos.y,																0, u1,	v1,	left_scol));
			block_menu_verts.push_back(Vertex(pos.x+block_menu_icon_size.x*0.35f, 	pos.y-block_menu_icon_size.y*0.18f,									0, u2,	v1,	left_scol));
			block_menu_verts.push_back(Vertex(pos.x+block_menu_icon_size.x*0.35f,	pos.y+block_menu_icon_size.y*0.27f-block_menu_icon_size.y*0.05f,	0, u2,	v2,	left_scol));

			u1 = Block::u_top_start[id];
			u2 = Block::u_top_end[id];
			v1 = Block::v_top_start[id];
			v2 = Block::v_top_end[id];

			block_menu_verts.push_back(Vertex(pos.x-block_menu_icon_size.x*0.35f,	pos.y-block_menu_icon_size.y*0.18f, 0, u1,	v1,	top_scol));
			block_menu_verts.push_back(Vertex(pos.x,								pos.y-block_menu_icon_size.y*0.36f, 0, u2,	v1,	top_scol));
			block_menu_verts.push_back(Vertex(pos.x+block_menu_icon_size.x*0.35f,	pos.y-block_menu_icon_size.y*0.18f, 0, u2,	v2,	top_scol));
			block_menu_verts.push_back(Vertex(pos.x,								pos.y,								0, u1,	v2,	top_scol));
		}
	}
}

void CollisionResponse(Vec3f&inout position, Vec3f&inout velocity)
{
	//x collision
	Vec3f xPosition(position.x + velocity.x, position.y, position.z);
	if (isColliding(position, xPosition))
	{
		if (velocity.x > 0)
		{
			position.x = Maths::Ceil(position.x + player_radius) - player_radius - 0.0001f;
		}
		else if (velocity.x < 0)
		{
			position.x = Maths::Floor(position.x - player_radius) + player_radius + 0.0001f;
		}
		velocity.x = 0;
	}
	position.x += velocity.x;

	//z collision
	Vec3f zPosition(position.x, position.y, position.z + velocity.z);
	if (isColliding(position, zPosition))
	{
		if (velocity.z > 0)
		{
			position.z = Maths::Ceil(position.z + player_radius) - player_radius - 0.0001f;
		}
		else if (velocity.z < 0)
		{
			position.z = Maths::Floor(position.z - player_radius) + player_radius + 0.0001f;
		}
		velocity.z = 0;
	}
	position.z += velocity.z;

	//y collision
	Vec3f yPosition(position.x, position.y + velocity.y, position.z);
	if (isColliding(position, yPosition))
	{
		if (velocity.y > 0)
		{
			position.y = Maths::Ceil(position.y + player_height) - player_height - 0.0001f;
		}
		else if (velocity.y < 0)
		{
			position.y = Maths::Floor(position.y) + 0.0001f;
		}
		velocity.y = 0;
	}
	position.y += velocity.y;
}

bool isColliding(const Vec3f&in position, const Vec3f&in next_position)
{
	float x_negative = next_position.x - player_radius; if(x_negative < 0) x_negative -= 1;
	int x_end = next_position.x + player_radius;
	float z_negative = next_position.z - player_radius; if(z_negative < 0) z_negative -= 1;
	int z_end = next_position.z + player_radius;
	float y_negative = next_position.y; if(y_negative < 0) y_negative -= 1;
	int y_end = next_position.y + player_height;

	for (int y = y_negative; y <= y_end; y++)
	{
		for (int z = z_negative; z <= z_end; z++)
		{
			for (int x = x_negative; x <= x_end; x++)
			{
				if ( //ignore voxels the player is currently inside
					x >= Maths::Floor(position.x - player_diameter / 2.0f) && x < Maths::Ceil(position.x + player_diameter / 2.0f) &&
					y >= Maths::Floor(position.y) && y < Maths::Ceil(position.y + player_height) &&
					z >= Maths::Floor(position.z - player_diameter / 2.0f) && z < Maths::Ceil(position.z + player_diameter / 2.0f))
				{
					// dont actually ignore, try pushing away (meh, later) maybe not here then
					continue;
				}

				if (world.isTileSolidOrOOBIgnoreHeight(x, y, z))
				{
					//DrawHitbox(x, y, z, 0x8800FF00);
					return true;
				}
			}
		}
	}
	return false;
}