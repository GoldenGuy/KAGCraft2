
#include "Blocks.as"

MapSender[] players_to_send;
class MapSender
{
    CPlayer@ player;
    uint32 packet_number = 0;

    MapSender(CPlayer@ _player, uint32 _packet_number)
    {
        @player = @_player;
        packet_number = _packet_number;
    }
}

class World
{
    bool save_map;
    string map_name = "";
    bool new = true;

    uint32 map_save_time = 10;
    
    uint32 chunk_width = 14;
    uint32 chunk_depth = 14;
    uint32 chunk_height = 14;
    uint32 chunk_size = chunk_width*chunk_depth*chunk_height;

    uint32 world_width = 32;
    uint32 world_depth = 32;
    uint32 world_height = 8;
    uint32 world_width_depth = world_width * world_depth;
    uint32 world_size = world_width_depth * world_height;

    uint32 map_width = world_width * chunk_width;
    uint32 map_depth = world_depth * chunk_depth;
    uint32 map_height = world_height * chunk_height;
    uint32 map_width_depth = map_width * map_depth;
    uint32 map_size = map_width_depth * map_height;

    SColor sky_color = 0xFF89A2ED;

    // map gen

    CFileImage@ save_image;
    
    float initial_plane = 0.0017;
    float initial_plane_max_height = 0.35f;
    float initial_plane_add_max = 0.16f;
    float hills_spread = 0.048f;

    float tree_frequency = 0.06f;
    float grass_frequency = 0.08f;

    // map sending and receiving

    uint32 map_packet_size = chunk_width*chunk_depth*chunk_height*8; // 16 chunks per packet
    uint32 map_packets_amount = map_size / map_packet_size;

    // client

    CBitStream@[] map_packets;
    uint32 current_map_packet;

    uint32 block_faces_packets_amount = map_packets_amount;
    uint32 block_faces_packet_size = map_size / block_faces_packets_amount;
    uint32 current_block_faces_packet;

    uint32 chunks_packets_amount = world_depth*world_height;
    uint32 chunks_packet_size = world_size / chunks_packets_amount;
    uint32 current_chunks_packet;
    
    // y z x
    //uint8[][][] map;
    uint8[] map;
    //uint8[][][] faces_bits;
    uint8[] faces_bits;
    Chunk@[] chunks;
    SMaterial map_material;

    Noise@ noise;
    Random@ rand;

    World()
    {
        map.clear();
        faces_bits.clear();
        chunks.clear();
    }

    void LoadMapParams()
    {
        ConfigFile cfg = ConfigFile();
        if (!cfg.loadFile(CFileMatcher("KCServerConfig.cfg").getFirst()))
        {
            error("Could not find config file! Using default parameters.");
            return;
        }
        else
        {
            print("Loading map parameters.");

            save_map = cfg.read_bool("save_map");
            
            map_save_time = cfg.read_s32("map_save_time");
            if(map_save_time != -1) map_save_time = map_save_time*60*getTicksASecond();

            map_name = cfg.read_string("map_name");
            if(map_name == "")
            {
                map_name = Time_Month()+"_"+Time_Local();
                new = true;
            }
            else
            {
                ConfigFile map_cfg;
                if(map_cfg.loadFile("../Cache/KagCraft2/map_info_"+map_name+".cfg"))
                {
                    print("Map \""+map_name+"\" exists, preparing to load it.");
                    //ConfigFile map_cfg = ConfigFile(CFileMatcher("../Cache/KagCraft2/"+map_name+"/map_info.cfg").getFirst());
                    //print(CFileMatcher("../Cache/KagCraft2/"+map_name+"/map_info.cfg").getFirst());

                    chunk_width = map_cfg.read_u32("c_w");
                    chunk_depth = map_cfg.read_u32("c_d");
                    chunk_height = map_cfg.read_u32("c_h");
                    chunk_size = chunk_width*chunk_depth*chunk_height;

                    world_width = map_cfg.read_u32("w_w");
                    world_depth = map_cfg.read_u32("w_d");
                    world_height = map_cfg.read_u32("w_h");
                    world_width_depth = world_width * world_depth;
                    world_size = world_width_depth * world_height;

                    map_width = world_width * chunk_width;
                    map_depth = world_depth * chunk_depth;
                    map_height = world_height * chunk_height;
                    map_width_depth = map_width * map_depth;
                    map_size = map_width_depth * map_height;

                    map_packet_size = chunk_width*chunk_depth*chunk_height*8;
                    map_packets_amount = map_size / map_packet_size;
                    block_faces_packets_amount = map_packets_amount;
                    block_faces_packet_size = map_size / block_faces_packets_amount;
                    chunks_packets_amount = world_depth*world_height;
                    chunks_packet_size = world_size / chunks_packets_amount;

                    uint32 sky_color_R = map_cfg.read_u32("s_r");
                    uint32 sky_color_G = map_cfg.read_u32("s_g");
                    uint32 sky_color_B = map_cfg.read_u32("s_b");
                    sky_color = SColor(255, sky_color_R, sky_color_G, sky_color_B);

                    @save_image = CFileImage("Maps/KagCraft2/map_data_"+map_name+".png");

                    new = false;
                    return;
                }
                else
                {
                    new = true;
                }
            }

            print("Creating new map with name \""+map_name+"\".");

            chunk_width = cfg.read_u32("chunk_width");
            chunk_depth = cfg.read_u32("chunk_depth");
            chunk_height = cfg.read_u32("chunk_height");
            chunk_size = chunk_width*chunk_depth*chunk_height;

            world_width = cfg.read_u32("world_width");
            world_depth = cfg.read_u32("world_depth");
            world_height = cfg.read_u32("world_height");
            world_width_depth = world_width * world_depth;
            world_size = world_width_depth * world_height;

            map_width = world_width * chunk_width;
            map_depth = world_depth * chunk_depth;
            map_height = world_height * chunk_height;
            map_width_depth = map_width * map_depth;
            map_size = map_width_depth * map_height;

            map_packet_size = chunk_width*chunk_depth*chunk_height*8;
            map_packets_amount = map_size / map_packet_size;
            block_faces_packets_amount = map_packets_amount;
            block_faces_packet_size = map_size / block_faces_packets_amount;
            chunks_packets_amount = world_depth*world_height;
            chunks_packet_size = world_size / chunks_packets_amount;

            uint8 sky_color_R = cfg.read_u8("sky_color_R");
            uint8 sky_color_G = cfg.read_u8("sky_color_G");
            uint8 sky_color_B = cfg.read_u8("sky_color_B");
            sky_color = SColor(255, sky_color_R, sky_color_G, sky_color_B);
            //getRules().set("sky_color", @sky_color);

            initial_plane = cfg.read_f32("initial_plane");
            initial_plane_max_height = cfg.read_f32("initial_plane_max_height");
            initial_plane_add_max = cfg.read_f32("initial_plane_add_max");
            hills_spread = cfg.read_f32("hills_spread");
            tree_frequency = cfg.read_f32("tree_frequency");
            grass_frequency = cfg.read_f32("grass_frequency");
        }
    }

