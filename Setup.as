
void onInit(CRules@ this)
{
	this.addCommandID("error");
	this.addCommandID("C_RequestMap");
	this.addCommandID("S_SendMap");
	this.addCommandID("C_ChangeBlock");

	CMap@ map = getMap();
	map.topBorder = map.bottomBorder = map.leftBorder = map.rightBorder = map.legacyTileVariations = map.legacyTileEffects = map.legacyTileDestroy = map.legacyTileMinimap = false;
	SColor col = 0x00000000;
	map.SetBorderColourLeft(col);
	map.SetBorderColourRight(col);
	map.SetBorderColourTop(col);
	map.SetBorderColourBottom(col);

	/*if(isServer())
	{
		print("server");
		this.AddScript("Server.as");
	}
	if(isClient())
	{
		print("client");
		//this.AddScript("Client.as");
	}*/
}

/*void onTick(CRules@ this)
{
	if(getGameTime() == 1)
	{
		if(isServer())
		{
			this.AddScript("Server.as");
		}
		if(isClient())
		{
			this.AddScript("Client.as");
		}
		this.RemoveScript("Setup.as");
	}
}*/