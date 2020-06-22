
#define SERVER_ONLY

//#include "Debug.as"
#include "AABB.as"
#include "World.as"
#include "Maths.as"
#include "ServerPlayer.as"
//#include "MapSavingLoading.as"

World@ world;

bool localhost = false;

ServerPlayer@[] players;

void onInit(CRules@ this)
{
	players_to_send.clear();

	InitBlocks();

	if(isClient())
	{
		localhost = true;
		return;
	}

	@world = @World();

	world.LoadMapParams();
	if(world.new)
	{
		world.GenerateMap();
	}
	else
	{
		world.LoadMap();
	}

	//if(isClient()) this.set("world", @world);
	
	print("Server started.");
}

void onTick(CRules@ this)
{
	if(localhost)
	{
		if(this.get_bool("world_ready"))
		{
			this.get("world", @world);
			localhost = false;
		}
		return;
	}
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
			players_to_send.removeAt(0);
			if(packet_num < world.map_packets_amount)
			{
				players_to_send.push_back(MapSender(player, packet_num));
			}
		}
		else
		{
			players_to_send.removeAt(0);
		}
	}

	if(world.map_save_time != -1 && getGameTime() % world.map_save_time == world.map_save_time-10)
	{
		world.SaveMap();

		CBitStream to_send;
		if(world.save_map)
		{
			to_send.write_string("Map has been auto-saved successfully!");
		}
		else
		{
			to_send.write_string("Will not save map :P");
		}
		to_send.write_u8(255);
		to_send.write_u8(22);
		to_send.write_u8(119);
		to_send.write_u16(160);
		this.SendCommand(this.getCommandID("S_UText"), to_send, true);
	}
}

void onCommand(CRules@ this, uint8 cmd, CBitStream@ params)
{
	if(cmd == this.getCommandID("C_RequestMapParams"))
	{
		uint16 netid = params.read_netid();
		CPlayer@ player = getPlayerByNetworkId(netid);
		if(player !is null)
		{
			CBitStream to_send;
			to_send.write_u32(world.chunk_width);
			to_send.write_u32(world.chunk_depth);
			to_send.write_u32(world.chunk_height);
			to_send.write_u32(world.world_width);
			to_send.write_u32(world.world_depth);
			to_send.write_u32(world.world_height);
			to_send.write_u8(world.sky_color.getRed());
			to_send.write_u8(world.sky_color.getGreen());
			to_send.write_u8(world.sky_color.getBlue());
			this.SendCommand(this.getCommandID("S_SendMapParams"), to_send, player);
		}
		
	}
	else if(cmd == this.getCommandID("C_RequestMap"))
	{
		uint16 netid = params.read_netid();
		if(isClient())
		{
			return;
		}
		else
		{
			//CPlayer@ sender = getNet().getActiveCommandPlayer();
			CPlayer@ player = getPlayerByNetworkId(netid);
			players_to_send.push_back(MapSender(player, 0));
		}
	}
	else if(cmd == this.getCommandID("C_CreatePlayer"))
	{
		u16 netid = params.read_netid();
		if(isClient())
		{
			return;
		}
		CPlayer@ player = getPlayerByNetworkId(netid);
		if(player !is null)
		{
			print("created "+player.getUsername());
			ServerPlayer new_player();
			new_player.pos = Vec3f(world.map_width/2, world.map_height-4, world.map_depth/2);
			new_player.SetPlayer(player);
			players.push_back(@new_player);
		}
	}
	else if(cmd == this.getCommandID("C_PlayerUpdate"))
	{
		uint16 netid = params.read_netid();
		CPlayer@ _player = getPlayerByNetworkId(netid);
		if(_player !is null)
		{
			ServerPlayer@ __player = getServerPlayer(_player);
			if(__player !is null)
			{
				__player.UnSerialize(params);
			}
		}
	}
	else if(cmd == this.getCommandID("C_FreezePlayer"))
	{
		uint16 netid = params.read_netid();
		CPlayer@ _player = getPlayerByNetworkId(netid);
		if(_player !is null)
		{
			string seclev = getSecurity().getPlayerSeclev(_player).getName();
			if(seclev != "Admin")
			{
				ServerPlayer@ __player = getServerPlayer(_player);
				if(__player !is null)
				{
					bool freeze = params.read_bool();
					__player.Frozen = freeze;
					error("Player "+_player.getCharacterName()+" ("+_player.getUsername()+") is "+(freeze ? "" : "un")+"frozen!");
					CBitStream to_send;
					to_send.write_netid(netid);
					to_send.write_bool(freeze);
					getRules().SendCommand(getRules().getCommandID("S_FreezePlayer"), to_send, true);
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
						world.saveBlock(x, y, z, block);
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
	else if(cmd == this.getCommandID("SC_ChangeSky"))
	{
		u8 r = params.read_u8();
		u8 g = params.read_u8();
		u8 b = params.read_u8();
		world.sky_color.setRed(r);
		world.sky_color.setGreen(g);
		world.sky_color.setBlue(b);
	}
	else if(cmd == this.getCommandID("CC_savemap"))
	{
		world.SaveMap();

		CBitStream to_send;
		if(world.save_map)
		{
			to_send.write_string("Map has been manually saved successfully!");
		}
		else
		{
			to_send.write_string("Will not save map :P");
		}
		to_send.write_u8(255);
		to_send.write_u8(22);
		to_send.write_u8(119);
		to_send.write_u16(160);
		this.SendCommand(this.getCommandID("S_UText"), to_send, true);
	}
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	getSecurity().sendSeclevs(player);
	CBlob@ blob = server_CreateBlob("husk");
	if(blob !is null)
	{
		blob.server_SetPlayer(player);
	}
}

void onPlayerLeave(CRules@ this, CPlayer@ player)
{
	CBlob@ blob = player.getBlob();
	if(blob !is null)
	{
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

void PlaySound3D(string name, int x, int y, int z)
{
    // nothing
}

void CreateBlockParticles(uint8 block_id, Vec3f pos)
{
	// nothing
}