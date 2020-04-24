
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
			ready_unser = false;
			got_packets = 0;
			gf_packet = 0;
			Debug("Asking for map.");
			CBitStream to_send;
			to_send.write_netid(getLocalPlayer().getNetworkID());
			this.SendCommand(this.getCommandID("C_RequestMap"), to_send, false);
			ask_map = true;
			ask_map_in = 0;
		}
		return true;
	}
	if(!map_ready)
	{
		if(got_packets >= amount_of_packets)
		{
			map_ready = true;
		}
		else if(ready_unser)
		{
			ready_unser = false;
			world.UnSerialize(got_packets);
			got_packets++;
			CBitStream to_send;
			to_send.write_netid(getLocalPlayer().getNetworkID());
			this.SendCommand(this.getCommandID("C_ReceivedMapPacket"), to_send, false);
			ask_map_in = 0;
		}
		return true;
	}
	else if(!map_renderable)
	{
		if(!faces_generated)
		{
			if(gf_packet == 0)
			{
				Debug("Generating block faces.");
				world.FacesSetUp();
			}
			if(gf_packet < gf_amount_of_packets)
			{
				world.GenerateBlockFaces(gf_packet);
				gf_packet++;
				Debug(gf_packet+"/"+gf_amount_of_packets+".", 3);
			}
			else
			{
				Debug("Done.");
				faces_generated = true;
			}
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
        //Camera _cam();
        //@cam = @_cam;
        //@my_player.cam = @cam;
		Player _my_player();
        @my_player = @_my_player;
        my_player.pos = Vec3f(map_width/2, map_height-4, map_depth/2);
		my_player.SetBlob(getLocalPlayerBlob());
		my_player.SetPlayer(getLocalPlayer());
        player_ready = true;
		Render::addScript(Render::layer_background, "Client.as", "Render", 1);
    }
    return false;
}