
#define SERVER_ONLY

#include "Debug.as"
#include "AABB.as"
#include "World.as"
#include "Vec3f.as"
#include "ServerPlayer.as"

World@ world;

ServerPlayer@[] players;

void onInit(CRules@ this)
{
	players_to_send.clear();

	InitBlocks();

	@world = @World();

	world.LoadMapParams();
	world.GenerateMap();

	if(isClient()) this.set("world", @world);
	
	print("Server started.");
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
		blob.server_SetPlayer(player);
	}

	for(int i = 0; i < players.size(); i++)
	{
		ServerPlayer@ _player = players[i];
		if(_player.player is player)
		{
			return;
		}
	}

	ServerPlayer new_player();
	new_player.pos = Vec3f(world.map_width/2, world.map_height-4, world.map_depth/2);
	new_player.SetPlayer(player);
	players.push_back(@new_player);
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