    void GenerateMap()
    {
        print("Generating map.");
        map.clear();

        uint32 seed = (114748346*Time_Local()+Time_Local()) % 500000;

        print("Map seed: "+seed);

        @noise = @Noise(seed);
        @rand = @Random(seed);
        
        float something = 1.0f/map_height;
    
        Vec3f[] trees;
        trees.clear();
        
        //uint8[][][] _map(map_height, uint8[][](map_depth, uint8[](map_width, 0)));
        //map = _map;
        map.resize(map_size);

        print("Map size: "+(map_height*map_depth*map_width));

        int temp = int(Maths::Sqrt(float(map_height*map_depth*map_width)/4.0f))+2;

        @save_image = CFileImage(temp, temp, true);
        save_image.setFilename("KagCraft2/map_data_"+map_name+".png", ImageFileBase::IMAGE_FILENAME_BASE_MAPS);
        //int map_index = 0; 
        //u8 rgba = 0; // 0 - red, 1 - green, 2 - blue, 3 - alpha

        for(float z = 0.0f; z < map_depth; z += 1.0f)
        {
            for(float x = 0.0f; x < map_width; x += 1.0f)
            {
                float initial_plane_height = noise.Fractal(x * initial_plane, z * initial_plane);
                float hills = ((1-noise.Sample(x * hills_spread, z * hills_spread)) * (1-noise.Sample((x+map_width) * hills_spread, z * hills_spread)) * (1-noise.Sample(x * hills_spread, (z+map_depth) * hills_spread)) * (1-noise.Sample((x+map_width) * hills_spread, (z+map_depth) * hills_spread)));

                float real_height = ((float(map_height)*initial_plane_max_height + float(map_height)*initial_plane_max_height*initial_plane_height) + (float(map_height)*0.65f*hills));
                float stone = ((float(map_height)*initial_plane_max_height + float(map_height)*initial_plane_max_height*initial_plane_height) + (float(map_height)*0.65f*Maths::Pow(hills, 0.6f))) - float(map_height)*0.12f;

                for(float y = 0.0f; y < map_height; y += 1.0f)
                {
                    if(y > real_height)
                    {
                        break;
                    }
                    else
                    {
                        if(y < stone)
                        {
                            setBlock(x, y, z, Block::stone);
                            setSaveSubPixel(x, y, z, Block::stone);
                            continue;
                        }
                        else 
                        {
                            if(y+1.0f > real_height)
                            {
                                // living stuff
                                {
                                    bool make_tree = noise.Sample((map_width+x)*tree_frequency, z*tree_frequency) > 0.7;
                                    if(make_tree && rand.NextRanged(70) > 2) make_tree = false;

                                    bool make_grass = noise.Sample(x*grass_frequency, (map_depth+z)*grass_frequency) > 0.6;
                                    if(make_grass && rand.NextRanged(50) > 40) make_grass = false;
                                    bool make_flower = rand.NextRanged(24) == 1;
                                    bool flower_type = rand.NextRanged(4) >= 2;

                                    if(make_tree)
                                    {
                                        trees.push_back(Vec3f(x,y+1,z));
                                        setBlock(x, y, z, Block::dirt);
                                        setSaveSubPixel(x, y, z, Block::dirt);
                                        continue;
                                    }
                                    else if(make_grass)
                                    {
                                        if(make_flower)
                                        {
                                            if(flower_type)
                                            {
                                                setBlock(x, y+1, z, Block::tulip);
                                                setSaveSubPixel(x, y+1, z, Block::tulip);
                                            }
                                            else
                                            {
                                                setBlock(x, y+1, z, Block::edelweiss);
                                                setSaveSubPixel(x, y+1, z, Block::edelweiss);
                                            }
                                        }
                                        else
                                        {
                                            setBlock(x, y+1, z, Block::grass);
                                            setSaveSubPixel(x, y+1, z, Block::grass);
                                        }
                                    }
                                    setBlock(x, y, z, Block::grass_dirt);
                                    setSaveSubPixel(x, y, z, Block::grass_dirt);
                                }
                                continue;
                            }
                            else
                            {
                                setBlock(x, y, z, Block::dirt);
                                setSaveSubPixel(x, y, z, Block::dirt);
                                continue;
                            }
                        }
                    }
                }
            }
        }
        
        print("Planting trees...");
        for(int i = 0; i < trees.size(); i++)
        {
            MakeTree(trees[i]);
        }
        print("Map generated.");
        SaveMap();
    }

    void MakeTree(Vec3f pos)
	{
		uint8 tree_type = Block::log;
		if(XORRandom(3) == 0)
			tree_type = Block::log_birch;
		if(inWorldBounds(pos.x, pos.y, pos.z))
		{
			setBlockSafe(pos.x, pos.y, pos.z, tree_type);
            setSaveSubPixel(pos.x, pos.y, pos.z, tree_type);
			pos.y += 1;
			if(inWorldBounds(pos.x, pos.y, pos.z))
			{
				setBlockSafe(pos.x, pos.y, pos.z, tree_type);
                setSaveSubPixel(pos.x, pos.y, pos.z, tree_type);
				pos.y += 1;
				if(inWorldBounds(pos.x, pos.y, pos.z))
				{
					setBlockSafe(pos.x, pos.y, pos.z, tree_type);
                    setSaveSubPixel(pos.x, pos.y, pos.z, tree_type);
					
					for(int _z = -2; _z <= 2; _z++)
						for(int _x = -2; _x <= 2; _x++)
							if(!(_x == 0 && _z == 0))
                            {
								setBlockSafe(pos.x+_x, pos.y, pos.z+_z, Block::leaves);
                                setSaveSubPixel(pos.x+_x, pos.y, pos.z+_z, Block::leaves);
                            }
					
					pos.y += 1;
					if(inWorldBounds(pos.x, pos.y, pos.z))
					{
						setBlockSafe(pos.x, pos.y, pos.z, tree_type);
                        setSaveSubPixel(pos.x, pos.y, pos.z, tree_type);
						
						for(int _z = -2; _z <= 2; _z++)
							for(int _x = -2; _x <= 2; _x++)
								if(!(_x == 0 && _z == 0))
                                {
									setBlockSafe(pos.x+_x, pos.y, pos.z+_z, Block::leaves);
                                    setSaveSubPixel(pos.x+_x, pos.y, pos.z+_z, Block::leaves);
                                }
						
						pos.y += 1;
						if(inWorldBounds(pos.x, pos.y, pos.z))
						{
							setBlockSafe(pos.x, pos.y, pos.z, tree_type);
                            setSaveSubPixel(pos.x, pos.y, pos.z, tree_type);
							
							for(int _z = -1; _z <= 1; _z++)
								for(int _x = -1; _x <= 1; _x++)
									if(!(_x == 0 && _z == 0))
                                    {
										setBlockSafe(pos.x+_x, pos.y, pos.z+_z, Block::leaves);
                                        setSaveSubPixel(pos.x+_x, pos.y, pos.z+_z, Block::leaves);
                                    }
							
							pos.y += 1;
							if(inWorldBounds(pos.x, pos.y, pos.z))
							{
								setBlockSafe(pos.x+1, pos.y, pos.z, Block::leaves);
								setBlockSafe(pos.x-1, pos.y, pos.z, Block::leaves);
								setBlockSafe(pos.x, pos.y, pos.z, Block::leaves);
								setBlockSafe(pos.x, pos.y, pos.z+1, Block::leaves);
								setBlockSafe(pos.x, pos.y, pos.z-1, Block::leaves);

                                setSaveSubPixel(pos.x+1, pos.y, pos.z, Block::leaves);
								setSaveSubPixel(pos.x-1, pos.y, pos.z, Block::leaves);
								setSaveSubPixel(pos.x, pos.y, pos.z, Block::leaves);
								setSaveSubPixel(pos.x, pos.y, pos.z+1, Block::leaves);
								setSaveSubPixel(pos.x, pos.y, pos.z-1, Block::leaves);
								getNet().server_KeepConnectionsAlive();
							}
						}
					}
					getNet().server_KeepConnectionsAlive();
				}
			}
		}
		getNet().server_KeepConnectionsAlive();
	}

