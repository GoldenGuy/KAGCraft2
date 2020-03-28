
#define CLIENT_ONLY

#include "World.as"
#include "Vec3f.as"

World world;

void onInit(CRules@ this)
{
	Texture::createFromFile("Default_Textures", "Textures/Blocks.png");
	print("Client init");
}