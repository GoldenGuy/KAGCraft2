
void onInit(CRules@ this)
{
	this.addCommandID("error1"); // reserverd for something in engine, crashes game on call
	this.addCommandID("C_RequestMapParams");
	this.addCommandID("S_SendMapParams");
	this.addCommandID("C_RequestMap");
	this.addCommandID("S_SendMapPacket");
	this.addCommandID("C_ChangeBlock");
	this.addCommandID("S_ChangeBlock");
	this.addCommandID("C_CreatePlayer");
	this.addCommandID("C_PlayerUpdate");
	this.addCommandID("S_PlayerUpdate");

	this.addCommandID("C_PlaySound3D");

	CMap@ map = getMap();
	map.topBorder = map.bottomBorder = map.leftBorder = map.rightBorder = map.legacyTileVariations = map.legacyTileEffects = map.legacyTileDestroy = map.legacyTileMinimap = false;
	SColor col = 0x00000000;
	map.SetBorderColourLeft(col);
	map.SetBorderColourRight(col);
	map.SetBorderColourTop(col);
	map.SetBorderColourBottom(col);
	map.MakeMiniMap();
}