    void LoadMap()
    {
        print("Loading existing map.");

        uint32 seed = (114748346*Time_Local()+Time_Local()) % 500000;

        @noise = @Noise(seed);
        @rand = @Random(seed);

        //uint8[][][] _map(map_height, uint8[][](map_depth, uint8[](map_width, 0)));
        //map = _map;
        //map_1d.resize(map_size);
        map.resize(map_size);

        bool done = false;
        if (save_image.isLoaded())
		{
			while(save_image.nextPixel() && !done)
			{
                int index = save_image.getPixelOffset()*4;
                if(index >= map_size)
                {
                    done = true;
                    break;
                }
                u8 a;
                u8 r;
                u8 g;
                u8 b;
                save_image.readPixel(a, r, g, b);

                Vec3f pos = getPosFromWorldIndex(index);
                setBlock(pos.x, pos.y, pos.z, a);
                //map_1d[pos.x+pos.z*map_width+pos.y*map_width_depth] = a;

                if(index+1 >= map_size)
                {
                    done = true;
                    break;
                }
                else
                {
                    pos = getPosFromWorldIndex(index+1);
                    setBlock(pos.x, pos.y, pos.z, r);
                    //map_1d[pos.x+pos.z*map_width+pos.y*map_width_depth] = r;
                }
                if(index+2 >= map_size)
                {
                    done = true;
                    break;
                }
                else
                {
                    pos = getPosFromWorldIndex(index+2);
                    setBlock(pos.x, pos.y, pos.z, g);
                    //map_1d[pos.x+pos.z*map_width+pos.y*map_width_depth] = g;
                }
                if(index+3 >= map_size)
                {
                    done = true;
                    break;
                }
                else
                {
                    pos = getPosFromWorldIndex(index+3);
                    setBlock(pos.x, pos.y, pos.z, b);
                    //map_1d[pos.x+pos.z*map_width+pos.y*map_width_depth] = b;
                }
            }
            print("Done!");
        }
        else
        {
            error("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA");
        }
    }

    void SaveMap()
    {
        if(!save_map) {print("lol, no, not gonna save the map :P"); return;}

        world.save_image.Save();

        ConfigFile cfg;

        cfg.add_u32("c_w", chunk_width);
        cfg.add_u32("c_d", chunk_depth);
        cfg.add_u32("c_h", chunk_height);
        cfg.add_u32("w_w", world_width);
        cfg.add_u32("w_d", world_depth);
        cfg.add_u32("w_h", world_height);

        u32 R = sky_color.getRed();
        u32 G = sky_color.getGreen();
        u32 B = sky_color.getBlue();

        cfg.add_u32("s_r", R);
        cfg.add_u32("s_g", G);
        cfg.add_u32("s_b", B);

        cfg.saveFile("KagCraft2/map_info_"+map_name+".cfg");
        print("Map saved!");
    }

    void setSaveSubPixel(int x, int y, int z, uint8 block)
    {
        if(!inWorldBounds(x, y, z)) return;

        uint map_index = toIndex(x, y, z);
        uint image_index = map_index / 4;
        u8 sub_pixel = map_index % 4;
        save_image.setPixelOffset(image_index);
        SColor new_col = save_image.readPixel();
        switch(sub_pixel)
        {
            case 0:
                new_col.setAlpha(block);
                break;
            case 1:
                new_col.setRed(block);
                break;
            case 2:
                new_col.setGreen(block);
                break;
            case 3:
                new_col.setBlue(block);
                break;
        }
        save_image.setPixel(new_col.getAlpha(), new_col.getRed(), new_col.getGreen(), new_col.getBlue());
    }

    void saveBlock(int x, int y, int z, uint8 block)
    {
        //if(!inWorldBounds(x, y, z)) return;
        //CFileImage image("../Cache/KagCraft2/"+map_name+"/data.png");
        setSaveSubPixel(x, y, z, block);
        //save_image.Save();
    }

