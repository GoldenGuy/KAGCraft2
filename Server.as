
#define SERVER_ONLY

#include "Debug.as"
#include "AABB.as"
#include "World.as"
#include "Vec3f.as"

World@ world;

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
				this.SendCommand(this.getCommandID("S_SendMap"), to_send, players_to_send[0].player);
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
			this.SendCommand(this.getCommandID("S_SendMap"), CBitStream(), true);
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
			//this.SendCommand(this.getCommandID("S_SendMap"), to_send, true);
		}
	}
	if(cmd == this.getCommandID("C_ReceivedMap"))
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
}

void onNewPlayerJoin(CRules@ this, CPlayer@ player)
{
	CBlob@ blob = server_CreateBlob("husk");
	if(blob !is null)
	{
		Debug("Creating player blob.");
		blob.server_SetPlayer(player);
	}
}

void onPlayerLeave(CRules@ this, CPlayer@ player)
{
	CBlob@ blob = player.getBlob();
	if(blob !is null)
	{
		Debug("Removing player blob.");
		blob.server_Die();
	}
}