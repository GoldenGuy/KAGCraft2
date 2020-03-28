
#define SERVER_ONLY

#include "World.as"

World world;

void onInit(CRules@ this)
{
	print("Server init");
	world.GenerateMap();
}

void onTick(CRules@ this)
{
	//print("ara");
}