
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
    u8[] Map;

    void GenerateMap()
    {
        Map.clear();
        Map.resize(map_size);

        for(int y = 0; y < map_height; y++)
        {
            for(int z = 0; z < map_depth; z++)
            {
                for(int x = 0; x < map_width; x++)
                {
                    int index = y*map_width_depth + z*map_width + x;
                    if(y<10)
                    {
                        Map[index] = BlockID::block_hard_stone;
                        continue;
                    }
                    else if(y<14)
                    {
                        Map[index] = BlockID::block_stone;
                        continue;
                    }
                    else if(y<16)
                    {
                        Map[index] = BlockID::block_dirt;
                        continue;
                    }
                    else if(y<17)
                    {
                        Map[index] = BlockID::block_grass_dirt;
                        continue;
                    }
                    else
                    {
                        Map[index] = BlockID::block_air;
                        continue;
                    }
                }
            }
        }
        print("Map generated");
    }
}