
void onInit(CRules@ this)
{
	this.addCommandID("error");
	this.addCommandID("S_SendMap");
	this.addCommandID("C_ChangeBlock");
	
	if(isServer())
	{
		this.AddScript("Server.as");
	}
	if(isClient())
	{
		Texture::createFromFile("Default_Textures", "Textures/Blocks.png");
		this.AddScript("Client.as");
	}
}