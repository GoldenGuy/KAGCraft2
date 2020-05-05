
class ServerPlayer
{
    CPlayer@ player;
    Vec3f pos;
    float dir_x = 0.01f;
	float dir_y = 0.01f;
	bool Crouch = false;
    bool Frozen = false;
	bool digging = false;
	Vec3f digging_pos;
	uint dig_timer;
	uint8 hand_block = Block::stone;

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
		pos.x = received.read_f32();
		pos.y = received.read_f32();
		pos.z = received.read_f32();
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
}

ServerPlayer@ getServerPlayer(CPlayer@ player)
{
	for(int i = 0; i < players.size(); i++)
	{
		if(players[i].player is player)
		{
			return @players[i];
		}
	}
	return null;
}