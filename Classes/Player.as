
class Player
{
    Vec3f pos, vel;
    f32 friction = 0.2f, air_friction = 0.09f, gravity = 0.1f;
    bool onGround = false;
    Camera@ cam;

    void Update()
    {
        cam.tick_update();
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
		}
		cam.move(Vec3f(0,50,0), false);
		cam.turn(dir_x, dir_y, 0, false);
    }
}