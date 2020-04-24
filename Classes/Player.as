
const float acceleration = 0.04f;
const float jump_acceleration = 0.35f;
const float friction = 0.8f;
const float air_friction = 0.9f;
const float eye_height = 1.7f;
const float player_height = 1.85f;
const float player_radius = 0.35f;
const float player_diameter = player_radius*2;
bool fly = true;
bool hold_frustum = false;
float sensitivity = 0.16;

class Player
{
    Vec3f pos, vel, old_pos;
	CBlob@ blob;
	CPlayer@ player;
    bool onGround = false;
	bool Crouch = false;
	bool Frozen = false;
    //Camera@ camera;
	f32 dir_x = 0.01f;
	f32 dir_y = 0.01f;
	Vec3f look_dir;

	Player(){}

	void SetBlob(CBlob@ _blob)
	{
		@blob = @_blob;
	}

	void SetPlayer(CPlayer@ _player)
	{
		@player = @_player;
	}

    void Update()
    {
        f32 temp_friction = friction;
		
		CControls@ c = getControls();
		Driver@ d = getDriver();
		if(blob !is null && d !is null && c !is null && isWindowActive() && isWindowFocused() && Menu::getMainMenu() is null)
		{
			Vec2f ScrMid = Vec2f(f32(getScreenWidth()) / 2.0f, f32(getScreenHeight()) / 2.0f);
			Vec2f dir = (c.getMouseScreenPos() - ScrMid);
			
			dir_x += dir.x*sensitivity;
			if(dir_x < 0) dir_x += 360;
			dir_x = dir_x % 360;
			dir_y = Maths::Clamp(dir_y-(dir.y*sensitivity),-90,90);
			
			Vec2f asuREEEEEE = /*Vec2f(3,26);*/Vec2f(0,0);
			c.setMousePosition(ScrMid-asuREEEEEE);

			look_dir = Vec3f(	Maths::Sin((dir_x)*piboe)*Maths::Cos(dir_y*piboe),
								Maths::Sin(dir_y*piboe),
								Maths::Cos((dir_x)*piboe)*Maths::Cos(dir_y*piboe));

			if(c.isKeyJustPressed(KEY_XBUTTON2)) fly = !fly;
			if(c.isKeyJustPressed(KEY_XBUTTON1)) hold_frustum = !hold_frustum;

			{
				Vec3f hit_pos;
				u8 check = RaycastWorld(camera.pos, look_dir, 40, hit_pos);
				if(check == Raycast::S_HIT)
				{
					DrawHitbox(int(hit_pos.x), int(hit_pos.y), int(hit_pos.z), 0x88FFC200);
					if(blob.isKeyPressed(key_action1))
					{
						server_SetBlock(block_air, hit_pos);
					}
				}
			}
			
			if(fly)
			{
				Vec3f vel_dir;
				
				if(blob.isKeyPressed(key_up))
				{
					vel_dir.z += 1;
				}
				if(blob.isKeyPressed(key_down))
				{
					vel_dir.z -= 1;
				}
				if(blob.isKeyPressed(key_left))
				{
					vel_dir.x -= 1;
				}
				if(blob.isKeyPressed(key_right))
				{
					vel_dir.x += 1;
				}

				f32 temp_acceleration = acceleration*6.0f;

				vel_dir.RotateXZ(-dir_x);
				vel_dir.Normalize();
				vel_dir *= temp_acceleration;

				vel += vel_dir;

				if(c.isKeyPressed(KEY_SPACE))
				{
					vel.y += temp_acceleration;
				}
				if(c.isKeyPressed(KEY_LSHIFT))
				{
					vel.y -= temp_acceleration;
				}
			}
			else // do actual movement here
			{
				Vec3f vel_dir;
				
				if(blob.isKeyPressed(key_up))
				{
					vel_dir.z += 1;
				}
				if(blob.isKeyPressed(key_down))
				{
					vel_dir.z -= 1;
				}
				if(blob.isKeyPressed(key_left))
				{
					vel_dir.x -= 1;
				}
				if(blob.isKeyPressed(key_right))
				{
					vel_dir.x += 1;
				}

				f32 temp_acceleration = acceleration;

				Crouch = false;

				if(onGround)
				{
					if(c.isKeyPressed(KEY_SPACE))
					{
						vel.y += jump_acceleration;
						onGround = false;
					}
					else if(c.isKeyPressed(KEY_LSHIFT))
					{
						Crouch = true;
					}
				}
				else
				{
					temp_friction = air_friction;
				}

				vel_dir.RotateXZ(-dir_x);
				vel_dir.Normalize();
				vel_dir *= temp_acceleration;

				vel += vel_dir;
			}

			if(c.isKeyJustPressed(KEY_KEY_R))
			{
				for(int i = 0; i < chunks_to_render.size(); i++)
				{
					Chunk@ chunk = chunks_to_render[i];
					chunk.rebuild = true;
				}
			}
		}

		if(fly)
		{
			vel.x *= friction;
			vel.z *= friction;
			vel.y *= friction;
		}
		else
		{
			vel.x *= temp_friction;
			vel.z *= temp_friction;

			if(!onGround)
			{
				vel.y = Maths::Max(vel.y-0.04f, -0.3f);
			}
		}

		CollisionResponse(@pos, @vel);

		//pos = Vec3f(Maths::Clamp(pos.x, player_diameter/1.9f, map_width-player_diameter/1.9f), Maths::Clamp(pos.y, 0, map_height-player_height), Maths::Clamp(pos.z, player_diameter/1.9f, map_depth-player_diameter/1.9f));

		onGround = false;

		Vec3f[] floor_check = {	Vec3f(pos.x-(player_diameter/2.0f), pos.y-0.0002f, pos.z-(player_diameter/2.0f)),
								Vec3f(pos.x+(player_diameter/2.0f), pos.y-0.0002f, pos.z-(player_diameter/2.0f)),
								Vec3f(pos.x+(player_diameter/2.0f), pos.y-0.0002f, pos.z+(player_diameter/2.0f)),
								Vec3f(pos.x-(player_diameter/2.0f), pos.y-0.0002f, pos.z+(player_diameter/2.0f))};
		
		for(int i = 0; i < 4; i++)
		{
			Vec3f temp_pos = floor_check[i];
			if(world.isTileSolid(temp_pos.x, temp_pos.y, temp_pos.z) || temp_pos.y <= 0)
			{
				DrawHitbox(int(temp_pos.x), int(temp_pos.y), int(temp_pos.z), 0x8800FF00);
				onGround = true;
				break;
			}
		}

		f32 vel_len = vel.Length();

		if(vel.x < 0.0001f && vel.x > -0.0001f) vel.x = 0;
		if(vel.y < 0.0001f && vel.y > -0.0001f) vel.y = 0;
		if(vel.z < 0.0001f && vel.z > -0.0001f) vel.z = 0;
		
		camera.move(pos+Vec3f(0,eye_height,0), false);
		camera.turn(dir_x, dir_y, 0, false);
		camera.tick_update();
    }

	void Serialize(CBitStream@ to_send)
	{
		to_send.write_netid(player.getNetworkID());
		to_send.write_f32(pos.x);
		to_send.write_f32(pos.y);
		to_send.write_f32(pos.z);
		to_send.write_f32(dir_x);
		to_send.write_f32(dir_y);
		to_send.write_bool(Crouch);
	}

	void UnSerialize(CBitStream@ received)
	{
		old_pos = pos;
		pos.x = received.read_f32();
		pos.y = received.read_f32();
		pos.z = received.read_f32();
		dir_x = received.read_f32();
		dir_y = received.read_f32();
		Crouch = received.read_bool();
	}
}

void CollisionResponse(Vec3f @position, Vec3f @velocity)
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

bool isColliding(Vec3f position, Vec3f next_position)
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
					// dont actually ignore, try pushing away (meh, later)
					continue;
				}

				if (world.isTileSolidOrOOB(x, y, z))
				{
					DrawHitbox(x, y, z, 0x8800FF00);
					return true;
				}
				else
				{
					DrawHitbox(x, y, z, 0x88FF0000);
				}
			}
		}
	}
	return false;
}