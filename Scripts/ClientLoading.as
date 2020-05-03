
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
		else
		{
			if(map_packets.size() > 0)
			{
				world.UnSerialize(map_packets[0], got_packets);
				map_packets.removeAt(0);
				got_packets++;
				int percent = (float(got_packets)/float(amount_of_packets))*100;
				loading_string = "Loading map. "+percent+"%";
				//return true;
			}
		}
		/*if(got_packets >= amount_of_packets)
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
		}*/
		return true;
	}
	else if(!map_renderable)
	{
		if(!faces_generated)
		{
			if(isServer())
			{
				if(gf_packet == 0)
				{
					Debug("Generating block faces.");
					loading_string = "Generating block faces.";
					world.FacesSetUp();
					gf_packet++;
					return true;
				}
				if(gf_packet < gf_amount_of_packets)
				{
					world.GenerateBlockFaces(gf_packet);
					gf_packet++;
					Debug("Generating block faces. "+gf_packet+"/"+gf_amount_of_packets+".", 3);
					int percent = (float(gf_packet)/float(gf_amount_of_packets))*100;
					loading_string = "Generating block faces. "+percent+"%";
					return true;
				}
				else
				{
					Debug("Done.");
					loading_string = "Setting up chunks.";
					faces_generated = true;
					return true;
				}
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
				world.SetUpChunks(chunks_packets);
				chunks_packets++;
				Debug("Setting up chunks. "+chunks_packets+"/"+max_chunks_packets);
				int percent = (float(chunks_packets)/float(max_chunks_packets))*100;
				loading_string = "Setting up chunks. "+percent+"%";
				if(chunks_packets < max_chunks_packets) return true;

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
        world.SetUpMaterial();
		
		Player _my_player();
        @my_player = @_my_player;
		
        my_player.pos = Vec3f(map_width/2, map_height-4, map_depth/2);
		my_player.SetBlob(getLocalPlayerBlob());
		my_player.SetPlayer(getLocalPlayer());
		my_player.GenerateBlockMenu();
		getControls().setMousePosition(Vec2f(float(getScreenWidth()) / 2.0f, float(getScreenHeight()) / 2.0f));
        player_ready = true;

		Render::SetFog(sky_color, SMesh::LINEAR, camera.z_far*0.76f, camera.z_far, 0, false, false);
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

/*MapPackets[] block_queue;

class MapPackets
{
	CBitStream@ stream;
	uint8 block;

	BlockToPlace(){}

	BlockToPlace(const Vec3f&in _pos, uint8 _block)
	{
		pos = _pos;
		block = _block;
	}
}*/

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

int chunks_packets = 0;
int max_chunks_packets = world_height;