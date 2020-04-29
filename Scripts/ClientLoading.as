
bool ask_map = false;
bool map_ready = false;
bool map_renderable = false;
bool faces_generated = false;
bool chunks_set_up = false;
bool tree_set_up = false;
bool player_ready = false;
int intro = 0; // later...
int ask_map_in = 0;

string loading_string;

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
			loading_string = "Asking for map.";
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
		if(ready_unser)
		{
			ready_unser = false;
			world.UnSerialize(got_packets);
			got_packets++;
			loading_string = "Unserializing map packet. "+got_packets+"/"+amount_of_packets;
			if(got_packets >= amount_of_packets)
			{
				loading_string = "Generating block faces.";
				map_ready = true;
				return true;
			}
			else
			{
				CBitStream to_send;
				to_send.write_netid(getLocalPlayer().getNetworkID());
				to_send.write_u32(got_packets);
				this.SendCommand(this.getCommandID("C_RequestMapPacket"), to_send, false);
			}
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
				loading_string = "Generating block faces.";
				world.FacesSetUp();
			}
			if(gf_packet < gf_amount_of_packets)
			{
				world.GenerateBlockFaces(gf_packet);
				gf_packet++;
				Debug(gf_packet+"/"+gf_amount_of_packets+".", 3);
				loading_string = "Generating faces. "+gf_packet+"/"+gf_amount_of_packets;
			}
			else
			{
				Debug("Done.");
				loading_string = "Setting up chunks.";
				faces_generated = true;
			}
			return true;
		}
		else
		{
			if(!chunks_set_up)
			{
				Debug("Setting up chunks.");
				world.SetUpChunks();
				loading_string = "Setting up tree.";
				Debug("Done.");
				chunks_set_up = true;
				return true;
			}
			else if(!tree_set_up)
			{
				Debug("Setting up tree.");
				SetUpTree();
				Debug("Done.");
				loading_string = "Done.";
				tree_set_up = true;
				map_renderable = true;
				return true;
			}
		}
	}
    else if(!player_ready)
    {
        Player _my_player();
        @my_player = @_my_player;
		
        my_player.pos = Vec3f(map_width/2, map_height-4, map_depth/2);
		my_player.SetBlob(getLocalPlayerBlob());
		my_player.SetPlayer(getLocalPlayer());
		my_player.GenerateBlockMenu();
		getControls().setMousePosition(Vec2f(float(getScreenWidth()) / 2.0f, float(getScreenHeight()) / 2.0f));
        player_ready = true;
		Render::addScript(Render::layer_background, "Client.as", "Render", 1);

		for(int i = 0; i < block_queue.size(); i++)
		{
			Vec3f pos = block_queue[i].pos;
			uint8 block = block_queue[i].block;
			world.map[pos.y][pos.z][pos.x] = block;
    		world.UpdateBlocksAndChunks(pos.x, pos.y, pos.z);
		}
		block_queue.clear();

		return true;
    }
    return false;
}

BlockToPlace[] block_queue;

class BlockToPlace
{
	Vec3f pos;
	uint8 block;

	BlockToPlace(){}

	BlockToPlace(const Vec3f&in _pos, uint8 _block)
	{
		pos = _pos;
		block = _block;
	}
}