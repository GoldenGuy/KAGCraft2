
const float acceleration = 0.04f;
const float friction = 0.8f;
const float air_friction = 0.12f;
const float cam_height = 1.7f;
const float player_height = 1.85f;
const float player_radius = 0.35f;
const float player_diameter = player_radius*2;

//vel.y = Maths::Max(vel.y-0.08f, -0.5f); // gravity

class Player
{
    Vec3f pos, vel;
	CBlob@ blob;
    bool onGround = false;
    Camera@ cam;
	f32 dir_x = 0.01f;
	f32 dir_y = 0.01f;

	void SetBlob(CBlob@ _blob)
	{
		@blob = @_blob;
	}

    void Update()
    {
        CControls@ c = getControls();
		Driver@ d = getDriver();
		if(d !is null && c !is null && isWindowActive() && isWindowFocused() && Menu::getMainMenu() is null)
		{
			Vec2f ScrMid = Vec2f(f32(getScreenWidth()) / 2.0f, f32(getScreenHeight()) / 2.0f);
			Vec2f dir = (c.getMouseScreenPos() - ScrMid);
			
			dir_x += dir.x*sensitivity;
			dir_y = Maths::Clamp(dir_y-(dir.y*sensitivity),-90,90);
			
			Vec2f asuREEEEEE = /*Vec2f(3,26);*/Vec2f(0,0);
			c.setMousePosition(ScrMid-asuREEEEEE);

			if(blob.isKeyPressed(key_up))
			{
				vel.z += Maths::Cos(dir_x*Maths::Pi/180)*acceleration;
				vel.x += Maths::Sin(dir_x*Maths::Pi/180)*acceleration;
			}
			if(blob.isKeyPressed(key_down))
			{
				vel.z -= Maths::Cos(dir_x*Maths::Pi/180)*acceleration;
				vel.x -= Maths::Sin(dir_x*Maths::Pi/180)*acceleration;
			}
			if(blob.isKeyPressed(key_left))
			{
				vel.z -= Maths::Sin(-dir_x*Maths::Pi/180)*acceleration;
				vel.x -= Maths::Cos(dir_x*Maths::Pi/180)*acceleration;
			}
			if(blob.isKeyPressed(key_right))
			{
				vel.z += Maths::Sin(-dir_x*Maths::Pi/180)*acceleration;
				vel.x += Maths::Cos(dir_x*Maths::Pi/180)*acceleration;
			}

			if(c.isKeyPressed(KEY_SPACE))
			{
				vel.y += acceleration;
			}
			if(c.isKeyPressed(KEY_LSHIFT))
			{
				vel.y -= acceleration;
			}
		}

		//physics here
		vel.x *= friction;
		vel.z *= friction;
		vel.y *= friction; // temp, for flying
		f32 vel_len = vel.Length();
		pos += vel;
		//------------
		
		cam.move(pos+Vec3f(0,0,0), false);
		cam.turn(dir_x, dir_y, 0, false);
		cam.tick_update();
    }
}