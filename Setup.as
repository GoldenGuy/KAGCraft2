
void onInit(CRules@ this)
{
	this.addCommandID("error");
	this.addCommandID("C_RequestMap");
	this.addCommandID("S_SendMap");
	this.addCommandID("C_ChangeBlock");
	
	this.AddScript("Server.as");
	this.AddScript("Client.as");

	CMap@ map = getMap();
	map.topBorder = map.bottomBorder = map.leftBorder = map.rightBorder = map.legacyTileVariations = map.legacyTileEffects = map.legacyTileDestroy = map.legacyTileMinimap = false;
	SColor col = 0x00000000;
	map.SetBorderColourLeft(col);
	map.SetBorderColourRight(col);
	map.SetBorderColourTop(col);
	map.SetBorderColourBottom(col);
}