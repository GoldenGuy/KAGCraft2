
void onInit(CRules@ this)
{
	this.addCommandID("error1"); // reserverd for something in engine, crashes game on call
	this.addCommandID("error2");
	this.addCommandID("error3");
	this.addCommandID("error4");
	this.addCommandID("error5");
	this.addCommandID("C_RequestMap");
	this.addCommandID("S_SendMap");
	this.addCommandID("C_ReceivedMap");
	this.addCommandID("C_ChangeBlock");

	CMap@ map = getMap();
	map.topBorder = map.bottomBorder = map.leftBorder = map.rightBorder = map.legacyTileVariations = map.legacyTileEffects = map.legacyTileDestroy = map.legacyTileMinimap = false;
	SColor col = 0x00000000;
	map.SetBorderColourLeft(col);
	map.SetBorderColourRight(col);
	map.SetBorderColourTop(col);
	map.SetBorderColourBottom(col);
}