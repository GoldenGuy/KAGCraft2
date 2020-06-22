
void Sound3D(string name, Vec3f pos, float vol = 1.0f, float pitch = 1.0f)
{
    Vec2f player_pos(camera.pos.x, camera.pos.z);
    Vec2f sound_pos(pos.x, pos.z);
    Vec2f real_pos = (sound_pos - player_pos).RotateByDegrees(camera.dir_x);
    real_pos *= 50;

    Sound::Play(name, real_pos, vol, pitch);
}