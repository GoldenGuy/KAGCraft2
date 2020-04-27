
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
	Debug("Server init");

	players_to_send.clear();

	InitBlocks();

	World temp;
	temp.GenerateMap();
	if(isClient()) this.set("world", @temp);
	@world = @temp;
}

void onTick(CRules@ this)
{
	if(!isClient())
	{
		u16 size = players.size();
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
		bool done = false;
		if(players_to_send[0].player !is null)
		{
			//u16 netid = players_to_send[0].player.getNetworkID();
			
			if(players_to_send[0].ready)
			{
				players_to_send[0].ready = false;
				CBitStream to_send;
				world.Serialize(@to_send, players_to_send[0].packet_number);
				this.SendCommand(this.getCommandID("S_SendMapPacket"), to_send, players_to_send[0].player);
				Debug("Sending map packet, "+(players_to_send[0].packet_number+1)+"/"+amount_of_packets+".", 3);

				players_to_send[0].packet_number++;
				if(players_to_send[0].packet_number >= amount_of_packets)
				{
					done = true;
				}
			}
		}
		else
		{
			done = true;
		}
		if(done)
		{
			players_to_send.removeAt(0);
		}
	}
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	Debug("Command: "+cmd+" : "+this.getNameFromCommandID(cmd), 1);
	if(cmd == this.getCommandID("C_RequestMap"))
	{
		u16 netid = params.read_netid();
		if(isClient())
		{
			Debug("Localhost, ignore.");
			this.SendCommand(this.getCommandID("S_SendMapPacket"), CBitStream(), true);
			return;
		}
		else
		{
			//CPlayer@ sender = getNet().getActiveCommandPlayer();
			CPlayer@ player = getPlayerByNetworkId(netid);
			if(player !is null)
			{
				players_to_send.push_back(MapSender(player));
			}

			//CBitStream to_send;
			//world.Serialize(@to_send);
			//this.SendCommand(this.getCommandID("S_SendMapPacket"), to_send, true);
		}
	}
	else if(cmd == this.getCommandID("C_ReceivedMapPacket"))
	{
		u16 netid = params.read_netid();
		CPlayer@ player = getPlayerByNetworkId(netid);
		for(int i = 0; i < players_to_send.size(); i++)
		{
			if(players_to_send[i].player is player)
			{
				players_to_send[i].ready = true;
			}
		}
	}
	else if(cmd == this.getCommandID("C_PlayerUpdate"))
	{
		u16 netid = params.read_netid();
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
		u8 block = params.read_u8();
		f32 x = params.read_f32();
		f32 y = params.read_f32();
		f32 z = params.read_f32();

		world.map[y][z][x] = block;
	}
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
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