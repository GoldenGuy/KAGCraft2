
class Player
{
    Vec3f pos, vel;
    f32 friction = 0.2f, air_friction = 0.09f, gravity = 0.1f;
    bool onGround = false;
    Camera@ cam;
}