    void BlockUpdate(int x, int y, int z, uint8 new_block, uint8 old_block)
    {
        if(isClient())
        {
            if(!Block::solid[new_block] && !Block::plant[new_block])
            {
                if(Block::plant[old_block])
                {
                    PlaySound3D("cut_grass2.ogg", x, y, z);
                    CreateBlockParticles(old_block, Vec3f(x+0.5,y+0.5,z+0.5));
                }
                else if(Block::solid[old_block])
                {
                    switch(old_block)
                    {
                        case Block::grass_dirt:
                        case Block::dirt:
                        {
                            PlaySound3D("destroy_dirt.ogg", x, y, z);
                            break;
                        }
                        case Block::crate:
                        case Block::log_birch:
                        case Block::log:
                        case Block::planks_birch:
                        case Block::planks:
                        case Block::log_palm:
                        {
                            PlaySound3D("destroy_wood.ogg", x, y, z);
                            break;
                        }
                        case Block::leaves:
                        case Block::wool_red:
                        case Block::wool_orange:
                        case Block::wool_yellow:
                        case Block::wool_green:
                        case Block::wool_cyan:
                        case Block::wool_blue:
                        case Block::wool_darkblue:
                        case Block::wool_purple:
                        case Block::wool_white:
                        case Block::wool_gray:
                        case Block::wool_black:
                        case Block::wool_brown:
                        case Block::wool_pink:
                        {
                            PlaySound3D("cut_grass1.ogg", x, y, z);
                            break;
                        }
                        case Block::glass:
                        {
                            PlaySound3D("GlassBreak2.ogg", x, y, z);
                            break;
                        }
                        case Block::hard_stone:
                        case Block::metal_shiny:
                        case Block::metal:
                        case Block::gearbox:
                        case Block::fence:
                        {
                            PlaySound3D("destroy_stone.ogg", x, y, z);
                            break;
                        }
                        case Block::gold:
                        {
                            PlaySound3D("destroy_gold.ogg", x, y, z);
                            break;
                        }
                        case Block::sand:
                        {
                            PlaySound3D("sand_fall.ogg", x, y, z);
                            break;
                        }
                        case Block::water:
                        case Block::watersecond:
                        {
                            PlaySound3D("WaterBubble2.ogg", x, y, z);
                            break;
                        }

                        default:
                        {
                            PlaySound3D("destroy_wall.ogg", x, y, z);
                            break;
                        }
                    }
                    CreateBlockParticles(old_block, Vec3f(x+0.5,y+0.5,z+0.5));
                }
            }
            else
            {
                switch(new_block)
                {
                    case Block::grass_dirt:
                    case Block::dirt:
                    case Block::sand:
                    {
                        PlaySound3D("dig_dirt1.ogg", x, y, z);
                        break;
                    }
                    case Block::crate:
                    case Block::log_birch:
                    case Block::log:
                    case Block::planks_birch:
                    case Block::planks:
                    case Block::log_palm:
                    {
                        PlaySound3D("build_ladder.ogg", x, y, z);
                        break;
                    }
                    case Block::wool_red:
                    case Block::wool_orange:
                    case Block::wool_yellow:
                    case Block::wool_green:
                    case Block::wool_cyan:
                    case Block::wool_blue:
                    case Block::wool_darkblue:
                    case Block::wool_purple:
                    case Block::wool_white:
                    case Block::wool_gray:
                    case Block::wool_black:
                    case Block::wool_brown:
                    case Block::wool_pink:
                    {
                        PlaySound3D("thud.ogg", x, y, z);
                        break;
                    }
                    case Block::leaves:
                    case Block::grass:
                    case Block::tulip:
                    case Block::edelweiss:
                    {
                        PlaySound3D("dig_dirt2.ogg", x, y, z);
                        break;
                    }
                    case Block::glass:
                    {
                        PlaySound3D("dry_hit.ogg", x, y, z);
                        break;
                    }
                    case Block::hard_stone:
                    case Block::metal_shiny:
                    case Block::metal:
                    case Block::gearbox:
                    case Block::fence:
                    case Block::gold:
                    {
                        PlaySound3D("dig_stone1.ogg", x, y, z);
                        break;
                    }
                    case Block::water:
                    case Block::watersecond:
                    {
                        PlaySound3D("wetfall1.ogg", x, y, z);
                        break;
                    }

                    default:
                    {
                        PlaySound3D("build_wall2.ogg", x, y, z);
                        break;
                    }
                }
            }
        }
        
        if(isServer())
        {
            if(Block::solid[new_block])
            {
                uint8 block_below = getBlockSafe(x, y-1, z);
                if(block_below < Block::blocks_count)
                {
                    if(block_below == Block::grass_dirt)
                    {
                        server_SetBlock(Block::dirt, x, y-1, z);
                        saveBlock(x, y-1, z, Block::dirt);
                    }
                }
            }
            else if(!Block::plant[new_block])
            {
                uint8 block_above = getBlockSafe(x, y+1, z);
                if(block_above < Block::blocks_count)
                {
                    if(Block::plant[block_above])
                    {
                        server_SetBlock(Block::air, x, y+1, z);
                        saveBlock(x, y+1, z, Block::air);
                    }
                }
            }
            else
            {
                uint8 block_below = getBlockSafe(x, y-1, z);
                if(block_below < Block::blocks_count)
                {
                    if(block_below == Block::dirt)
                    {
                        server_SetBlock(Block::grass_dirt, x, y-1, z);
                        saveBlock(x, y-1, z, Block::grass_dirt);
                    }
                }
            }
        }
    }

    void ClientMapSetUp()
    {
        //uint8[][][] _map(map_height, uint8[][](map_depth, uint8[](map_width, 0)));
        //map = _map;
        map.resize(map_size);

        @noise = @Noise(XORRandom(10000000));

        chunks.clear();
    }

    void FacesSetUp()
    {
        //uint8[][][] _faces_bits(map_height, uint8[][](map_depth, uint8[](map_width, 0)));
        //faces_bits = _faces_bits;
        faces_bits.resize(map_size);
    }

    void SetUpMaterial()
    {
        map_material.AddTexture("Block_Textures", 0);
        map_material.DisableAllFlags();
        map_material.SetFlag(SMaterial::COLOR_MASK, true);
        map_material.SetFlag(SMaterial::ZBUFFER, true);
        map_material.SetFlag(SMaterial::ZWRITE_ENABLE, true);
        map_material.SetFlag(SMaterial::BACK_FACE_CULLING, true);
        map_material.SetMaterialType(SMaterial::TRANSPARENT_ALPHA_CHANNEL_REF);
        map_material.SetFlag(SMaterial::FOG_ENABLE, true);

        getRules().set("map_material", @map_material);
    }

    void setBlockSafe(int x, int y, int z, uint8 block_id)
    {
        if(inWorldBounds(x, y, z)) setBlock(x, y, z, block_id);
    }

    void setBlockSafe(uint32 index, uint8 block_id)
    {
        if(index < 0 || index >= map_size) setBlock(index, block_id);
    }

    void setBlock(uint32 x, uint32 y, uint32 z, uint8 block_id)
    {
        //map[y][z][x] = block_id;
        map[x+z*map_width+y*map_width_depth] = block_id;
    }

    void setBlock(uint32 index, uint8 block_id)
    {
        map[index] = block_id;
    }

    uint8 getBlockSafe(int x, int y, int z)
    {
        if(inWorldBounds(x, y, z)) return getBlock(x, y, z);
        return 255;
    }

    uint8 getBlockSafe(uint32 index)
    {
        if(index < 0 || index >= map_size) return getBlock(index);
        return 255;
    }

    uint8 getBlock(int x, int y, int z)
    {
        //return map[y][z][x];
        return map[x+z*map_width+y*map_width_depth];
    }

    uint8 getBlock(uint32 index)
    {
        return map[index];
    }

    void SetUpChunks(uint32 chunk_packet)
    {
        uint32 start = chunk_packet*chunks_packet_size;
        uint32 end = start+chunks_packet_size;

        for(int i = start; i < end; i++)
        {
            Chunk chunk(this, i);
            chunks.push_back(@chunk);
            getNet().server_KeepConnectionsAlive();
        }
    }

    void GenerateBlockFaces(uint32 block_faces_packet)
    {
        uint32 start = block_faces_packet*block_faces_packet_size;
        uint32 end = start+block_faces_packet_size;
        Vec3f pos;
        uint8 block_id;

        for(uint32 i = start; i < end; i++)
        {
            pos = getPosFromWorldIndex(i);
            uint8 block = getBlock(i);//pos.x, pos.y, pos.z);
            SetBlockFaces(block, pos.x, pos.y, pos.z);
            if(pos.y == map_height-1)// && !Block::see_through[block])
            {
                faces_bits[i] += 4;
            }
            getNet().server_KeepConnectionsAlive();
        }
    }

    void SetBlockFaces(uint8 block, int x, int y, int z)
    {
        if(Block::see_through[block])
        {
            if(z < map_depth-1) faces_bits[toIndex(x, y, z+1)] += 1;
            if(z > 0) faces_bits[toIndex(x, y, z-1)] += 2;
            if(y > 0) faces_bits[toIndex(x, y-1, z)] += 4;
            if(y < map_height-1) faces_bits[toIndex(x, y+1, z)] += 8;
            if(x > 0) faces_bits[toIndex(x-1, y, z)] += 16;
            if(x < map_width-1) faces_bits[toIndex(x+1, y, z)] += 32;
        }
    }

