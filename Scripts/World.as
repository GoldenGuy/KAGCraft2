
#include "Blocks.as"
//#include "Particles3D.as"

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

float initial_plane = 0.0017;
float initial_plane_max_height = 0.35f;
float initial_plane_add_max = 0.16f;
float hills_spread = 0.048f;

float tree_frequency = 0.06f;
float grass_frequency = 0.08f;

// map sending and receiving

uint32 map_packet_size = chunk_width*chunk_depth*chunk_height*8; // 16 chunks per packet
uint32 map_packets_amount = map_size / map_packet_size;

// server

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

// client

CBitStream@[] map_packets;
uint32 current_map_packet;

uint32 block_faces_packets_amount = map_packets_amount;
uint32 block_faces_packet_size = map_size / block_faces_packets_amount;
uint32 current_block_faces_packet;

uint32 chunks_packets_amount = world_depth*world_height;
uint32 chunks_packet_size = world_size / chunks_packets_amount;
uint32 current_chunks_packet;

class World
{
    // y z x
    uint8[][][] map;
    uint8[][][] faces_bits;
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

    void GenerateMap()
    {
        Debug("Generating map.");
        map.clear();
        Debug("map_size: "+map_size, 2);

        uint32 seed = (114748346*Time_Local()+Time_Local()) % 500000;

        Debug("map seed: "+seed, 2);

        @noise = @Noise(seed);
        @rand = @Random(seed);
        
        float something = 1.0f/map_height;
    
        Vec3f[] trees;
        trees.clear();
        
        uint8[][][] _map(map_height, uint8[][](map_depth, uint8[](map_width, 0)));
        map = _map;
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
                                        continue;
                                    }
                                    else if(make_grass)
                                    {
                                        if(make_flower)
                                        {
                                            if(flower_type)
                                            {
                                                setBlock(x, y+1, z, Block::tulip);
                                            }
                                            else
                                            {
                                                setBlock(x, y+1, z, Block::edelweiss);
                                            }
                                        }
                                        else
                                        {
                                            setBlock(x, y+1, z, Block::grass);
                                        }
                                    }
                                    setBlock(x, y, z, Block::grass_dirt);
                                }
                                continue;
                            }
                            else
                            {
                                setBlock(x, y, z, Block::dirt);
                                continue;
                            }
                        }
                    }
                }
            }
        }
        
        Debug("Making trees...", 2);
        for(int i = 0; i < trees.size(); i++)
        {
            MakeTree(trees[i]);
        }
        Debug("Map generated.");
    }

    void ClientMapSetUp()
    {
        uint8[][][] _map(map_height, uint8[][](map_depth, uint8[](map_width, 0)));
        map = _map;

        uint8[][][] _faces_bits(map_height, uint8[][](map_depth, uint8[](map_width, 0)));
        faces_bits = _faces_bits;

        @noise = @Noise(XORRandom(10000000));

        chunks.clear();
    }

    void FacesSetUp()
    {
        uint8[][][] _faces_bits(map_height, uint8[][](map_depth, uint8[](map_width, 0)));
        faces_bits = _faces_bits;
    }

    void SetUpMaterial()
    {
        //SMaterial@ _mapMaterial = SMaterial();
        //@mapMaterial = @_mapMaterial;
        map_material.AddTexture("Block_Textures", 0);
        //mapMaterial.AddTexture("detail_map", 1);
        //mapMaterial.AddTexture("nm", 1);
        map_material.DisableAllFlags();
        map_material.SetFlag(SMaterial::COLOR_MASK, true);
        map_material.SetFlag(SMaterial::ZBUFFER, true);
        map_material.SetFlag(SMaterial::ZWRITE_ENABLE, true);
        map_material.SetFlag(SMaterial::BACK_FACE_CULLING, true);
        map_material.SetMaterialType(SMaterial::TRANSPARENT_ALPHA_CHANNEL_REF); //TRANSPARENT_ALPHA_CHANNEL_REF
        map_material.SetFlag(SMaterial::FOG_ENABLE, true);

        //mapMaterial.SetFlag(SMaterial::GOURAUD_SHADING, true);

        //mapMaterial.SetFlag(SMaterial::LIGHTING, true);

        //mapMaterial.SetLayerAnisotropicFilter(0, 0);
        //mapMaterial.SetFlag(SMaterial::ANISOTROPIC_FILTER, true);
        //mapMaterial.SetLayerLODBias(0, 1);
        //mapMaterial.SetFlag(SMaterial::USE_MIP_MAPS, true);
        //mapMaterial.RegenMipMap(0);

        //mapMaterial.SetFlag(SMaterial::ANTI_ALIASING, true);
        //mapMaterial.SetAntiAliasing(AntiAliasing::OFF);
    }

    void MakeTree(Vec3f pos)
	{
		uint8 tree_type = Block::log;
		if(XORRandom(3) == 0)
			tree_type = Block::log_birch;
		if(inWorldBounds(pos.x, pos.y, pos.z))
		{
			setBlockSafe(pos.x, pos.y, pos.z, tree_type);
			pos.y += 1;
			if(inWorldBounds(pos.x, pos.y, pos.z))
			{
				setBlockSafe(pos.x, pos.y, pos.z, tree_type);
				pos.y += 1;
				if(inWorldBounds(pos.x, pos.y, pos.z))
				{
					setBlockSafe(pos.x, pos.y, pos.z, tree_type);
					
					for(int _z = -2; _z <= 2; _z++)
						for(int _x = -2; _x <= 2; _x++)
							if(!(_x == 0 && _z == 0))
								setBlockSafe(pos.x+_x, pos.y, pos.z+_z, Block::leaves);
					
					pos.y += 1;
					if(inWorldBounds(pos.x, pos.y, pos.z))
					{
						setBlockSafe(pos.x, pos.y, pos.z, tree_type);
						
						for(int _z = -2; _z <= 2; _z++)
							for(int _x = -2; _x <= 2; _x++)
								if(!(_x == 0 && _z == 0))
									setBlockSafe(pos.x+_x, pos.y, pos.z+_z, Block::leaves);
						
						pos.y += 1;
						if(inWorldBounds(pos.x, pos.y, pos.z))
						{
							setBlockSafe(pos.x, pos.y, pos.z, tree_type);
							
							for(int _z = -1; _z <= 1; _z++)
								for(int _x = -1; _x <= 1; _x++)
									if(!(_x == 0 && _z == 0))
										setBlockSafe(pos.x+_x, pos.y, pos.z+_z, Block::leaves);
							
							pos.y += 1;
							if(inWorldBounds(pos.x, pos.y, pos.z))
							{
								setBlockSafe(pos.x+1, pos.y, pos.z, Block::leaves);
								setBlockSafe(pos.x-1, pos.y, pos.z, Block::leaves);
								setBlockSafe(pos.x, pos.y, pos.z, Block::leaves);
								setBlockSafe(pos.x, pos.y, pos.z+1, Block::leaves);
								setBlockSafe(pos.x, pos.y, pos.z-1, Block::leaves);
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

    void BlockUpdate(int x, int y, int z, uint8 new_block, uint8 old_block)
    {
        if(isClient())
        {
            if(!Block::solid[new_block] && !Block::plant[new_block])
            {
                if(Block::plant[old_block])
                {
                    PlaySound3D("cut_grass2.ogg", x, y, z);
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
                    }
                }
            }
        }
    }

    void setBlockSafe(int x, int y, int z, uint8 block_id)
    {
        if(inWorldBounds(x, y, z)) map[y][z][x] = block_id;
    }

    void setBlock(int x, int y, int z, uint8 block_id)
    {
        map[y][z][x] = block_id;
    }

    uint8 getBlock(int x, int y, int z)
    {
        return map[y][z][x];
    }

    uint8 getBlockSafe(int x, int y, int z)
    {
        if(inWorldBounds(x, y, z)) return map[y][z][x];
        return 255;
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
            SetBlockFaces(getBlock(pos.x, pos.y, pos.z), pos.x, pos.y, pos.z);
            getNet().server_KeepConnectionsAlive();
        }
    }

    void SetBlockFaces(uint8 block, int x, int y, int z)
    {
        if(Block::see_through[block])
        {
            if(z > 0) faces_bits[y][z-1][x] += 2;
            if(z < map_depth-1) faces_bits[y][z+1][x] += 1;
            if(y < map_height-1) faces_bits[y+1][z][x] += 8;
            if(y > 0) faces_bits[y-1][z][x] += 4;
            if(x < map_width-1) faces_bits[y][z][x+1] += 32;
            if(x > 0) faces_bits[y][z][x-1] += 16;
        }
    }

    void UpdateBlockFaces(int x, int y, int z)
    {
        if(map[y][z][x] == Block::air)// || Block::plant[map[y][z][x]])
        {
            faces_bits[y][z][x] = 0;
            return;
        }
        
        uint8 faces = 0;

        if(z > 0 && Block::see_through[map[y][z-1][x]]) faces += 1;
        if(z < map_depth-1 && Block::see_through[map[y][z+1][x]]) faces += 2;
        if(y < map_height-1 && Block::see_through[map[y+1][z][x]]) faces += 4;
        if(y > 0 && Block::see_through[map[y-1][z][x]]) faces += 8;
        if(x < map_width-1 && Block::see_through[map[y][z][x+1]]) faces += 16;
        if(x > 0 && Block::see_through[map[y][z][x-1]]) faces += 32;

        faces_bits[y][z][x] = faces;
    }

    int getIndex(int x, int y, int z)
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
            block_id = map[pos.y][pos.z][pos.x];
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
                pos = getPosFromWorldIndex(start+index);
                map[pos.y][pos.z][pos.x] = block_id;
                SetBlockFaces(block_id, pos.x, pos.y, pos.z);
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
    
    bool inChunkBounds(int x, int y, int z)
    {
        if(x<0 || y<0 || z<0 || x>=world_width || y>=world_height || z>=world_depth) return false;
        return true;
    }

    void clearVisibility()
    {
        for(int i = 0; i < world_size; i++)
        {
            chunks[i].visible = false;
        }
    }

    bool isTileSolid(int x, int y, int z)
    {
        if(!inWorldBounds(x, y, z)) return false;
        return Block::solid[map[y][z][x]];
    }

    bool isTileSolidOrOOB(int x, int y, int z)
    {
        if(!inWorldBounds(x, y, z)) return true;
        return Block::solid[map[y][z][x]];
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
    int x, y, z, world_x, world_y, world_z, world_x_bounds, world_y_bounds, world_z_bounds;
    int index, world_index;
    bool visible, rebuild, empty;
    SMesh mesh;
    Vertex[] verts;
    uint16[] indices;
    AABB box;

    Chunk(){}

    Chunk(World@ reference, int _index)
    {
        @_world = @reference;
        mesh.Clear();
        mesh.SetHardwareMapping(SMesh::STATIC);
        //mesh.BuildMesh();
        //mesh.DropMesh();
        //mesh.DropMeshBuffer();
        index = _index;
        x = _index % world_width; z = (_index / world_width) % world_depth; y = _index / world_width_depth;
        world_x = x*chunk_width; world_z = z*chunk_depth; world_y = y*chunk_height;
        world_x_bounds = world_x+chunk_width; world_z_bounds = world_z+chunk_depth; world_y_bounds = world_y+chunk_height;
        box = AABB(Vec3f(world_x, world_y, world_z), Vec3f(world_x_bounds, world_y_bounds, world_z_bounds));

        GenerateMesh();
        
        //visible = false;

        /*for (int _y = world_y; _y < world_y_bounds; _y++)
		{
			for (int _z = world_z; _z < world_z_bounds; _z++)
			{
				for (int _x = world_x; _x < world_x_bounds; _x++)
				{
                    //int index = _world.getIndex(_x, _y, _z);
                    //Vec3f(x,y,z).Print();
                    if(_world.map[_y][_z][_x] == Block::air)
                    {
                        continue;
                    }
                    else if(_world.faces_bits[_y][_z][_x] > 0)
                    {
                        rebuild = true;
                        empty = false;
                        return;
                    }
                }
            }
        }
        rebuild = false;
        empty = true;*/
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
                    //int index = _world.getIndex(_x, _y, _z);

                    int faces = _world.faces_bits[_y][_z][_x];

                    if(faces == 0) continue;

                    uint8 block = _world.map[_y][_z][_x];

                    if(block == Block::air) continue;

                    //Block@ b = Blocks[block];
                    if(Block::plant[block])
                    {
                        addPlantFaces(block, Vec3f(_x,_y,_z));
                    }
                    else
                    {
                        addFaces(block, faces, Vec3f(_x,_y,_z));
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
        //AddSector(AABB(Vec3f(world_x, world_y, world_z), Vec3f(world_x_bounds, world_y_bounds, world_z_bounds)), 0x50A8360D, 20);
    }

    void SetVisible()
    {
        visible = true;
    }

    void addFaces(uint8 block, uint8 face_info, const Vec3f&in pos)
	{
		switch(face_info)
		{
			case 0:{ break;}
			case 1:{ addFrontFace(block, pos); break;}
			case 2:{ addBackFace(block, pos); break;}
			case 3:{ addFrontFace(block, pos); addBackFace(block, pos); break;}
			case 4:{ addUpFace(block, pos); break;}
			case 5:{ addFrontFace(block, pos); addUpFace(block, pos); break;}
			case 6:{ addBackFace(block, pos); addUpFace(block, pos); break;}
			case 7:{ addFrontFace(block, pos); addBackFace(block, pos); addUpFace(block, pos); break;}
			case 8:{ addDownFace(block, pos); break;}
			case 9:{ addFrontFace(block, pos); addDownFace(block, pos); break;}
			case 10:{ addBackFace(block, pos); addDownFace(block, pos); break;}
			case 11:{ addFrontFace(block, pos); addBackFace(block, pos); addDownFace(block, pos); break;}
			case 12:{ addUpFace(block, pos); addDownFace(block, pos); break;}
			case 13:{ addFrontFace(block, pos); addUpFace(block, pos); addDownFace(block, pos); break;}
			case 14:{ addBackFace(block, pos); addUpFace(block, pos); addDownFace(block, pos); break;}
			case 15:{ addFrontFace(block, pos); addBackFace(block, pos); addUpFace(block, pos); addDownFace(block, pos); break;}
			case 16:{ addRightFace(block, pos); break;}
			case 17:{ addFrontFace(block, pos); addRightFace(block, pos); break;}
			case 18:{ addBackFace(block, pos); addRightFace(block, pos); break;}
			case 19:{ addFrontFace(block, pos); addBackFace(block, pos); addRightFace(block, pos); break;}
			case 20:{ addUpFace(block, pos); addRightFace(block, pos); break;}
			case 21:{ addFrontFace(block, pos); addUpFace(block, pos); addRightFace(block, pos); break;}
			case 22:{ addBackFace(block, pos); addUpFace(block, pos); addRightFace(block, pos); break;}
			case 23:{ addFrontFace(block, pos); addBackFace(block, pos); addUpFace(block, pos); addRightFace(block, pos); break;}
			case 24:{ addDownFace(block, pos); addRightFace(block, pos); break;}
			case 25:{ addFrontFace(block, pos); addDownFace(block, pos); addRightFace(block, pos); break;}
			case 26:{ addBackFace(block, pos); addDownFace(block, pos); addRightFace(block, pos); break;}
			case 27:{ addFrontFace(block, pos); addBackFace(block, pos); addDownFace(block, pos); addRightFace(block, pos); break;}
			case 28:{ addUpFace(block, pos); addDownFace(block, pos); addRightFace(block, pos); break;}
			case 29:{ addFrontFace(block, pos); addUpFace(block, pos); addDownFace(block, pos); addRightFace(block, pos); break;}
			case 30:{ addBackFace(block, pos); addUpFace(block, pos); addDownFace(block, pos); addRightFace(block, pos); break;}
			case 31:{ addFrontFace(block, pos); addBackFace(block, pos); addUpFace(block, pos); addDownFace(block, pos); addRightFace(block, pos); break;}
			case 32:{ addLeftFace(block, pos); break;}
			case 33:{ addFrontFace(block, pos); addLeftFace(block, pos); break;}
			case 34:{ addBackFace(block, pos); addLeftFace(block, pos); break;}
			case 35:{ addFrontFace(block, pos); addBackFace(block, pos); addLeftFace(block, pos); break;}
			case 36:{ addUpFace(block, pos); addLeftFace(block, pos); break;}
			case 37:{ addFrontFace(block, pos); addUpFace(block, pos); addLeftFace(block, pos); break;}
			case 38:{ addBackFace(block, pos); addUpFace(block, pos); addLeftFace(block, pos); break;}
			case 39:{ addFrontFace(block, pos); addBackFace(block, pos); addUpFace(block, pos); addLeftFace(block, pos); break;}
			case 40:{ addDownFace(block, pos); addLeftFace(block, pos); break;}
			case 41:{ addFrontFace(block, pos); addDownFace(block, pos); addLeftFace(block, pos); break;}
			case 42:{ addBackFace(block, pos); addDownFace(block, pos); addLeftFace(block, pos); break;}
			case 43:{ addFrontFace(block, pos); addBackFace(block, pos); addDownFace(block, pos); addLeftFace(block, pos); break;}
			case 44:{ addUpFace(block, pos); addDownFace(block, pos); addLeftFace(block, pos); break;}
			case 45:{ addFrontFace(block, pos); addUpFace(block, pos); addDownFace(block, pos); addLeftFace(block, pos); break;}
			case 46:{ addBackFace(block, pos); addUpFace(block, pos); addDownFace(block, pos); addLeftFace(block, pos); break;}
			case 47:{ addFrontFace(block, pos); addBackFace(block, pos); addUpFace(block, pos); addDownFace(block, pos); addLeftFace(block, pos); break;}
			case 48:{ addRightFace(block, pos); addLeftFace(block, pos); break;}
			case 49:{ addFrontFace(block, pos); addRightFace(block, pos); addLeftFace(block, pos); break;}
			case 50:{ addBackFace(block, pos); addRightFace(block, pos); addLeftFace(block, pos); break;}
			case 51:{ addFrontFace(block, pos); addBackFace(block, pos); addRightFace(block, pos); addLeftFace(block, pos); break;}
			case 52:{ addUpFace(block, pos); addRightFace(block, pos); addLeftFace(block, pos); break;}
			case 53:{ addFrontFace(block, pos); addUpFace(block, pos); addRightFace(block, pos); addLeftFace(block, pos); break;}
			case 54:{ addBackFace(block, pos); addUpFace(block, pos); addRightFace(block, pos); addLeftFace(block, pos); break;}
			case 55:{ addFrontFace(block, pos); addBackFace(block, pos); addUpFace(block, pos); addRightFace(block, pos); addLeftFace(block, pos); break;}
			case 56:{ addDownFace(block, pos); addRightFace(block, pos); addLeftFace(block, pos); break;}
			case 57:{ addFrontFace(block, pos); addDownFace(block, pos); addRightFace(block, pos); addLeftFace(block, pos); break;}
			case 58:{ addBackFace(block, pos); addDownFace(block, pos); addRightFace(block, pos); addLeftFace(block, pos); break;}
			case 59:{ addFrontFace(block, pos); addBackFace(block, pos); addDownFace(block, pos); addRightFace(block, pos); addLeftFace(block, pos); break;}
			case 60:{ addUpFace(block, pos); addDownFace(block, pos); addRightFace(block, pos); addLeftFace(block, pos); break;}
			case 61:{ addFrontFace(block, pos); addUpFace(block, pos); addDownFace(block, pos); addRightFace(block, pos); addLeftFace(block, pos); break;}
			case 62:{ addBackFace(block, pos); addUpFace(block, pos); addDownFace(block, pos); addRightFace(block, pos); addLeftFace(block, pos); break;}
			case 63:{ addFrontFace(block, pos); addBackFace(block, pos); addUpFace(block, pos); addDownFace(block, pos); addRightFace(block, pos); addLeftFace(block, pos); break;}
		}
	}
	
	void addFrontFace(uint8 block, const Vec3f&in pos)
	{
		float u1 = Block::u_sides_start[block];
        float u2 = Block::u_sides_end[block];
        float v1 = Block::v_sides_start[block];
        float v2 = Block::v_sides_end[block];
        
        verts.push_back(Vertex(pos.x,	pos.y+1,	pos.z,	u1,	v1,	front_scol));
		verts.push_back(Vertex(pos.x+1,	pos.y+1,	pos.z,	u2,	v1,	front_scol));
		verts.push_back(Vertex(pos.x+1,	pos.y,		pos.z,	u2,	v2, front_scol));
		verts.push_back(Vertex(pos.x,	pos.y,		pos.z,	u1,	v2, front_scol));
        addIndices();
	}
	
	void addBackFace(uint8 block, const Vec3f&in pos)
	{
		float u1 = Block::u_sides_start[block];
        float u2 = Block::u_sides_end[block];
        float v1 = Block::v_sides_start[block];
        float v2 = Block::v_sides_end[block];

        verts.push_back(Vertex(pos.x+1,	pos.y+1,	pos.z+1,    u1,	v1,	back_scol));
		verts.push_back(Vertex(pos.x,	pos.y+1,	pos.z+1,	u2,	v1,	back_scol));
		verts.push_back(Vertex(pos.x,	pos.y,		pos.z+1,	u2,	v2,	back_scol));
		verts.push_back(Vertex(pos.x+1,	pos.y,		pos.z+1,	u1,	v2,	back_scol));
        addIndices();
	}
	
	void addUpFace(uint8 block, const Vec3f&in pos)
	{
		float u1 = Block::u_top_start[block];
        float u2 = Block::u_top_end[block];
        float v1 = Block::v_top_start[block];
        float v2 = Block::v_top_end[block];
        
        verts.push_back(Vertex(pos.x,	pos.y+1,	pos.z+1,	u1,	v1,	top_scol));
		verts.push_back(Vertex(pos.x+1,	pos.y+1,	pos.z+1,	u2,	v1,	top_scol));
		verts.push_back(Vertex(pos.x+1,	pos.y+1,	pos.z,		u2,	v2,  top_scol));
		verts.push_back(Vertex(pos.x,	pos.y+1,	pos.z,		u1,	v2,  top_scol));
        addIndices();
	}
	
	void addDownFace(uint8 block, const Vec3f&in pos)
	{
		float u1 = Block::u_bottom_start[block];
        float u2 = Block::u_bottom_end[block];
        float v1 = Block::v_bottom_start[block];
        float v2 = Block::v_bottom_end[block];
        
        verts.push_back(Vertex(pos.x,	pos.y,		pos.z,		u1,	v1, bottom_scol));
		verts.push_back(Vertex(pos.x+1,	pos.y,		pos.z,		u2,	v1, bottom_scol));
		verts.push_back(Vertex(pos.x+1,	pos.y,		pos.z+1,	u2,	v2, bottom_scol));
		verts.push_back(Vertex(pos.x,	pos.y,		pos.z+1,	u1,	v2, bottom_scol));
        addIndices();
	}
	
	void addRightFace(uint8 block, const Vec3f&in pos)
	{
		float u1 = Block::u_sides_start[block];
        float u2 = Block::u_sides_end[block];
        float v1 = Block::v_sides_start[block];
        float v2 = Block::v_sides_end[block];
        
        verts.push_back(Vertex(pos.x+1,	pos.y+1,	pos.z,		u1,	v1,	right_scol));
		verts.push_back(Vertex(pos.x+1,	pos.y+1,	pos.z+1,	u2,	v1,	right_scol));
		verts.push_back(Vertex(pos.x+1,	pos.y,		pos.z+1,	u2,	v2,	right_scol));
		verts.push_back(Vertex(pos.x+1,	pos.y,		pos.z,		u1,	v2,	right_scol));
        addIndices();
	}
	
	void addLeftFace(uint8 block, const Vec3f&in pos)
	{
		float u1 = Block::u_sides_start[block];
        float u2 = Block::u_sides_end[block];
        float v1 = Block::v_sides_start[block];
        float v2 = Block::v_sides_end[block];
        
        verts.push_back(Vertex(pos.x,	pos.y+1,	pos.z+1,	u1,	v1,	left_scol));
        verts.push_back(Vertex(pos.x,	pos.y+1,	pos.z,		u2,	v1,	left_scol));
        verts.push_back(Vertex(pos.x,	pos.y,		pos.z,		u2,	v2,	left_scol));
        verts.push_back(Vertex(pos.x,	pos.y,		pos.z+1,	u1,	v2,	left_scol));
        addIndices();
	}

    void addPlantFaces(uint8 block, const Vec3f&in pos)
	{
		Vec2f rand_offset = Vec2f(_world.noise.Sample(pos.x*60, (pos.z-pos.y)*60)/2.0f-0.25f, _world.noise.Sample(pos.z*60, (pos.y-pos.x)*60)/2.0f-0.25f);

        float u1 = Block::u_sides_start[block];
        float u2 = Block::u_sides_end[block];
        float v1 = Block::v_sides_start[block];
        float v2 = Block::v_sides_end[block];
        
        verts.push_back(Vertex(pos.x+0.84f+rand_offset.x,	pos.y+1,	pos.z+0.84f+rand_offset.y,	u1,	v1,	top_scol));
		verts.push_back(Vertex(pos.x+0.16f+rand_offset.x,	pos.y+1,	pos.z+0.16f+rand_offset.y,	u2,	v1,	top_scol));
		verts.push_back(Vertex(pos.x+0.16f+rand_offset.x,	pos.y,		pos.z+0.16f+rand_offset.y,	u2,	v2,	top_scol));
		verts.push_back(Vertex(pos.x+0.84f+rand_offset.x,	pos.y,		pos.z+0.84f+rand_offset.y,	u1,	v2,	top_scol));
        addIndices();

		verts.push_back(Vertex(pos.x+0.84f+rand_offset.x,	pos.y+1,	pos.z+0.16f+rand_offset.y,	u1,	v1,	top_scol));
		verts.push_back(Vertex(pos.x+0.16f+rand_offset.x,	pos.y+1,	pos.z+0.84f+rand_offset.y,	u2,	v1,	top_scol));
		verts.push_back(Vertex(pos.x+0.16f+rand_offset.x,	pos.y,		pos.z+0.84f+rand_offset.y,	u2,	v2,	top_scol));
		verts.push_back(Vertex(pos.x+0.84f+rand_offset.x,	pos.y,		pos.z+0.16f+rand_offset.y,	u1,	v2,	top_scol));
        addIndices();

		verts.push_back(Vertex(pos.x+0.16f+rand_offset.x,	pos.y+1,	pos.z+0.16f+rand_offset.y,	u1,	v1,	top_scol));
		verts.push_back(Vertex(pos.x+0.84f+rand_offset.x,	pos.y+1,	pos.z+0.84f+rand_offset.y,	u2,	v1,	top_scol));
		verts.push_back(Vertex(pos.x+0.84f+rand_offset.x,	pos.y,		pos.z+0.84f+rand_offset.y,	u2,	v2,	top_scol));
		verts.push_back(Vertex(pos.x+0.16f+rand_offset.x,	pos.y,		pos.z+0.16f+rand_offset.y,	u1,	v2,	top_scol));
        addIndices();

		verts.push_back(Vertex(pos.x+0.16f+rand_offset.x,	pos.y+1,	pos.z+0.84f+rand_offset.y,	u1,	v1, top_scol));
		verts.push_back(Vertex(pos.x+0.84f+rand_offset.x,	pos.y+1,	pos.z+0.16f+rand_offset.y,	u2,	v1,	top_scol));
		verts.push_back(Vertex(pos.x+0.84f+rand_offset.x,	pos.y,		pos.z+0.16f+rand_offset.y,	u2,	v2,	top_scol));
		verts.push_back(Vertex(pos.x+0.16f+rand_offset.x,	pos.y,		pos.z+0.84f+rand_offset.y,	u1,	v2,	top_scol));
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
        //Render::RawQuads("Block_Textures", verts);
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

void client_SetBlock(CPlayer@ player, uint8 block, const Vec3f&in pos)
{
    if(!world.inWorldBounds(pos.x, pos.y, pos.z)) return;

    //uint8 old_block = world.getBlock(pos.x, pos.y, pos.z);
    //world.setBlock(pos.x, pos.y, pos.z, block);
    //world.UpdateBlocksAndChunks(pos.x, pos.y, pos.z);
    
    if(!isServer())
    {
        CBitStream to_send;
        to_send.write_netid(player.getNetworkID());
        to_send.write_u8(block);
        to_send.write_f32(pos.x);
		to_send.write_f32(pos.y);
		to_send.write_f32(pos.z);
        getRules().SendCommand(getRules().getCommandID("C_ChangeBlock"), to_send, false);
        //return;
    }
    else
    {
        uint8 old_block = world.getBlock(pos.x, pos.y, pos.z);
        world.setBlock(pos.x, pos.y, pos.z, block);
        world.UpdateBlocksAndChunks(pos.x, pos.y, pos.z);
        world.BlockUpdate(pos.x, pos.y, pos.z, block, old_block);
    }
}

void server_SetBlock(uint8 block, int x, int y, int z)
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

void PlaySound3D(string name, int x, int y, int z)
{
    CBitStream to_send;
    to_send.write_string(name);
    to_send.write_f32(x);
    to_send.write_f32(y);
    to_send.write_f32(z);
    getRules().SendCommand(getRules().getCommandID("C_PlaySound3D"), to_send);
}