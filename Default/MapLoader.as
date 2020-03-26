bool LoadMap(CMap@ map, const string& in fileName)
{
	if(!isServer())
	{
		map.CreateTileMap(0, 0, 8.0f, "Textures/Blocks.png");
		return true;
	}
	map.CreateTileMap(2, 2, 8.0f, "Textures/Blocks.png");
	return true;
}