    void UpdateBlockFaces(int x, int y, int z)
    {
        if(getBlock(x, y, z) == Block::air)
        {
            faces_bits[toIndex(x, y, z)] = 0;
            return;
        }
        
        uint8 faces = 0;

        if(z > 0 && Block::see_through[getBlock(x, y, z-1)]) faces += 1;
        if(z < map_depth-1 && Block::see_through[getBlock(x, y, z+1)]) faces += 2;
        if(y < map_height-1)
        {
            if(Block::see_through[getBlock(x, y+1, z)])
            {
                faces += 4;
            }
        }
        else if(y == map_height-1)
        {
            faces += 4;
        }
        if(y > 0 && Block::see_through[getBlock(x, y-1, z)]) faces += 8;
        if(x < map_width-1 && Block::see_through[getBlock(x+1, y, z)]) faces += 16;
        if(x > 0 && Block::see_through[getBlock(x-1, y, z)]) faces += 32;

        faces_bits[toIndex(x, y, z)] = faces;
    }

    int32 toIndex(int x, int y, int z)
    {
        int index = y*map_width_depth + z*map_width + x;
        return index;
    }

    Vec3f getPosFromWorldIndex(int index)
    {
        return Vec3f(index % map_width, index / map_width_depth, (index / map_width) % map_depth);
    }

    void Serialize(CBitStream@ to_send, uint32 map_packet)
    {
        uint32 start = map_packet*map_packet_size;
        uint32 end = start+map_packet_size;
        Vec3f pos;
        uint8 block_id;

        uint32 similars = 0;
        uint8 similar_block_id = 0;

        for(uint32 i = start; i < end; i++)
        {
            pos = getPosFromWorldIndex(i);
            block_id = getBlock(pos.x, pos.y, pos.z);
            if(i == start)
            {
                similar_block_id = block_id;
                similars++;
                continue;
            }
            else
            {
                if(similar_block_id == block_id)
                {
                    similars++;
                    continue;
                }
                else
                {
                    to_send.write_u32(similars);
                    to_send.write_u8(similar_block_id);
                    similar_block_id = block_id;
                    similars = 1;
                }
            }
            getNet().server_KeepConnectionsAlive();
        }
        to_send.write_u32(similars);
        to_send.write_u8(similar_block_id);
    }

    void UnSerialize(CBitStream@ to_read, uint32 packet)
    {
        uint32 start = packet*map_packet_size;
        uint32 end = start+map_packet_size;
        Vec3f pos;
        uint8 block_id;

        uint32 index = 0;

        while(index < map_packet_size)
        {
            uint32 amount = to_read.read_u32();
            uint8 block_id = to_read.read_u8();
            for(uint32 j = 0; j < amount; j++)
            {
                if(index == map_packet_size)
                {
                    return;
                }
                uint32 map_index = start+index;
                pos = getPosFromWorldIndex(start+index);
                //map[pos.y][pos.z][pos.x] = block_id;
                setBlock(map_index, block_id);
                SetBlockFaces(block_id, pos.x, pos.y, pos.z);
                if(pos.y == map_height-1)// && !Block::see_through[block_id])
                {
                    faces_bits[map_index] += 4;
                }
                index++;
            }
        }
    }

    Chunk@ getChunk(int x, int y, int z)
    {
        if(!inChunkBounds(x, y, z)) return null;
        int index = y*world_width_depth + z*world_width + x;
        Chunk@ chunk = @chunks[index];
        return @chunk;
    }

    Chunk@ getChunkWorldPos(int x, int y, int z)
    {
        if(!inWorldBounds(x, y, z)) return null;
        x /= chunk_width; y /= chunk_height; x /= chunk_depth;
        int index = y*world_width_depth + z*world_width + x;
        Chunk@ chunk = @chunks[index];
        return @chunk;
    }

    bool inWorldBounds(int x, int y, int z)
    {
        if(x<0 || y<0 || z<0 || x>=map_width || y>=map_height || z>=map_depth) return false;
        return true;
    }

    bool inWorldBoundsIgnoreHeight(int x, int y, int z)
    {
        if(x<0 || y<0 || z<0 || x>=map_width || z>=map_depth) return false;
        return true;
    }
    
    bool inChunkBounds(int x, int y, int z)
    {
        if(x<0 || y<0 || z<0 || x>=world_width || y>=world_height || z>=world_depth) return false;
        return true;
    }

    bool isTileSolid(int x, int y, int z)
    {
        if(!inWorldBounds(x, y, z)) return false;
        return Block::solid[getBlock(x, y, z)];
    }

    bool isTileSolidOrOOB(int x, int y, int z)
    {
        if(!inWorldBounds(x, y, z)) return true;
        return Block::solid[getBlock(x, y, z)];
    }

    bool isTileSolidOrOOBIgnoreHeight(int x, int y, int z)
    {
        if(inWorldBounds(x, y, z))
        {
            return Block::solid[getBlock(x, y, z)];
        }
        return !inWorldBoundsIgnoreHeight(x, y, z);
    }

    void UpdateBlocksAndChunks(int x, int y, int z)
    {
        world.UpdateBlockFaces(x, y, z);
        if(x > 0) world.UpdateBlockFaces(x-1, y, z);
        if(x+1 < map_width) world.UpdateBlockFaces(x+1, y, z);
        if(y > 0) world.UpdateBlockFaces(x, y-1, z);
        if(y+1 < map_height) world.UpdateBlockFaces(x, y+1, z);
        if(z > 0) world.UpdateBlockFaces(x, y, z-1);
        if(z+1 < map_depth) world.UpdateBlockFaces(x, y, z+1);

        Vec3f chunk_pos = Vec3f(int(x/chunk_width), int(y/chunk_height), int(z/chunk_depth));
        {Chunk@ chunk = world.getChunk(chunk_pos.x, chunk_pos.y, chunk_pos.z);if(chunk !is null){chunk.rebuild = true;chunk.empty = false;}}

        if(x % chunk_width == 0) {Chunk@ chunk = world.getChunk(chunk_pos.x-1, chunk_pos.y, chunk_pos.z); if(chunk !is null) {chunk.rebuild = true; chunk.empty = false;}}
        else if(x % chunk_width == chunk_width-1) {Chunk@ chunk = world.getChunk(chunk_pos.x+1, chunk_pos.y, chunk_pos.z); if(chunk !is null) {chunk.rebuild = true; chunk.empty = false;}}
        if(y % chunk_height == 0) {Chunk@ chunk = world.getChunk(chunk_pos.x, chunk_pos.y-1, chunk_pos.z); if(chunk !is null) {chunk.rebuild = true; chunk.empty = false;}}
        else if(y % chunk_height == chunk_height-1) {Chunk@ chunk = world.getChunk(chunk_pos.x, chunk_pos.y+1, chunk_pos.z); if(chunk !is null) {chunk.rebuild = true; chunk.empty = false;}}
        if(z % chunk_depth == 0) {Chunk@ chunk = world.getChunk(chunk_pos.x, chunk_pos.y, chunk_pos.z-1); if(chunk !is null) {chunk.rebuild = true; chunk.empty = false;}}
        else if(z % chunk_depth == chunk_depth-1) {Chunk@ chunk = world.getChunk(chunk_pos.x, chunk_pos.y, chunk_pos.z+1); if(chunk !is null) {chunk.rebuild = true; chunk.empty = false;}}
    }
}

