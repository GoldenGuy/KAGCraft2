
#define SERVER_ONLY

#include "Debug.as"
#include "AABB.as"
#include "World.as"
#include "Vec3f.as"
#include "ServerPlayer.as"
#include "UtilitySectors.as"

World@ world;

ServerPlayer@[] players;

void onInit(CRules@ this)
{
	Debug("Server init");

	players_to_send.clear();

	InitBlocks();

	Debug("Loading params from config file.");
	LoadServerParams();

	World temp;
	temp.GenerateMap();
	if(isClient()) this.set("world", @temp);
	@world = @temp;
}

void onTick(CRules@ this)
{
	if(!isClient())
	{
		uint16 size = players.size();
		if(size > 1)
		{
			CBitStream to_send;
			to_send.write_u16(size);
			for(int i = 0; i < size; i++)
			{
				players[i].Serialize(@to_send);
			}
			this.SendCommand(this.getCommandID("S_PlayerUpdate"), to_send, true);
		}
	}
	if(players_to_send.size() > 0)
	{
		if(players_to_send[0].player !is null)
		{
			CBitStream to_send;
			CPlayer@ player = players_to_send[0].player;
			uint32 packet_num = players_to_send[0].packet_number;
			world.Serialize(@to_send, packet_num);
			this.SendCommand(this.getCommandID("S_SendMapPacket"), to_send, players_to_send[0].player);
			packet_num++;
			//Debug("Sending map packet, "+packet_num+"/"+amount_of_packets+".", 3);
			players_to_send.removeAt(0);
			if(packet_num < map_packets_amount)
			{
				players_to_send.push_back(MapSender(player, packet_num));
			}
		}
		else
		{
			players_to_send.removeAt(0);
		}
	}

	/*if(getGameTime() > 50)
	{
		if(getGameTime() % 5 == 2) server_SetBlock(Block::grass_dirt, map_width/2, map_height-4, map_depth/2);
		else if(getGameTime() % 6 == 4) server_SetBlock(Block::air, map_width/2, map_height-4, map_depth/2);
	}*/
}

void onCommand(CRules@ this, uint8 cmd, CBitStream@ params)
{
	//Debug("Command: "+cmd+" : "+this.getNameFromCommandID(cmd), 1);
	if(cmd == this.getCommandID("C_RequestMapParams"))
	{
		uint16 netid = params.read_netid();
		CPlayer@ player = getPlayerByNetworkId(netid);
		if(player !is null)
		{
			CBitStream to_send;
			to_send.write_u32(chunk_width);
			to_send.write_u32(chunk_depth);
			to_send.write_u32(chunk_height);
			to_send.write_u32(world_width);
			to_send.write_u32(world_depth);
			to_send.write_u32(world_height);
			to_send.write_u8(sky_color.getRed());
			to_send.write_u8(sky_color.getGreen());
			to_send.write_u8(sky_color.getBlue());
			this.SendCommand(this.getCommandID("S_SendMapParams"), to_send, player);
		}
		
	}
	else if(cmd == this.getCommandID("C_RequestMap"))
	{
		uint16 netid = params.read_netid();
		if(isClient())
		{
			Debug("Localhost, ignore.");
			//this.SendCommand(this.getCommandID("S_SendMapPacket"), CBitStream(), true);
			return;
		}
		else
		{
			//CPlayer@ sender = getNet().getActiveCommandPlayer();
			CPlayer@ player = getPlayerByNetworkId(netid);
			players_to_send.push_back(MapSender(player, 0));
		}
	}
	else if(cmd == this.getCommandID("C_PlayerUpdate"))
	{
		uint16 netid = params.read_netid();
		CPlayer@ _player = getPlayerByNetworkId(netid);
		if(_player !is null)
		{
			for(int i = 0; i < players.size(); i++)
			{
				ServerPlayer@ __player = players[i];
				if(__player.player is _player)
				{
					__player.UnSerialize(params);
					break;
				}
			}
		}
	}
	else if(cmd == this.getCommandID("C_ChangeBlock"))
	{
		uint16 netid = params.read_netid();
		CPlayer@ player = getPlayerByNetworkId(netid);
		if(player !is null)
		{
			ServerPlayer@ splayer = getServerPlayer(player);
			if(splayer !is null)
			{
				if(!splayer.Frozen)
				{
					uint8 block = params.read_u8();
					float x = params.read_f32();
					float y = params.read_f32();
					float z = params.read_f32();

					if(world.inWorldBounds(x, y, z))
					{
						uint8 old_block = world.getBlock(x, y, z);
						world.setBlock(x, y, z, block);
						world.BlockUpdate(x, y, z, block, old_block);

						CBitStream to_send;
						to_send.write_u8(block);
						to_send.write_f32(x);
						to_send.write_f32(y);
						to_send.write_f32(z);
						getRules().SendCommand(getRules().getCommandID("S_ChangeBlock"), to_send, true);
					}
				}
			}
		}
	}
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	getSecurity().sendSeclevs(player);
	CBlob@ blob = server_CreateBlob("husk");
	if(blob !is null)
	{
		Debug("Creating player blob.");
		blob.server_SetPlayer(player);
	}

	for(int i = 0; i < players.size(); i++)
	{
		ServerPlayer@ _player = players[i];
		if(_player.player is player)
		{
			Debug("onNewPlayerJoin: Player already in list!", 3);
			return;
		}
	}

	ServerPlayer new_player();
	new_player.pos = Vec3f(map_width/2, map_height-4, map_depth/2);
	new_player.SetPlayer(player);
	players.push_back(@new_player);
}

