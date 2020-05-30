
bool onServerProcessChat(CRules@ this, const string& in text_in, string& out text_out, CPlayer@ player)
{
	if (text_in.substr(0, 1) == "/") // command
	{
		if(getSecurity().getPlayerSeclev(player).getName() == "Admin")
		{
			string[]@ tokens = text_in.split(" ");

			if (tokens.length > 1)
			{
				if (tokens[0] == "/sky")
				{
					if (tokens.length == 4)
					{
						CBitStream to_send;
						u8 r = parseInt(tokens[1]);
						u8 g = parseInt(tokens[2]);
						u8 b = parseInt(tokens[3]);
						to_send.write_u8(r);
						to_send.write_u8(g);
						to_send.write_u8(b);
						this.SendCommand(this.getCommandID("SC_ChangeSky"), to_send, true);
					}
				}
			}
		}
	}
	return true;
}

bool onClientProcessChat(CRules@ this, const string&in text_in, string&out text_out, CPlayer@ player)
{
	if (text_in.substr(0, 1) == "/") // command
	{
		if(!player.isMyPlayer())
		{
			/*if (getSecurity().getPlayerSeclev(p).getName() != "Admin")
			{
				return false;
			}

			string[]@ tokens = text_in.split(" ");

			if (tokens.length > 1)
			{
				if (tokens[0] == "/sky")
				{
					if (tokens.length == 4)
					{
						SColor@ old;
						getRules().set("sky_color", @old);
						old.set(255, int(tokens[1]), int(tokens[2]), int(tokens[3]));
					}
				}
			}*/
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
			client_AddToChat("\"3x3\"", chat_colors::color_blue);
		}
		else // check commands with multiple arguments
		{
			string[]@ tokens = text_in.split(" ");

			if (tokens.length == 2)
			{
				if (tokens[0] == "/blocks")
				{
					string name = tokens[1];
					if(name == "Classic" || name == "Jenny" || name == "Minecraft" || name == "PublicEnemy" || name == "3x3")
					{
						SMaterial@ map_material;
						getRules().get("map_material", @map_material);
						map_material.AddTexture("SOLID", 0);
						Texture::destroy("Block_Textures");
						Texture::createFromFile("Block_Textures", "Textures/Blocks_"+name+".png");
						map_material.AddTexture("Block_Textures", 0);

						client_AddToChat("Changing block textures to \""+name+"\".", chat_colors::color_green);
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