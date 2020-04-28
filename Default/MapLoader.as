
bool LoadMap(CMap@ map, const string&in fileName)
{
	if(!isServer())
	{
		map.CreateTileMap(0, 0, 8.0f, "Sprites/world.png");
		return true;
	}
	map.CreateTileMap(161, 48, 8.0f, "Sprites/world.png");
	@image = CFileImage(CFileMatcher("BitMap.png").getFirst());
	return true;
}

CFileImage@ image;

void CalculateMinimapColour(CMap@ this, u32 offset, TileType tile, SColor&out col)
{
	image.setPixelOffset(offset);
	col = image.readPixel();
	return;
}