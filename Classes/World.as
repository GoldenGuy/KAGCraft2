
#include "Blocks.as"

const u32 chunk_width = 10;
const u32 chunk_depth = 10;
const u32 chunk_height = 10;

u32 world_width = 16;
u32 world_depth = 16;
u32 world_height = 8;
u32 world_width_depth = world_width * world_depth;
u32 world_size = world_width_depth * world_height;

u32 map_width = world_width * chunk_width;
u32 map_depth = world_depth * chunk_depth;
u32 map_height = world_height * chunk_height;
u32 map_width_depth = map_width * map_depth;
u32 map_size = map_width_depth * map_height;

float sample_frequency = 0.05f;
float fractal_frequency = 0.02f;
float add_height = 0.2f;
float dirt_start = 0.16f;

class World
{
    u8[] map;
    u8[] faces_bits;
    Chunk@[] chunks;
    bool poop = true;

    void GenerateMap()
    {
        map.clear();
        map.resize(map_size);
        Debug("map_size: "+map_size);


        Noise noise(69);
        Random rand(69);
        
        float something = 1.0f/map_height;
    
        Vec3f[] trees;
        trees.clear();
        
        for(float y = 0.0f; y < map_height; y += 1.0f)
        {
            float h_diff = y/float(map_height);
            for(float z = 0.0f; z < map_depth; z += 1.0f)
            {
                for(float x = 0.0f; x < map_width; x += 1.0f)
                {
                    u32 index = y*map_width_depth + z*map_width + x;

                    u32 tree_rand = rand.NextRanged(200);
                    bool make_tree = tree_rand == 1;
                    
                    u32 grass_rand = rand.NextRanged(8);
                    bool make_grass = grass_rand == 1;
                    
                    u32 flower_rand = rand.NextRanged(20);
                    bool make_flower = flower_rand == 1;
                
                    u32 flower_type_rand = rand.NextRanged(2);
                    bool flower_type = flower_type_rand == 1;
                    
                    float h = noise.Sample(x * sample_frequency, z * sample_frequency) * (noise.Fractal(x * fractal_frequency, z * fractal_frequency)/2) + add_height;//+Maths::Pow(y / float(map_height), 1.1024f)-0.5;
                    if(y == 0)
                    {
                        //set_block(int(x), int(y), int(z), block_bedrock);
                        map[index] = block_bedrock;
                    }
                    else if(h > h_diff)
                    {
                        if(h-h_diff <= dirt_start)
                        {
                            if(h-something > h_diff)
                                map[index] = block_dirt;//set_block(int(x), int(y), int(z), block_dirt);
                            else
                            {
                                map[index] = block_grass_dirt;//set_block(int(x), int(y), int(z), block_grass_dirt);
                                /*if(make_tree)
                                {
                                    trees.push_back(Vec3f(x,y+1,z));
                                    set_block(int(x), int(y), int(z), block_dirt);
                                }
                                else if(make_grass)
                                {
                                    if(make_flower)
                                    {
                                        if(flower_type)
                                        {
                                            set_block(int(x), int(y+1), int(z), block_tulip);
                                        }
                                        else
                                        {
                                            set_block(int(x), int(y+1), int(z), block_tdelweiss);
                                        }
                                    }
                                    else
                                    {
                                        set_block(int(x), int(y+1), int(z), block_grass);
                                    }
                                }*/
                            }
                        }
                        else
                        {
                            if(h-h_diff > dirt_start+0.06)
                            {
                                map[index] = block_hard_stone;//set_block(int(x), int(y), int(z), block_hard_stone);
                            }
                            else
                            {
                                map[index] = block_stone;//set_block(int(x), int(y), int(z), block_stone);
                            }
                        }
                    }
                    getNet().server_KeepConnectionsAlive();
                }
            }
        }
        /*for(int i = 0; i < trees.size(); i++)
        {
            MakeTree(trees[i]);
        }*/


        /*for(int y = 0; y < map_height; y++)
        {
            for(int z = 0; z < map_depth; z++)
            {
                for(int x = 0; x < map_width; x++)
                {
                    int index = y*map_width_depth + z*map_width + x;
                    
                    

                }
            }
        }*/
        Debug("Map generated");
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

    void GenerateBlockFaces()
    {
        faces_bits.clear();
        faces_bits.resize(map_size);

        for(int y = 0; y < map_height; y++)
        {
            for(int z = 0; z < map_depth; z++)
            {
                for(int x = 0; x < map_width; x++)
                {
                    UpdateBlockFaces(x, y, z);
                }
            }
        }
    }

    void UpdateBlockFaces(int x, int y, int z)
    {
        u8 faces = 0;

        if(z > 0 && Blocks[map[getIndex(x, y, z-1)]].see_through) faces += 1;
        if(z < map_depth-1 && Blocks[map[getIndex(x, y, z+1)]].see_through) faces += 2;
        if(y < map_height-1 && Blocks[map[getIndex(x, y+1, z)]].see_through) faces += 4;
        if(y > 0 && Blocks[map[getIndex(x, y-1, z)]].see_through) faces += 8;
        if(x < map_width-1 && Blocks[map[getIndex(x+1, y, z)]].see_through) faces += 16;
        if(x > 0 && Blocks[map[getIndex(x-1, y, z)]].see_through) faces += 32;

        faces_bits[getIndex(x, y, z)] = faces;
    }

    int getIndex(int x, int y, int z)
    {
        int index = y*map_width_depth + z*map_width + x;
        return index;
    }

    void Serialize(CBitStream@ to_send)
    {
        u32 similars = 0;
        u8 similar_block_id = 0;
        u8 block_id = 0;
        u32 index = 0;
        for(u32 i = 0; i < map_size; i++)
        {
            if(i == 0)
            {
                similar_block_id = map[i];
                block_id = similar_block_id;
                similars++;
                continue;
            }
            else
            {
                block_id = map[i];
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
                    index++;
                }
            }
            getNet().server_KeepConnectionsAlive();
        }
    }

