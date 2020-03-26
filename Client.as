
#define CLIENT_ONLY

void onInit(CRules@ this)
{
	Texture::createFromFile("Default_Textures", "Textures/Blocks.png");
	print("Client init");
}