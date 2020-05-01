
#include "Blocks.as"

const uint32 chunk_width = 16;
const uint32 chunk_depth = 16;
const uint32 chunk_height = 16;

uint32 world_width = 16;
uint32 world_depth = 16;
uint32 world_height = 8;
uint32 world_width_depth = world_width * world_depth;
uint32 world_size = world_width_depth * world_height;

uint32 map_width = world_width * chunk_width;
uint32 map_depth = world_depth * chunk_depth;
uint32 map_height = world_height * chunk_height;
uint32 map_width_depth = map_width * map_depth;
uint32 map_size = map_width_depth * map_height;

float sample_frequency = 0.02f;
float fractal_frequency = 0.02f;
float add_height = 0.16f;
float dirt_start = 0.16f;
float tree_frequency = 0.06f;
float grass_frequency = 0.08f;

class World
{
    // y z x
    uint8[][][] map;
    uint8[][][] faces_bits;
    Chunk@[] chunks;

    Noise@ noise;
    Random@ rand;

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
        for(float y = 0.0f; y < map_height; y += 1.0f)
        {
            float h_diff = y/float(map_height);
            for(float z = 0.0f; z < map_depth; z += 1.0f)
            {
                for(float x = 0.0f; x < map_width; x += 1.0f)
                {
                    bool make_tree = noise.Sample((map_width+x)*tree_frequency, z*tree_frequency) > 0.7;
                    if(make_tree && rand.NextRanged(70) > 2) make_tree = false;

                    bool make_grass = noise.Sample(x*grass_frequency, (map_depth+z)*grass_frequency) > 0.6;
                    if(make_grass && rand.NextRanged(50) > 40) make_grass = false;
                    bool make_flower = rand.NextRanged(24) == 1;
                    bool flower_type = rand.NextRanged(4) >= 2;
                    
                    float h = noise.Sample(x * sample_frequency, z * sample_frequency) * (noise.Fractal(x * fractal_frequency, z * fractal_frequency)/2.0f) + add_height;//+Maths::Pow(y / float(map_height), 1.1024f)-0.5;
                    if(y == 0)
                    {
                        map[y][z][x] = Block::block_bedrock;
                    }
                    else if(h > h_diff)
                    {
                        if(h-h_diff <= dirt_start)
                        {
                            if(h-something > h_diff)
                                map[y][z][x] = Block::block_dirt;
                            else
                            {
                                if(make_tree)
                                {
                                    trees.push_back(Vec3f(x,y+1,z));
                                    map[y][z][x] = Block::block_dirt;
                                }
                                else if(make_grass)
                                {
                                    if(make_flower)
                                    {
                                        if(flower_type)
                                        {
                                            map[y+1][z][x] = Block::block_tulip;
                                        }
                                        else
                                        {
                                            map[y+1][z][x] = Block::block_edelweiss;
                                        }
                                    }
                                    else
                                    {
                                        map[y+1][z][x] = Block::block_grass;
                                    }
                                    map[y][z][x] = Block::block_grass_dirt;
                                }
                                else map[y][z][x] = Block::block_grass_dirt;
                            }
                        }
                        else
                        {
                            if(h-h_diff > dirt_start+0.06)
                            {
                                map[y][z][x] = Block::block_hard_stone;
                            }
                            else
                            {
                                map[y][z][x] = Block::block_stone;
                            }
                        }
                    }
                    getNet().server_KeepConnectionsAlive();
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
    }
    
    void FacesSetUp()
    {
        uint8[][][] _faces_bits(map_height, uint8[][](map_depth, uint8[](map_width, 0)));
        faces_bits = _faces_bits;
        @noise = @Noise(XORRandom(10000000));
    }

    void MakeTree(Vec3f pos)
	{
		uint8 tree_type = Block::block_log;
		if(XORRandom(3) == 0)
			tree_type = Block::block_log_birch;
		if(inWorldBounds(pos.x, pos.y, pos.z))
		{
			SetBlock(pos.x, pos.y, pos.z, tree_type);
			pos.y += 1;
			if(inWorldBounds(pos.x, pos.y, pos.z))
			{
				SetBlock(pos.x, pos.y, pos.z, tree_type);
				pos.y += 1;
				if(inWorldBounds(pos.x, pos.y, pos.z))
				{
					SetBlock(pos.x, pos.y, pos.z, tree_type);
					
					for(int _z = -2; _z <= 2; _z++)
						for(int _x = -2; _x <= 2; _x++)
							if(!(_x == 0 && _z == 0))
								SetBlock(pos.x+_x, pos.y, pos.z+_z, Block::block_leaves);
					
					pos.y += 1;
					if(inWorldBounds(pos.x, pos.y, pos.z))
					{
						SetBlock(pos.x, pos.y, pos.z, tree_type);
						
						for(int _z = -2; _z <= 2; _z++)
							for(int _x = -2; _x <= 2; _x++)
								if(!(_x == 0 && _z == 0))
									SetBlock(pos.x+_x, pos.y, pos.z+_z, Block::block_leaves);
						
						pos.y += 1;
						if(inWorldBounds(pos.x, pos.y, pos.z))
						{
							SetBlock(pos.x, pos.y, pos.z, tree_type);
							
							for(int _z = -1; _z <= 1; _z++)
								for(int _x = -1; _x <= 1; _x++)
									if(!(_x == 0 && _z == 0))
										SetBlock(pos.x+_x, pos.y, pos.z+_z, Block::block_leaves);
							
							pos.y += 1;
							if(inWorldBounds(pos.x, pos.y, pos.z))
							{
								SetBlock(pos.x+1, pos.y, pos.z, Block::block_leaves);
								SetBlock(pos.x-1, pos.y, pos.z, Block::block_leaves);
								SetBlock(pos.x, pos.y, pos.z, Block::block_leaves);
								SetBlock(pos.x, pos.y, pos.z+1, Block::block_leaves);
								SetBlock(pos.x, pos.y, pos.z-1, Block::block_leaves);
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

    void SetBlock(int x, int y, int z, uint8 block_id)
    {
        if(inWorldBounds(x, y, z)) map[y][z][x] = block_id;
    }

    void SetUpChunks()
    {
        chunks.clear();
        for(int i = 0; i < world_size; i++)
        {
            Chunk chunk(this, i);
            chunks.push_back(@chunk);
        }
    }

    void GenerateBlockFaces(uint32 _gf_packet)
    {
        uint32 start = _gf_packet*gf_packet_size;
        uint32 end = start+gf_packet_size;
        Vec3f pos;
        uint8 block_id;

        for(uint32 i = start; i < end; i++)
        {
            pos = getPosFromWorldIndex(i);
            UpdateBlockFaces(pos.x, pos.y, pos.z);
            getNet().server_KeepConnectionsAlive();
        }
    }

    void UpdateBlockFaces(int x, int y, int z)
    {
        if(map[y][z][x] == Block::block_air || Block::plant[map[y][z][x]])
        {
            faces_bits[y][z][x] = 64;
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

    void Serialize(CBitStream@ to_send, uint32 packet)
    {
        uint32 start = packet*ms_packet_size;
        uint32 end = start+ms_packet_size;
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

    void UnSerialize(uint32 packet)
    {
        uint32 start = packet*ms_packet_size;
        uint32 end = start+ms_packet_size;
        Vec3f pos;
        uint8 block_id;

        uint32 index = 0;

        while(index < ms_packet_size)
        {
            uint32 amount = map_packet.read_u32();
            uint8 block_id = map_packet.read_u8();
            for(uint32 j = 0; j < amount; j++)
            {
                if(index == ms_packet_size)
                {
                    return;
                }
                pos = getPosFromWorldIndex(start+index);
                map[pos.y][pos.z][pos.x] = block_id;
                index++;
            }
        }
    }

    // old and slow way of map sending

    /*void Serialize(CBitStream@ to_send, uint32 packet)
    {
        uint32 start = packet*ms_packet_size;
        uint32 end = start+ms_packet_size;
        Vec3f pos;
        uint8 block_id;

        for(uint32 i = start; i < end; i++)
        {
            pos = getPosFromWorldIndex(i);
            block_id = map[pos.y][pos.z][pos.x];

            to_send.write_u8(block_id);
            getNet().server_KeepConnectionsAlive();
        }
    }

    void UnSerialize(uint32 packet)
    {
        uint32 start = packet*ms_packet_size;
        uint32 end = start+ms_packet_size;
        Vec3f pos;
        uint8 block_id;

        // skip 16 uint8's
        //map_packet.SetBitIndex(16*8*2);

        for(uint32 i = start; i < end; i++)
        {
            block_id = map_packet.read_uint8();
            pos = getPosFromWorldIndex(i);
            map[pos.y][pos.z][pos.x] = block_id;

            getNet().server_KeepConnectionsAlive();
        }
    }*/

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
    Vertex[] verts;
    AABB box;

    Chunk(){}

    Chunk(World@ reference, int _index)
    {
        @_world = @reference;
        index = _index;
        x = _index % world_width; z = (_index / world_width) % world_depth; y = _index / world_width_depth;
        world_x = x*chunk_width; world_z = z*chunk_depth; world_y = y*chunk_height;
        world_x_bounds = world_x+chunk_width; world_z_bounds = world_z+chunk_depth; world_y_bounds = world_y+chunk_height;
        box = AABB(Vec3f(world_x, world_y, world_z), Vec3f(world_x_bounds, world_y_bounds, world_z_bounds));
        visible = false;
        rebuild = true;

        for (int _y = world_y; _y < world_y_bounds; _y++)
		{
			for (int _z = world_z; _z < world_z_bounds; _z++)
			{
				for (int _x = world_x; _x < world_x_bounds; _x++)
				{
                    //int index = _world.getIndex(_x, _y, _z);
                    //Vec3f(x,y,z).Print();
                    if(_world.faces_bits[_y][_z][_x] > 0)
                    {
                        empty = false;
                        return;
                    }
                }
            }
        }
        empty = true;
    }

    void GenerateMesh()
    {
        rebuild = false;
        verts.clear();

        for (int _y = world_y; _y < world_y_bounds; _y++)
		{
			for (int _z = world_z; _z < world_z_bounds; _z++)
			{
				for (int _x = world_x; _x < world_x_bounds; _x++)
				{
                    //int index = _world.getIndex(_x, _y, _z);

                    uint8 block = _world.map[_y][_z][_x];

                    if(block == Block::block_air) continue;

                    int faces = _world.faces_bits[_y][_z][_x];

                    if(faces == 0) continue;

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
        }
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

		verts.push_back(Vertex(pos.x+0.84f+rand_offset.x,	pos.y+1,	pos.z+0.16f+rand_offset.y,	u1,	v1,	top_scol));
		verts.push_back(Vertex(pos.x+0.16f+rand_offset.x,	pos.y+1,	pos.z+0.84f+rand_offset.y,	u2,	v1,	top_scol));
		verts.push_back(Vertex(pos.x+0.16f+rand_offset.x,	pos.y,		pos.z+0.84f+rand_offset.y,	u2,	v2,	top_scol));
		verts.push_back(Vertex(pos.x+0.84f+rand_offset.x,	pos.y,		pos.z+0.16f+rand_offset.y,	u1,	v2,	top_scol));

		verts.push_back(Vertex(pos.x+0.16f+rand_offset.x,	pos.y+1,	pos.z+0.16f+rand_offset.y,	u1,	v1,	top_scol));
		verts.push_back(Vertex(pos.x+0.84f+rand_offset.x,	pos.y+1,	pos.z+0.84f+rand_offset.y,	u2,	v1,	top_scol));
		verts.push_back(Vertex(pos.x+0.84f+rand_offset.x,	pos.y,		pos.z+0.84f+rand_offset.y,	u2,	v2,	top_scol));
		verts.push_back(Vertex(pos.x+0.16f+rand_offset.x,	pos.y,		pos.z+0.16f+rand_offset.y,	u1,	v2,	top_scol));

		verts.push_back(Vertex(pos.x+0.16f+rand_offset.x,	pos.y+1,	pos.z+0.84f+rand_offset.y,	u1,	v1, top_scol));
		verts.push_back(Vertex(pos.x+0.84f+rand_offset.x,	pos.y+1,	pos.z+0.16f+rand_offset.y,	u2,	v1,	top_scol));
		verts.push_back(Vertex(pos.x+0.84f+rand_offset.x,	pos.y,		pos.z+0.16f+rand_offset.y,	u2,	v2,	top_scol));
		verts.push_back(Vertex(pos.x+0.16f+rand_offset.x,	pos.y,		pos.z+0.84f+rand_offset.y,	u1,	v2,	top_scol));
	}

    void Render()
    {
        Render::RawQuads("Block_Textures", verts);
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

void server_SetBlock(uint8 block, const Vec3f&in pos)
{
    if(!world.inWorldBounds(pos.x, pos.y, pos.z)) return;
    
    if(!isServer())
    {
        CBitStream to_send;
        to_send.write_u8(block);
        to_send.write_f32(pos.x);
		to_send.write_f32(pos.y);
		to_send.write_f32(pos.z);
        getRules().SendCommand(getRules().getCommandID("C_ChangeBlock"), to_send, true);
        //return;
    }
    
    world.map[pos.y][pos.z][pos.x] = block;
    world.UpdateBlocksAndChunks(pos.x, pos.y, pos.z);
}

// map sending and receiving

uint32 ms_packet_size = chunk_width*chunk_depth*chunk_height*16; // 16 chunks per packet
uint32 amount_of_packets = map_size / ms_packet_size;

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

CBitStream map_packet;
uint32 got_packets;
bool ready_unser;

uint32 gf_amount_of_packets = amount_of_packets;
uint32 gf_packet_size = map_size / gf_amount_of_packets;
uint32 gf_packet;