    void UnSerialize(CBitStream@ to_read)
    {
        map.clear();
        map.resize(map_size);
        u32 map_index = 0;
        while(!to_read.isBufferEnd())
        {
            u32 amount = to_read.read_u32();
            u8 block_id = to_read.read_u8();
            for(u32 j = 0; j < amount; j++)
            {
                if(map_index >= map_size)
                {
                    Debug("MAP LIMIT: "+map_index+" >= "+map_size, 3);
                    Debug("j: "+j+" amount: "+amount, 3);
                    Debug("block_id: "+block_id, 3);
                    Debug("If map looks like shit tell goldenguy and show him this message.", 3);
                    return;
                }
                map[map_index] = block_id;
                map_index++;
                getNet().server_KeepConnectionsAlive();
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
}

class Chunk
{
    World@ _world;
    int x, y, z, world_x, world_y, world_z, world_x_bounds, world_y_bounds, world_z_bounds;
    int index, world_index;
    bool visible, rebuild, empty;
    Vertex[] mesh;
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
                    int index = _world.getIndex(_x, _y, _z);
                    u8 block = _world.map[index];
                    if(block != 0)
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
        mesh.clear();

        for (int _y = world_y; _y < world_y_bounds; _y++)
		{
			for (int _z = world_z; _z < world_z_bounds; _z++)
			{
				for (int _x = world_x; _x < world_x_bounds; _x++)
				{
                    int index = _world.getIndex(_x, _y, _z);
                    u8 block = _world.map[index];

                    Block@ b = Blocks[block];
                    addFaces(@b, _world.faces_bits[index], Vec3f(_x,_y,_z));
                }
            }
        }
        if(mesh.size() == 0)
        {
            empty = true;
        }
    }

    void SetVisible()
    {
        visible = true;
    }

    void addFaces(Block@ b, u8 face_info, Vec3f pos)
	{
		switch(face_info)
		{
			case 0:{ break;}
			case 1:{ addFrontFace(@b, pos); break;}
			case 2:{ addBackFace(@b, pos); break;}
			case 3:{ addFrontFace(@b, pos); addBackFace(@b, pos); break;}
			case 4:{ addUpFace(@b, pos); break;}
			case 5:{ addFrontFace(@b, pos); addUpFace(@b, pos); break;}
			case 6:{ addBackFace(@b, pos); addUpFace(@b, pos); break;}
			case 7:{ addFrontFace(@b, pos); addBackFace(@b, pos); addUpFace(@b, pos); break;}
			case 8:{ addDownFace(@b, pos); break;}
			case 9:{ addFrontFace(@b, pos); addDownFace(@b, pos); break;}
			case 10:{ addBackFace(@b, pos); addDownFace(@b, pos); break;}
			case 11:{ addFrontFace(@b, pos); addBackFace(@b, pos); addDownFace(@b, pos); break;}
			case 12:{ addUpFace(@b, pos); addDownFace(@b, pos); break;}
			case 13:{ addFrontFace(@b, pos); addUpFace(@b, pos); addDownFace(@b, pos); break;}
			case 14:{ addBackFace(@b, pos); addUpFace(@b, pos); addDownFace(@b, pos); break;}
			case 15:{ addFrontFace(@b, pos); addBackFace(@b, pos); addUpFace(@b, pos); addDownFace(@b, pos); break;}
			case 16:{ addRightFace(@b, pos); break;}
			case 17:{ addFrontFace(@b, pos); addRightFace(@b, pos); break;}
			case 18:{ addBackFace(@b, pos); addRightFace(@b, pos); break;}
			case 19:{ addFrontFace(@b, pos); addBackFace(@b, pos); addRightFace(@b, pos); break;}
			case 20:{ addUpFace(@b, pos); addRightFace(@b, pos); break;}
			case 21:{ addFrontFace(@b, pos); addUpFace(@b, pos); addRightFace(@b, pos); break;}
			case 22:{ addBackFace(@b, pos); addUpFace(@b, pos); addRightFace(@b, pos); break;}
			case 23:{ addFrontFace(@b, pos); addBackFace(@b, pos); addUpFace(@b, pos); addRightFace(@b, pos); break;}
			case 24:{ addDownFace(@b, pos); addRightFace(@b, pos); break;}
			case 25:{ addFrontFace(@b, pos); addDownFace(@b, pos); addRightFace(@b, pos); break;}
			case 26:{ addBackFace(@b, pos); addDownFace(@b, pos); addRightFace(@b, pos); break;}
			case 27:{ addFrontFace(@b, pos); addBackFace(@b, pos); addDownFace(@b, pos); addRightFace(@b, pos); break;}
			case 28:{ addUpFace(@b, pos); addDownFace(@b, pos); addRightFace(@b, pos); break;}
			case 29:{ addFrontFace(@b, pos); addUpFace(@b, pos); addDownFace(@b, pos); addRightFace(@b, pos); break;}
			case 30:{ addBackFace(@b, pos); addUpFace(@b, pos); addDownFace(@b, pos); addRightFace(@b, pos); break;}
			case 31:{ addFrontFace(@b, pos); addBackFace(@b, pos); addUpFace(@b, pos); addDownFace(@b, pos); addRightFace(@b, pos); break;}
			case 32:{ addLeftFace(@b, pos); break;}
			case 33:{ addFrontFace(@b, pos); addLeftFace(@b, pos); break;}
			case 34:{ addBackFace(@b, pos); addLeftFace(@b, pos); break;}
			case 35:{ addFrontFace(@b, pos); addBackFace(@b, pos); addLeftFace(@b, pos); break;}
			case 36:{ addUpFace(@b, pos); addLeftFace(@b, pos); break;}
			case 37:{ addFrontFace(@b, pos); addUpFace(@b, pos); addLeftFace(@b, pos); break;}
			case 38:{ addBackFace(@b, pos); addUpFace(@b, pos); addLeftFace(@b, pos); break;}
			case 39:{ addFrontFace(@b, pos); addBackFace(@b, pos); addUpFace(@b, pos); addLeftFace(@b, pos); break;}
			case 40:{ addDownFace(@b, pos); addLeftFace(@b, pos); break;}
			case 41:{ addFrontFace(@b, pos); addDownFace(@b, pos); addLeftFace(@b, pos); break;}
			case 42:{ addBackFace(@b, pos); addDownFace(@b, pos); addLeftFace(@b, pos); break;}
			case 43:{ addFrontFace(@b, pos); addBackFace(@b, pos); addDownFace(@b, pos); addLeftFace(@b, pos); break;}
			case 44:{ addUpFace(@b, pos); addDownFace(@b, pos); addLeftFace(@b, pos); break;}
			case 45:{ addFrontFace(@b, pos); addUpFace(@b, pos); addDownFace(@b, pos); addLeftFace(@b, pos); break;}
			case 46:{ addBackFace(@b, pos); addUpFace(@b, pos); addDownFace(@b, pos); addLeftFace(@b, pos); break;}
			case 47:{ addFrontFace(@b, pos); addBackFace(@b, pos); addUpFace(@b, pos); addDownFace(@b, pos); addLeftFace(@b, pos); break;}
			case 48:{ addRightFace(@b, pos); addLeftFace(@b, pos); break;}
			case 49:{ addFrontFace(@b, pos); addRightFace(@b, pos); addLeftFace(@b, pos); break;}
			case 50:{ addBackFace(@b, pos); addRightFace(@b, pos); addLeftFace(@b, pos); break;}
			case 51:{ addFrontFace(@b, pos); addBackFace(@b, pos); addRightFace(@b, pos); addLeftFace(@b, pos); break;}
			case 52:{ addUpFace(@b, pos); addRightFace(@b, pos); addLeftFace(@b, pos); break;}
			case 53:{ addFrontFace(@b, pos); addUpFace(@b, pos); addRightFace(@b, pos); addLeftFace(@b, pos); break;}
			case 54:{ addBackFace(@b, pos); addUpFace(@b, pos); addRightFace(@b, pos); addLeftFace(@b, pos); break;}
			case 55:{ addFrontFace(@b, pos); addBackFace(@b, pos); addUpFace(@b, pos); addRightFace(@b, pos); addLeftFace(@b, pos); break;}
			case 56:{ addDownFace(@b, pos); addRightFace(@b, pos); addLeftFace(@b, pos); break;}
			case 57:{ addFrontFace(@b, pos); addDownFace(@b, pos); addRightFace(@b, pos); addLeftFace(@b, pos); break;}
			case 58:{ addBackFace(@b, pos); addDownFace(@b, pos); addRightFace(@b, pos); addLeftFace(@b, pos); break;}
			case 59:{ addFrontFace(@b, pos); addBackFace(@b, pos); addDownFace(@b, pos); addRightFace(@b, pos); addLeftFace(@b, pos); break;}
			case 60:{ addUpFace(@b, pos); addDownFace(@b, pos); addRightFace(@b, pos); addLeftFace(@b, pos); break;}
			case 61:{ addFrontFace(@b, pos); addUpFace(@b, pos); addDownFace(@b, pos); addRightFace(@b, pos); addLeftFace(@b, pos); break;}
			case 62:{ addBackFace(@b, pos); addUpFace(@b, pos); addDownFace(@b, pos); addRightFace(@b, pos); addLeftFace(@b, pos); break;}
			case 63:{ addFrontFace(@b, pos); addBackFace(@b, pos); addUpFace(@b, pos); addDownFace(@b, pos); addRightFace(@b, pos); addLeftFace(@b, pos); break;}
		}
	}
	
	void addFrontFace(Block@ b, Vec3f pos)
	{
		mesh.push_back(Vertex(pos.x,	pos.y+1,	pos.z,	b.sides_start_u,	b.sides_start_v,	front_scol));
		mesh.push_back(Vertex(pos.x+1,	pos.y+1,	pos.z,	b.sides_end_u,	    b.sides_start_v,	front_scol));
		mesh.push_back(Vertex(pos.x+1,	pos.y,		pos.z,	b.sides_end_u,	    b.sides_end_v,	    front_scol));
		mesh.push_back(Vertex(pos.x,	pos.y,		pos.z,	b.sides_start_u,	b.sides_end_v,	    front_scol));
	}
	
	void addBackFace(Block@ b, Vec3f pos)
	{
		mesh.push_back(Vertex(pos.x+1,	pos.y+1,	pos.z+1,	b.sides_start_u,	b.sides_start_v,	back_scol));
		mesh.push_back(Vertex(pos.x,	pos.y+1,	pos.z+1,	b.sides_end_u,	    b.sides_start_v,	back_scol));
		mesh.push_back(Vertex(pos.x,	pos.y,		pos.z+1,	b.sides_end_u,	    b.sides_end_v,		back_scol));
		mesh.push_back(Vertex(pos.x+1,	pos.y,		pos.z+1,	b.sides_start_u,	b.sides_end_v,		back_scol));
	}
	
	void addUpFace(Block@ b, Vec3f pos)
	{
		mesh.push_back(Vertex(pos.x,	pos.y+1,	pos.z+1,	b.top_start_u,	b.top_start_v,	top_scol));
		mesh.push_back(Vertex(pos.x+1,	pos.y+1,	pos.z+1,	b.top_end_u,    b.top_start_v,	top_scol));
		mesh.push_back(Vertex(pos.x+1,	pos.y+1,	pos.z,		b.top_end_u,    b.top_end_v,    top_scol));
		mesh.push_back(Vertex(pos.x,	pos.y+1,	pos.z,		b.top_start_u,	b.top_end_v,    top_scol));
	}
	
	void addDownFace(Block@ b, Vec3f pos)
	{
		mesh.push_back(Vertex(pos.x,	pos.y,		pos.z,		b.bottom_start_u,	b.bottom_start_v,	bottom_scol));
		mesh.push_back(Vertex(pos.x+1,	pos.y,		pos.z,		b.bottom_end_u,	    b.bottom_start_v,	bottom_scol));
		mesh.push_back(Vertex(pos.x+1,	pos.y,		pos.z+1,	b.bottom_end_u,	    b.bottom_end_v,		bottom_scol));
		mesh.push_back(Vertex(pos.x,	pos.y,		pos.z+1,	b.bottom_start_u,	b.bottom_end_v,		bottom_scol));
	}
	
	void addRightFace(Block@ b, Vec3f pos)
	{
		mesh.push_back(Vertex(pos.x+1,	pos.y+1,	pos.z,		b.sides_start_u,	b.sides_start_v,	right_scol));
		mesh.push_back(Vertex(pos.x+1,	pos.y+1,	pos.z+1,	b.sides_end_u,	    b.sides_start_v,	right_scol));
		mesh.push_back(Vertex(pos.x+1,	pos.y,		pos.z+1,	b.sides_end_u,	    b.sides_end_v,		right_scol));
		mesh.push_back(Vertex(pos.x+1,	pos.y,		pos.z,		b.sides_start_u,	b.sides_end_v,		right_scol));
	}
	
	void addLeftFace(Block@ b, Vec3f pos)
	{
		mesh.push_back(Vertex(pos.x,	pos.y+1,	pos.z+1,	b.sides_start_u,	b.sides_start_v,	left_scol));
        mesh.push_back(Vertex(pos.x,	pos.y+1,	pos.z,		b.sides_end_u,	    b.sides_start_v,	left_scol));
        mesh.push_back(Vertex(pos.x,	pos.y,		pos.z,		b.sides_end_u,	    b.sides_end_v,		left_scol));
        mesh.push_back(Vertex(pos.x,	pos.y,		pos.z+1,	b.sides_start_u,	b.sides_end_v,		left_scol));
	}

    void Render()
    {
        Render::RawQuads("Blocks.png", mesh);
    }
}

const u8 debug_alpha =	255;
const u8 top_col =		255;
const u8 bottom_col =	166;
const u8 left_col =		191;
const u8 right_col =	191;
const u8 front_col =	230;
const u8 back_col =		230;

const SColor top_scol = SColor(debug_alpha, top_col, top_col, top_col);
const SColor bottom_scol = SColor(debug_alpha, bottom_col, bottom_col, bottom_col);
const SColor left_scol = SColor(debug_alpha, left_col, left_col, left_col);
const SColor right_scol = SColor(debug_alpha, right_col, right_col, right_col);
const SColor front_scol = SColor(debug_alpha, front_col, front_col, front_col);
const SColor back_scol = SColor(debug_alpha, back_col, back_col, back_col);