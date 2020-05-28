// copyrighted by GoldenGuy#8983 , DO NOT STEAL >:[

//string characters = " !\"#$%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_\`abcdefghijklmnopqrstuvwxyz{|}~"; // -32
u8[] sizes = {3,1,4,5,5,5,5,2,4,4,4,5,1,5,1,5,5,5,5,5,5,5,5,5,5,5,1,1,4,5,4,5,6,5,5,5,5,5,5,5,5,3,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,3,5,3,5,5,2,5,5,5,5,5,4,5,5,1,5,4,2,5,5,5,5,5,5,5,3,5,5,5,5,5,5,4,1,4,6}; //damn

class NickName
{
	string player_name;
	//SMesh Mesh;
	Vertex[] Vertexes;
	u16[] IDs;
	NickName(){}
	NickName(string _player_name, SMesh&inout mesh_nn)
	{
		//_player_name = " !\"#$%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_\`abcdefghijklmnopqrstuvwxyz{|}~"; //
		player_name = _player_name+"_NN";
		SColor nickColor = getNameColour(_player_name);//color_white;
		//if(Cool(_player_name))
		//	nickColor = SColor(0xFFFF2020);
		int size_x = 0;
		if(!Texture::exists(_player_name+"_NN"))
		{
			if(!Texture::exists("NickNamesFont"))
				Texture::createFromFile("NickNamesFont", "NickNamesFont.png");
				
			ImageData@ nicknames_font_img = Texture::data("NickNamesFont");

			size_x = figureOutTextureLength(_player_name);
			ImageData@ nickname_img = ImageData(size_x, 8);
			
			int nn_last_pos_x = 0;
			
			for(int char = 0; char < _player_name.size(); char++)
			{
				int id = _player_name[char]-32;
				u8 letter_size = sizes[id];
				int characters_pos_x = 0;
				for(int i = 0; i < id; i++)
				{
					characters_pos_x += sizes[i]+1;
				}
				
				//print(""+_player_name[char]);
				
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
			Texture::createFromData(_player_name+"_NN", nickname_img);
		}
		else
		{
			ImageData@ nickname_img = Texture::data(_player_name+"_NN");
			size_x = nickname_img.width();
		}
		f32 letter_ratio = 1.0f/64.0f;
		f32 letter_heigth = letter_ratio*8;
		f32 text_start = 0-letter_ratio*size_x/2;
		f32 text_end = letter_ratio*size_x/2;
		Vertex[] _Vertexes = {	Vertex(text_start,	letter_heigth,	0, 0,0,	SColor(170, 255, 255, 255)),
								Vertex(text_end,	letter_heigth,	0, 1,0,	SColor(170, 255, 255, 255)),
								Vertex(text_end,	0,				0, 1,1,	SColor(170, 255, 255, 255)),
								Vertex(text_start,	0,				0, 0,1,	SColor(170, 255, 255, 255))};
		u16[] v_ids = {0,1,2,0,2,3};
		Vertexes = _Vertexes;
		IDs = v_ids;

		SMaterial material;
		material.AddTexture(_player_name+"_NN", 0);
        material.DisableAllFlags();
		material.SetFlag(SMaterial::COLOR_MASK, true);
		material.SetFlag(SMaterial::ZBUFFER, true);
        material.SetFlag(SMaterial::ZWRITE_ENABLE, true);
		material.SetFlag(SMaterial::BLEND_OPERATION, true);
		material.SetMaterialType(SMaterial::TRANSPARENT_ALPHA_CHANNEL_REF);

		print("aaaaa");
		mesh_nn.Clear();
		mesh_nn.SetMaterial(material);
		mesh_nn.SetVertex(_Vertexes);
		mesh_nn.SetIndices(v_ids);
		mesh_nn.SetDirty(SMesh::VERTEX_INDEX);
		mesh_nn.SetHardwareMapping(SMesh::DYNAMIC);
		mesh_nn.BuildMesh();
		//mesh_nn.RenderMesh();

		//Mesh.LoadObjIntoMesh("Models/Camera/Camera.obj");
		//Mesh.GetMaterial().SetFlag(SMaterial::LIGHTING, false);
		//Mesh.GetMaterial().SetFlag(SMaterial::BILINEAR_FILTER, false);
		//Mesh.BuildMesh();
	}

	//void Render()
	//{
		//this.Mesh.RenderMesh();
	//}
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