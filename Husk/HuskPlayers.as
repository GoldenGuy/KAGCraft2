
#define SERVER_ONLY

void onNewPlayerJoin( CRules@ this, CPlayer@ player )
{
	CBlob@ blob = server_CreateBlob("husk");
	if(blob !is null)
	{
		blob.server_SetPlayer(player);
	}
}