void onPlayerLeave(CRules@ this, CPlayer@ player)
{
	CBlob@ blob = player.getBlob();
	if(blob !is null)
	{
		Debug("Removing player blob.");
		blob.server_Die();
	}

	for(int i = 0; i < players.size(); i++)
	{
		ServerPlayer@ _player = players[i];
		if(_player.player is player)
		{
			players.removeAt(i);
			return;
		}
	}
}

void LoadServerParams()
{
	ConfigFile cfg = ConfigFile();
	if (!cfg.loadFile(CFileMatcher("KCServerConfig.cfg").getFirst()))
	{
		error("Could not find config file! Using default parameters.");
		return;
	}
	else
	{
		print("Loading map parameters.");
		chunk_width = cfg.read_u32("chunk_width");
		chunk_depth = cfg.read_u32("chunk_depth");
		chunk_height = cfg.read_u32("chunk_height");
		chunk_size = chunk_width*chunk_depth*chunk_height;

		world_width = cfg.read_u32("world_width");
		world_depth = cfg.read_u32("world_depth");
		world_height = cfg.read_u32("world_height");
		world_width_depth = world_width * world_depth;
		world_size = world_width_depth * world_height;

		map_width = world_width * chunk_width;
		map_depth = world_depth * chunk_depth;
		map_height = world_height * chunk_height;
		map_width_depth = map_width * map_depth;
		map_size = map_width_depth * map_height;

		map_packet_size = chunk_width*chunk_depth*chunk_height*8;
		map_packets_amount = map_size / map_packet_size;

		uint8 sky_color_R = cfg.read_u8("sky_color_R");
		uint8 sky_color_G = cfg.read_u8("sky_color_G");
		uint8 sky_color_B = cfg.read_u8("sky_color_B");
		sky_color = SColor(255, sky_color_R, sky_color_G, sky_color_B);

		initial_plane = cfg.read_f32("initial_plane");
		initial_plane_max_height = cfg.read_f32("initial_plane_max_height");
		initial_plane_add_max = cfg.read_f32("initial_plane_add_max");
		hills_spread = cfg.read_f32("hills_spread");
		tree_frequency = cfg.read_f32("tree_frequency");
		grass_frequency = cfg.read_f32("grass_frequency");
	}
}