class Chunk
{
    World@ _world;
    uint32 x, y, z, world_x, world_y, world_z, world_x_bounds, world_y_bounds, world_z_bounds;
    uint32 index, world_index;
    bool rebuild, empty;
    SMesh mesh;
    Vertex[] verts;
    uint16[] indices;
    AABB box;

    Chunk(){}

    Chunk(World@ reference, uint32 _index)
    {
        @_world = @reference;
        mesh.Clear();
        mesh.SetHardwareMapping(SMesh::STATIC);
        index = _index;
        x = _index % _world.world_width; z = (_index / _world.world_width) % _world.world_depth; y = _index / _world.world_width_depth;
        world_x = x*_world.chunk_width; world_z = z*_world.chunk_depth; world_y = y*_world.chunk_height;
        world_x_bounds = world_x+_world.chunk_width; world_z_bounds = world_z+_world.chunk_depth; world_y_bounds = world_y+_world.chunk_height;
        box = AABB(Vec3f(world_x, world_y, world_z), Vec3f(world_x_bounds, world_y_bounds, world_z_bounds));

        GenerateMesh();
    }

    void GenerateMesh()
    {
        rebuild = false;
        verts.clear();
        indices.clear();
        empty = false;

        for (int _y = world_y; _y < world_y_bounds; _y++)
		{
			for (int _z = world_z; _z < world_z_bounds; _z++)
			{
				for (int _x = world_x; _x < world_x_bounds; _x++)
				{
                    int faces = _world.faces_bits[_world.toIndex(_x, _y, _z)];

                    if(faces == 0) continue;

                    uint8 block = _world.getBlock(_x, _y, _z);

                    if(block == Block::air) continue;

                    if(Block::plant[block])
                    {
                        addPlantFaces(block, _x, _y, _z);
                    }
                    else
                    {
                        addFaces(block, faces, _x, _y, _z);
                    }
                }
            }
        }
        if(verts.size() == 0)
        {
            empty = true;
            mesh.Clear();
        }
        else
        {
            mesh.SetVertex(verts);
            mesh.SetIndices(indices);
            mesh.SetDirty(SMesh::VERTEX_INDEX);
            mesh.BuildMesh();
        }
    }

    void addFaces(uint8 block, uint8 face_info, uint32 x, uint32 y, uint32 z)
	{
		switch(face_info)
		{
			case 0:{ break;}
			case 1:{ addFrontFace(block, x, y, z); break;}
			case 2:{ addBackFace(block, x, y, z); break;}
			case 3:{ addFrontFace(block, x, y, z); addBackFace(block, x, y, z); break;}
			case 4:{ addUpFace(block, x, y, z); break;}
			case 5:{ addFrontFace(block, x, y, z); addUpFace(block, x, y, z); break;}
			case 6:{ addBackFace(block, x, y, z); addUpFace(block, x, y, z); break;}
			case 7:{ addFrontFace(block, x, y, z); addBackFace(block, x, y, z); addUpFace(block, x, y, z); break;}
			case 8:{ addDownFace(block, x, y, z); break;}
			case 9:{ addFrontFace(block, x, y, z); addDownFace(block, x, y, z); break;}
			case 10:{ addBackFace(block, x, y, z); addDownFace(block, x, y, z); break;}
			case 11:{ addFrontFace(block, x, y, z); addBackFace(block, x, y, z); addDownFace(block, x, y, z); break;}
			case 12:{ addUpFace(block, x, y, z); addDownFace(block, x, y, z); break;}
			case 13:{ addFrontFace(block, x, y, z); addUpFace(block, x, y, z); addDownFace(block, x, y, z); break;}
			case 14:{ addBackFace(block, x, y, z); addUpFace(block, x, y, z); addDownFace(block, x, y, z); break;}
			case 15:{ addFrontFace(block, x, y, z); addBackFace(block, x, y, z); addUpFace(block, x, y, z); addDownFace(block, x, y, z); break;}
			case 16:{ addRightFace(block, x, y, z); break;}
			case 17:{ addFrontFace(block, x, y, z); addRightFace(block, x, y, z); break;}
			case 18:{ addBackFace(block, x, y, z); addRightFace(block, x, y, z); break;}
			case 19:{ addFrontFace(block, x, y, z); addBackFace(block, x, y, z); addRightFace(block, x, y, z); break;}
			case 20:{ addUpFace(block, x, y, z); addRightFace(block, x, y, z); break;}
			case 21:{ addFrontFace(block, x, y, z); addUpFace(block, x, y, z); addRightFace(block, x, y, z); break;}
			case 22:{ addBackFace(block, x, y, z); addUpFace(block, x, y, z); addRightFace(block, x, y, z); break;}
			case 23:{ addFrontFace(block, x, y, z); addBackFace(block, x, y, z); addUpFace(block, x, y, z); addRightFace(block, x, y, z); break;}
			case 24:{ addDownFace(block, x, y, z); addRightFace(block, x, y, z); break;}
			case 25:{ addFrontFace(block, x, y, z); addDownFace(block, x, y, z); addRightFace(block, x, y, z); break;}
			case 26:{ addBackFace(block, x, y, z); addDownFace(block, x, y, z); addRightFace(block, x, y, z); break;}
			case 27:{ addFrontFace(block, x, y, z); addBackFace(block, x, y, z); addDownFace(block, x, y, z); addRightFace(block, x, y, z); break;}
			case 28:{ addUpFace(block, x, y, z); addDownFace(block, x, y, z); addRightFace(block, x, y, z); break;}
			case 29:{ addFrontFace(block, x, y, z); addUpFace(block, x, y, z); addDownFace(block, x, y, z); addRightFace(block, x, y, z); break;}
			case 30:{ addBackFace(block, x, y, z); addUpFace(block, x, y, z); addDownFace(block, x, y, z); addRightFace(block, x, y, z); break;}
			case 31:{ addFrontFace(block, x, y, z); addBackFace(block, x, y, z); addUpFace(block, x, y, z); addDownFace(block, x, y, z); addRightFace(block, x, y, z); break;}
			case 32:{ addLeftFace(block, x, y, z); break;}
			case 33:{ addFrontFace(block, x, y, z); addLeftFace(block, x, y, z); break;}
			case 34:{ addBackFace(block, x, y, z); addLeftFace(block, x, y, z); break;}
			case 35:{ addFrontFace(block, x, y, z); addBackFace(block, x, y, z); addLeftFace(block, x, y, z); break;}
			case 36:{ addUpFace(block, x, y, z); addLeftFace(block, x, y, z); break;}
			case 37:{ addFrontFace(block, x, y, z); addUpFace(block, x, y, z); addLeftFace(block, x, y, z); break;}
			case 38:{ addBackFace(block, x, y, z); addUpFace(block, x, y, z); addLeftFace(block, x, y, z); break;}
			case 39:{ addFrontFace(block, x, y, z); addBackFace(block, x, y, z); addUpFace(block, x, y, z); addLeftFace(block, x, y, z); break;}
			case 40:{ addDownFace(block, x, y, z); addLeftFace(block, x, y, z); break;}
			case 41:{ addFrontFace(block, x, y, z); addDownFace(block, x, y, z); addLeftFace(block, x, y, z); break;}
			case 42:{ addBackFace(block, x, y, z); addDownFace(block, x, y, z); addLeftFace(block, x, y, z); break;}
			case 43:{ addFrontFace(block, x, y, z); addBackFace(block, x, y, z); addDownFace(block, x, y, z); addLeftFace(block, x, y, z); break;}
			case 44:{ addUpFace(block, x, y, z); addDownFace(block, x, y, z); addLeftFace(block, x, y, z); break;}
			case 45:{ addFrontFace(block, x, y, z); addUpFace(block, x, y, z); addDownFace(block, x, y, z); addLeftFace(block, x, y, z); break;}
			case 46:{ addBackFace(block, x, y, z); addUpFace(block, x, y, z); addDownFace(block, x, y, z); addLeftFace(block, x, y, z); break;}
			case 47:{ addFrontFace(block, x, y, z); addBackFace(block, x, y, z); addUpFace(block, x, y, z); addDownFace(block, x, y, z); addLeftFace(block, x, y, z); break;}
			case 48:{ addRightFace(block, x, y, z); addLeftFace(block, x, y, z); break;}
			case 49:{ addFrontFace(block, x, y, z); addRightFace(block, x, y, z); addLeftFace(block, x, y, z); break;}
			case 50:{ addBackFace(block, x, y, z); addRightFace(block, x, y, z); addLeftFace(block, x, y, z); break;}
			case 51:{ addFrontFace(block, x, y, z); addBackFace(block, x, y, z); addRightFace(block, x, y, z); addLeftFace(block, x, y, z); break;}
			case 52:{ addUpFace(block, x, y, z); addRightFace(block, x, y, z); addLeftFace(block, x, y, z); break;}
			case 53:{ addFrontFace(block, x, y, z); addUpFace(block, x, y, z); addRightFace(block, x, y, z); addLeftFace(block, x, y, z); break;}
			case 54:{ addBackFace(block, x, y, z); addUpFace(block, x, y, z); addRightFace(block, x, y, z); addLeftFace(block, x, y, z); break;}
			case 55:{ addFrontFace(block, x, y, z); addBackFace(block, x, y, z); addUpFace(block, x, y, z); addRightFace(block, x, y, z); addLeftFace(block, x, y, z); break;}
			case 56:{ addDownFace(block, x, y, z); addRightFace(block, x, y, z); addLeftFace(block, x, y, z); break;}
			case 57:{ addFrontFace(block, x, y, z); addDownFace(block, x, y, z); addRightFace(block, x, y, z); addLeftFace(block, x, y, z); break;}
			case 58:{ addBackFace(block, x, y, z); addDownFace(block, x, y, z); addRightFace(block, x, y, z); addLeftFace(block, x, y, z); break;}
			case 59:{ addFrontFace(block, x, y, z); addBackFace(block, x, y, z); addDownFace(block, x, y, z); addRightFace(block, x, y, z); addLeftFace(block, x, y, z); break;}
			case 60:{ addUpFace(block, x, y, z); addDownFace(block, x, y, z); addRightFace(block, x, y, z); addLeftFace(block, x, y, z); break;}
			case 61:{ addFrontFace(block, x, y, z); addUpFace(block, x, y, z); addDownFace(block, x, y, z); addRightFace(block, x, y, z); addLeftFace(block, x, y, z); break;}
			case 62:{ addBackFace(block, x, y, z); addUpFace(block, x, y, z); addDownFace(block, x, y, z); addRightFace(block, x, y, z); addLeftFace(block, x, y, z); break;}
			case 63:{ addFrontFace(block, x, y, z); addBackFace(block, x, y, z); addUpFace(block, x, y, z); addDownFace(block, x, y, z); addRightFace(block, x, y, z); addLeftFace(block, x, y, z); break;}
		}
	}
	
