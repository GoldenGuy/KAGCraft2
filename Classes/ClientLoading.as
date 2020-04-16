
bool ask_map = false;
bool map_ready = false;
bool map_renderable = false;
bool faces_generated = false;
bool player_ready = false;
int intro = 0; // later...
int ask_map_in = 0;

bool isLoading(CRules@ this)
{
    if(!ask_map)
	{
		ask_map_in++;
		if(ask_map_in == 15)
		{
			Debug("Asking for map.");
			CBitStream to_send;
			to_send.write_netid(getLocalPlayer().getNetworkID());
			this.SendCommand(this.getCommandID("C_RequestMap"), to_send, true);
			ask_map = true;
		}
		return true;
	}
	if(!map_ready)
	{
		if(got_packets >= 2)
		{
			map_ready = true;
		}
		else if(map_packets.size() > 0)
		{
			CBitStream@ packet = @map_packets[0];
			world.UnSerialize(@packet, got_packets);
			map_packets.removeAt(0);
			got_packets++;
		}
		return true;
	}
	else if(!map_renderable)
	{
		if(!faces_generated)
		{
			Debug("Generating block faces.");
			world.GenerateBlockFaces();
			Debug("Done.");
			faces_generated = true;
			return true;
		}
		else
		{
			Debug("Setting up chunks.");
            world.SetUpChunks();
            Debug("Done.");
			SetUpTree();
			map_renderable = true;
			return true;
		}
	}
    else if(!player_ready)
    {
        Camera _cam();
        @cam = @_cam;
        @player.cam = @cam;
        player.pos = Vec3f(0,0,0);//Vec3f(map_width/2, map_height, map_depth/2);
		player.SetBlob(getLocalPlayerBlob());
        player_ready = true;
		Render::addScript(Render::layer_background, "Client.as", "Render", 1);
    }
    return false;
}