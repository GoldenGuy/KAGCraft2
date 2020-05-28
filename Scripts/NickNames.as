// copyrighted by GoldenGuy#8983 , DO NOT STEAL >:[

//string characters = " !\"#$%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_\`abcdefghijklmnopqrstuvwxyz{|}~"; // -32
u8[] sizes = {3,1,4,5,5,5,5,2,4,4,4,5,1,5,1,5,5,5,5,5,5,5,5,5,5,5,1,1,4,5,4,5,6,5,5,5,5,5,5,5,5,3,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,3,5,3,5,5,2,5,5,5,5,5,4,5,5,1,5,4,2,5,5,5,5,5,5,5,3,5,5,5,5,5,5,4,1,4,6}; //damn

void MakeNickName(string player_name, SMesh&inout mesh)
{
	string player_name_nn = player_name+"_NN";
	SColor nickColor = getNameColour(player_name);
	int size_x = 0;
	if(!Texture::exists(player_name_nn))
	{
		ImageData@ nicknames_font_img = Texture::data("NickNamesFont");

		size_x = figureOutTextureLength(player_name);
		ImageData@ nickname_img = ImageData(size_x, 8);
		
		int nn_last_pos_x = 0;
		
		for(int char = 0; char < player_name.size(); char++)
		{
			int id = player_name[char]-32;
			u8 letter_size = sizes[id];
			int characters_pos_x = 0;
			for(int i = 0; i < id; i++)
			{
				characters_pos_x += sizes[i]+1;
			}
			
			for(int y = 0; y < 8; y++)
			{
				string bitmap = "";
				for(int x = characters_pos_x; x < characters_pos_x+letter_size+1; x++)
				{
					SColor col = nicknames_font_img.get(x, y);
					if(col == color_white)
					{
						nickname_img.put(nn_last_pos_x+(x-characters_pos_x), y, color_black);
						bitmap +=".";
					}
					else
					{
						bitmap +="0";
						nickname_img.put(nn_last_pos_x+(x-characters_pos_x), y, nickColor);
					}
				}
				//print(" "+bitmap);
			}
			nn_last_pos_x += letter_size+1;
		}
		Texture::createFromData(player_name_nn, nickname_img);
	}
	else
	{
		ImageData@ nickname_img = Texture::data(player_name_nn);
		size_x = nickname_img.width();
	}

	f32 letter_ratio = 1.0f/64.0f;
	f32 letter_heigth = letter_ratio*8;
	f32 text_start = 0-letter_ratio*size_x/2;
	f32 text_end = letter_ratio*size_x/2;
	Vertex[] Verts = {
		Vertex(text_start,	letter_heigth,	0, 0,0,	SColor(170, 255, 255, 255)),
		Vertex(text_end,	letter_heigth,	0, 1,0,	SColor(170, 255, 255, 255)),
		Vertex(text_end,	0,				0, 1,1,	SColor(170, 255, 255, 255)),
		Vertex(text_start,	0,				0, 0,1,	SColor(170, 255, 255, 255))
	};
	u16[] IDs = {0,1,2,0,2,3};

	SMaterial material;
	material.AddTexture(player_name_nn, 0);
	material.DisableAllFlags();
	material.SetFlag(SMaterial::COLOR_MASK, true);
	material.SetFlag(SMaterial::ZBUFFER, true);
	material.SetFlag(SMaterial::ZWRITE_ENABLE, true);
	material.SetFlag(SMaterial::BLEND_OPERATION, true);
	material.SetMaterialType(SMaterial::TRANSPARENT_ALPHA_CHANNEL_REF);

	mesh.Clear();
	mesh.SetMaterial(material);
	mesh.SetVertex(Verts);
	mesh.SetIndices(IDs);
	mesh.SetDirty(SMesh::VERTEX_INDEX);
	mesh.SetHardwareMapping(SMesh::STATIC);
	mesh.BuildMesh();
}

int figureOutTextureLength(string player_name)
{
	int nickname_length = 0;
	for(int i = 0; i < player_name.size(); i++)
	{
		u8 letter_size = sizes[player_name[i]-32];
		
		nickname_length += letter_size+1;
	}
	return nickname_length;
}

SColor getNameColour(string player_name)
{
    SColor c;
    CPlayer@ p = getPlayerByUsername(player_name);
	if(p is null)
	{
		c = SColor(0xffffffff);
		return c;
	}

    if (p.isDev())	//dev
	{
        c = SColor(0xff9900DB);
    }
	else if (p.isGuard())	//guard
	{
        c = SColor(0xff5FCC5F);
    }
	else if (getSecurity().getPlayerSeclev(p).getName() == "Admin")	//cool
	{
        c = SColor(0xffF08020);
	}
	else if (p.getOldGold() && !p.isBot())	//gold
	{
        c = SColor(0xffBC8F14);
    }
	else	//normal
	{
		c = SColor(0xffffffff);
    }
	return c;
}