	void addFrontFace(uint8 block, uint32 x, uint32 y, uint32 z)
	{
		float u1 = Block::u_sides_start[block];
        float u2 = Block::u_sides_end[block];
        float v1 = Block::v_sides_start[block];
        float v2 = Block::v_sides_end[block];
        
        verts.push_back(Vertex(x,	y+1,	z,	u1,	v1,	front_scol));
		verts.push_back(Vertex(x+1,	y+1,	z,	u2,	v1,	front_scol));
		verts.push_back(Vertex(x+1,	y,		z,	u2,	v2, front_scol));
		verts.push_back(Vertex(x,	y,		z,	u1,	v2, front_scol));
        addIndices();
	}
	
	void addBackFace(uint8 block, uint32 x, uint32 y, uint32 z)
	{
		float u1 = Block::u_sides_start[block];
        float u2 = Block::u_sides_end[block];
        float v1 = Block::v_sides_start[block];
        float v2 = Block::v_sides_end[block];

        verts.push_back(Vertex(x+1,	y+1,	z+1,    u1,	v1,	back_scol));
		verts.push_back(Vertex(x,	y+1,	z+1,	u2,	v1,	back_scol));
		verts.push_back(Vertex(x,	y,		z+1,	u2,	v2,	back_scol));
		verts.push_back(Vertex(x+1,	y,		z+1,	u1,	v2,	back_scol));
        addIndices();
	}
	
	void addUpFace(uint8 block, uint32 x, uint32 y, uint32 z)
	{
		float u1 = Block::u_top_start[block];
        float u2 = Block::u_top_end[block];
        float v1 = Block::v_top_start[block];
        float v2 = Block::v_top_end[block];
        
        verts.push_back(Vertex(x,	y+1,	z+1,	u1,	v1,	top_scol));
		verts.push_back(Vertex(x+1,	y+1,	z+1,	u2,	v1,	top_scol));
		verts.push_back(Vertex(x+1,	y+1,	z,		u2,	v2,  top_scol));
		verts.push_back(Vertex(x,	y+1,	z,		u1,	v2,  top_scol));
        addIndices();
	}
	
	void addDownFace(uint8 block, uint32 x, uint32 y, uint32 z)
	{
		float u1 = Block::u_bottom_start[block];
        float u2 = Block::u_bottom_end[block];
        float v1 = Block::v_bottom_start[block];
        float v2 = Block::v_bottom_end[block];
        
        verts.push_back(Vertex(x,	y,		z,		u1,	v1, bottom_scol));
		verts.push_back(Vertex(x+1,	y,		z,		u2,	v1, bottom_scol));
		verts.push_back(Vertex(x+1,	y,		z+1,	u2,	v2, bottom_scol));
		verts.push_back(Vertex(x,	y,		z+1,	u1,	v2, bottom_scol));
        addIndices();
	}
	
