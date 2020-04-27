
class ServerPlayer
{
    CPlayer@ player;
    Vec3f pos;
    float dir_x = 0.01f;
	float dir_y = 0.01f;
	bool Crouch = false;
    bool Frozen = false;

    ServerPlayer(){}

    void SetPlayer(CPlayer@ _player)
	{
		@player = @_player;
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
		pos.x = received.read_f32();
		pos.y = received.read_f32();
		pos.z = received.read_f32();
		dir_x = received.read_f32();
		dir_y = received.read_f32();
		Crouch = received.read_bool();
	}
}