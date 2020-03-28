
#include "Blocks.as"

const int chunk_width = 10;
const int chunk_depth = 10;
const int chunk_height = 10;

int world_width = 12;
int world_depth = 12;
int world_height = 6;
int world_width_depth = world_width * world_depth;
int world_size = world_width_depth * world_height;

int map_width = world_width * chunk_width;
int map_depth = world_depth * chunk_depth;
int map_height = world_height * chunk_height;
int map_width_depth = map_width * map_depth;
int map_size = map_width_depth * map_height;

class World
{
    u8[] map;
    u8[] faces_bits;

    void GenerateMap()
    {
        map.clear();
        map.resize(map_size);

        for(int y = 0; y < map_height; y++)
        {
            for(int z = 0; z < map_depth; z++)
            {
                for(int x = 0; x < map_width; x++)
                {
                    int index = y*map_width_depth + z*map_width + x;
                    if(y<10)
                    {
                        map[index] = BlockID::block_hard_stone;
                        continue;
                    }
                    else if(y<14)
                    {
                        map[index] = BlockID::block_stone;
                        continue;
                    }
                    else if(y<16)
                    {
                        map[index] = BlockID::block_dirt;
                        continue;
                    }
                    else if(y<17)
                    {
                        map[index] = BlockID::block_grass_dirt;
                        continue;
                    }
                    else
                    {
                        map[index] = BlockID::block_air;
                        continue;
                    }
                }
            }
        }
        debug("Map generated");
    }

    void GenerateBlockFaces()
    {
        print("size: "+Blocks.size());
        faces_bits.clear();
        faces_bits.resize(map_size);

        for(int y = 0; y < map_height; y++)
        {
            for(int z = 0; z < map_depth; z++)
            {
                for(int x = 0; x < map_width; x++)
                {
                    //print("x: "+x+"; y: "+y+"; z: "+z);
                    UpdateBlockFaces(x, y, z);
                }
            }
        }
    }

    void UpdateBlockFaces(int x, int y, int z)
    {
        u8 faces = 0;

        if(x > 0) if(!Blocks[map[getIndex(x-1, y, z)]].see_through) faces += 1;
        if(x < map_width-1) if(!Blocks[map[getIndex(x+1, y, z)]].see_through) faces += 2;
        if(z > 0) if(!Blocks[map[getIndex(x, y, z-1)]].see_through) faces += 4;
        if(z < map_depth-1) if(!Blocks[map[getIndex(x, y, z+1)]].see_through) faces += 8;
        if(y > 0) if(!Blocks[map[getIndex(x, y-1, z)]].see_through) faces += 16;
        if(y < map_height-1) if(!Blocks[map[getIndex(x, y+1, z)]].see_through) faces += 32;

        faces_bits[getIndex(x, y, z)] = faces;
    }

    int getIndex(int x, int y, int z)
    {
        int index = y*map_width_depth + z*map_width + x;
        return index;
    }

    void Serialize(CBitStream@ params)
    {
        uint similars = 1;
        u8 similar_block_id = 0;
        u8 block_id = 0;
        for(int i = 0; i < map_size; i++)
        {
            if(i == 0)
            {
                similar_block_id = map[i];
                block_id = similar_block_id;
                continue;
            }
            else
            {
                block_id = map[i];
                if(similar_block_id != block_id)
                {
                    params.write_u32(similars);
                    params.write_u8(similar_block_id);
                    similar_block_id = block_id;
                    similars = 1;
                }
                else
                {
                    similars++;
                }
            }
        }
    }

    void UnSerialize(CBitStream params)
    {
        map.clear();
        map.resize(map_size);
        int index = 0;
        while(!params.isBufferEnd())
        {
            u32 amount = params.read_u32();
            u8 block_id = params.read_u8();
            for(int i = 0; i < amount; i++)
            {
                map[index+i] = block_id;
                index++;
            }
        }
    }
}

class Chunk
{
    World@ _world;
    int x, y, z, world_x, world_y, world_z;
    int index, world_index;
    bool rebuild;
    Vertex[] mesh;

    Chunk(){}

    void GenerateMesh()
    {
        rebuild = false;
    }
}