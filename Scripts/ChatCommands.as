
bool onServerProcessChat(CRules@ this, const string& in text_in, string& out text_out, CPlayer@ player)
{
	return true;
}

bool onClientProcessChat(CRules@ this, const string&in text_in, string&out text_out, CPlayer@ player)
{
	if (text_in.substr(0, 1) == "/") // command
	{
		if(!player.isMyPlayer())
		{
			return false;
		}
		if(this.get_bool("ClientLoading"))
		{
			client_AddToChat("Commands are not available while game is loading.", chat_colors::color_red);
		}
		if(text_in == "/commands")
		{
			client_AddToChat("Available commands:", chat_colors::color_green);
			client_AddToChat("/commands - show this text. :)", chat_colors::color_blue);
			client_AddToChat("/blocks - show available block texture names.", chat_colors::color_blue);
			client_AddToChat("/blocks texture_name - change current block textures.", chat_colors::color_blue);
			client_AddToChat("...and more comming soon!", chat_colors::color_blue);
		}
		else if(text_in == "/blocks")
		{
			client_AddToChat("Available textures:", chat_colors::color_green);
			client_AddToChat("\"Classic\"", chat_colors::color_blue);
			client_AddToChat("\"Jenny\"", chat_colors::color_blue);
			client_AddToChat("\"Minecraft\"", chat_colors::color_blue);
			client_AddToChat("\"PublicEnemy\"", chat_colors::color_blue);
		}
		else // check commands with multiple arguments
		{
			string[]@ tokens = text_in.split(" ");

			if (tokens.length == 2)
			{
				if (tokens[0] == "/blocks")
				{
					string name = tokens[1];
					if(name == "Classic" || name == "Jenny" || name == "Minecraft" || name == "PublicEnemy")
					{
						client_AddToChat("Changing block textures to \""+name+"\".", chat_colors::color_green);

						{
							Texture::destroy("Block_Textures");
							Texture::createFromFile("Block_Textures", "Textures/Blocks_"+name+".png");
						}
					}
					else
					{
						client_AddToChat("Incorrect name, use /blocks commant to see all available textures.", chat_colors::color_red);
					}
				}
			}
			else if(tokens.length == 1)
			{
				client_AddToChat("Invalid command, use /commands to see all available commands.", chat_colors::color_red);
			}
		}
		return false;
	}
	return true;
}

namespace chat_colors
{
	SColor color_red = SColor(255, 239, 35, 35);
	SColor color_green = SColor(255, 0, 153, 17);
	SColor color_blue = SColor(255, 31, 139, 226);
	SColor color_purple = SColor(255, 217, 0, 255);
}