	void addRightFace(uint8 block, uint32 x, uint32 y, uint32 z)
	{
		float u1 = Block::u_sides_start[block];
        float u2 = Block::u_sides_end[block];
        float v1 = Block::v_sides_start[block];
        float v2 = Block::v_sides_end[block];
        
        verts.push_back(Vertex(x+1,	y+1,	z,		u1,	v1,	right_scol));
		verts.push_back(Vertex(x+1,	y+1,	z+1,	u2,	v1,	right_scol));
		verts.push_back(Vertex(x+1,	y,		z+1,	u2,	v2,	right_scol));
		verts.push_back(Vertex(x+1,	y,		z,		u1,	v2,	right_scol));
        addIndices();
	}
	
	void addLeftFace(uint8 block, uint32 x, uint32 y, uint32 z)
	{
		float u1 = Block::u_sides_start[block];
        float u2 = Block::u_sides_end[block];
        float v1 = Block::v_sides_start[block];
        float v2 = Block::v_sides_end[block];
        
        verts.push_back(Vertex(x,	y+1,	z+1,	u1,	v1,	left_scol));
        verts.push_back(Vertex(x,	y+1,	z,		u2,	v1,	left_scol));
        verts.push_back(Vertex(x,	y,		z,		u2,	v2,	left_scol));
        verts.push_back(Vertex(x,	y,		z+1,	u1,	v2,	left_scol));
        addIndices();
	}

    void addPlantFaces(uint8 block, uint32 x, uint32 y, uint32 z)
	{
		Vec2f rand_offset = Vec2f(_world.noise.Sample(x*60, (z-y)*60)/2.0f-0.25f, _world.noise.Sample(z*60, (y-x)*60)/2.0f-0.25f);

        float u1 = Block::u_sides_start[block];
        float u2 = Block::u_sides_end[block];
        float v1 = Block::v_sides_start[block];
        float v2 = Block::v_sides_end[block];
        
        verts.push_back(Vertex(x+0.84f+rand_offset.x,	y+1,	z+0.84f+rand_offset.y,	u1,	v1,	top_scol));
		verts.push_back(Vertex(x+0.16f+rand_offset.x,	y+1,	z+0.16f+rand_offset.y,	u2,	v1,	top_scol));
		verts.push_back(Vertex(x+0.16f+rand_offset.x,	y,		z+0.16f+rand_offset.y,	u2,	v2,	top_scol));
		verts.push_back(Vertex(x+0.84f+rand_offset.x,	y,		z+0.84f+rand_offset.y,	u1,	v2,	top_scol));
        addIndices();

		verts.push_back(Vertex(x+0.84f+rand_offset.x,	y+1,	z+0.16f+rand_offset.y,	u1,	v1,	top_scol));
		verts.push_back(Vertex(x+0.16f+rand_offset.x,	y+1,	z+0.84f+rand_offset.y,	u2,	v1,	top_scol));
		verts.push_back(Vertex(x+0.16f+rand_offset.x,	y,		z+0.84f+rand_offset.y,	u2,	v2,	top_scol));
		verts.push_back(Vertex(x+0.84f+rand_offset.x,	y,		z+0.16f+rand_offset.y,	u1,	v2,	top_scol));
        addIndices();

		verts.push_back(Vertex(x+0.16f+rand_offset.x,	y+1,	z+0.16f+rand_offset.y,	u1,	v1,	top_scol));
		verts.push_back(Vertex(x+0.84f+rand_offset.x,	y+1,	z+0.84f+rand_offset.y,	u2,	v1,	top_scol));
		verts.push_back(Vertex(x+0.84f+rand_offset.x,	y,		z+0.84f+rand_offset.y,	u2,	v2,	top_scol));
		verts.push_back(Vertex(x+0.16f+rand_offset.x,	y,		z+0.16f+rand_offset.y,	u1,	v2,	top_scol));
        addIndices();

		verts.push_back(Vertex(x+0.16f+rand_offset.x,	y+1,	z+0.84f+rand_offset.y,	u1,	v1, top_scol));
		verts.push_back(Vertex(x+0.84f+rand_offset.x,	y+1,	z+0.16f+rand_offset.y,	u2,	v1,	top_scol));
		verts.push_back(Vertex(x+0.84f+rand_offset.x,	y,		z+0.16f+rand_offset.y,	u2,	v2,	top_scol));
		verts.push_back(Vertex(x+0.16f+rand_offset.x,	y,		z+0.84f+rand_offset.y,	u1,	v2,	top_scol));
        addIndices();
	}

    void addIndices()
    {
        u32 size = verts.size()-1;
        indices.push_back(size-3);
        indices.push_back(size-2);
        indices.push_back(size-1);
        indices.push_back(size-3);
        indices.push_back(size-1);
        indices.push_back(size);
    }

    void Render()
    {
        mesh.RenderMesh();
    }
}

const uint8 debug_alpha =	255;
const uint8 top_col =		255;
const uint8 bottom_col =	150;
const uint8 left_col =		185;
const uint8 right_col =	    185;
const uint8 front_col =	    220;
const uint8 back_col =		220;

const SColor top_scol = SColor(debug_alpha, top_col, top_col, top_col);
const SColor bottom_scol = SColor(debug_alpha, bottom_col, bottom_col, bottom_col);
const SColor left_scol = SColor(debug_alpha, left_col, left_col, left_col);
const SColor right_scol = SColor(debug_alpha, right_col, right_col, right_col);
const SColor front_scol = SColor(debug_alpha, front_col, front_col, front_col);
const SColor back_scol = SColor(debug_alpha, back_col, back_col, back_col);

void client_SetBlock(CPlayer@ player, uint8 block, const Vec3f&in pos) // called from client to server
{
    if(!world.inWorldBounds(pos.x, pos.y, pos.z)) return;
    
    if(!isServer())
    {
        if(Block::solid[block]) world.setBlock(pos.x, pos.y, pos.z, Block::tempsolid);
        CBitStream to_send;
        to_send.write_netid(player.getNetworkID());
        to_send.write_u8(block);
        to_send.write_f32(pos.x);
		to_send.write_f32(pos.y);
		to_send.write_f32(pos.z);
        getRules().SendCommand(getRules().getCommandID("C_ChangeBlock"), to_send, false);
    }
    else
    {
        uint8 old_block = world.getBlock(pos.x, pos.y, pos.z);
        world.setBlock(pos.x, pos.y, pos.z, block);
        world.saveBlock(pos.x, pos.y, pos.z, block);
        world.UpdateBlocksAndChunks(pos.x, pos.y, pos.z);
        world.BlockUpdate(pos.x, pos.y, pos.z, block, old_block);
    }
}

void server_SetBlock(uint8 block, uint32 x, uint32 y, uint32 z) // called from server to clients
{
    if(!world.inWorldBounds(x, y, z)) return;

    uint8 old_block = world.getBlock(x, y, z);
    world.setBlock(x, y, z, block);
    world.BlockUpdate(x, y, z, block, old_block);

    if(!isClient())
    {
        CBitStream to_send;
        to_send.write_u8(block);
        to_send.write_f32(x);
		to_send.write_f32(y);
		to_send.write_f32(z);
        getRules().SendCommand(getRules().getCommandID("S_ChangeBlock"), to_send, true);
    }
    else
    {
        world.UpdateBlocksAndChunks(x, y, z);
    }
}