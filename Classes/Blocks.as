
const f32 u_step = 1.0f/16.0f;
const f32 v_step = 1.0f/16.0f;

enum block_id
{
    block_air = 0,
    block_grass_dirt,
    block_dirt,
    block_stone,
    block_hard_stone,
    block_stone_wall,
    block_gold,
    block_crate,
    
    block_log_birch,
    block_log,
    block_leaves,
    block_planks_birch,
    block_planks,
    block_bricks,
    block_glass,
    block_wool_red,
    
    block_wool_orange,
    block_wool_yellow,
    block_wool_green,
    block_wool_cyan,
    block_wool_blue,
    block_wool_darkblue,
    block_wool_purple,
    block_wool_white,
    
    block_wool_gray,
    block_wool_black,
    block_wool_brown,
    block_wool_pink,
    block_metal_shiny,
    block_metal,
    block_gearbox,
    block_bedrock,
    
    block_fence,
    block_grass,
    block_tulip,
    block_tdelweiss,
    block_log_palm,
    block_sand,
    block_water,
    block_watersecond,
    
    blocks_count
}


Block@[] Blocks;

int counter = 0;
void InitBlocks()
{
    counter = 0;
    Blocks.clear();
    AddBlock("Air", false, true, 0);
    AddBlock("Grass dirt", true, false, 1, 2, 3);
    AddBlock("Dirt", true, false, 3);
    AddBlock("Stone", true, false, 4);
    AddBlock("Hard stone", true, false, 5);
    AddBlock("Stone wall", true, false, 6);
    AddBlock("Gold", true, false, 7);
    AddBlock("Crate", true, false, 8);
    AddBlock("Birch log", true, false, 81, 80);
    AddBlock("Log", true, false, 83, 82);
    AddBlock("Leaves", true, true, 19);
    AddBlock("Birch planks", true, false, 9);
    AddBlock("Planks", true, false, 10);
    AddBlock("Bricks", true, false, 11);
    AddBlock("Glass", true, true, 12);
    AddBlock("Red wool", true, false, 64);
    AddBlock("Orange wool", true, false, 65);
    AddBlock("Yellow wool", true, false, 66);
    AddBlock("Green wool", true, false, 67);
    AddBlock("Cyan wool", true, false, 68);
    AddBlock("Blue wool", true, false, 69); // nice
    AddBlock("Dark-blue wool", true, false, 70);
    AddBlock("Purple wool", true, false, 71);
    AddBlock("White wool", true, false, 74);
    AddBlock("Gray wool", true, false, 75);
    AddBlock("Black wool", true, false, 76);
    AddBlock("Brown wool", true, false, 73);
    AddBlock("Pink wool", true, false, 72);
    AddBlock("Shiny metal", true, false, 13);
    AddBlock("Metal", true, false, 14);
    AddBlock("Gearbox", true, false, 16);
    AddBlock("Bedrock", true, false, 240);
    AddBlock("Fence", true, false, 241);
    AddPlantBlock("Grass", 112);
    AddPlantBlock("Tulip", 113);
    AddPlantBlock("Edelweiss", 114);
    AddBlock("Palm log", true, false, 85, 84);
    AddBlock("Sand", true, false, 15);
    AddBlock("Water", true, false, 17);
    AddBlock("Deep water", true, false, 18);
    Debug("Blocks are created.");
}

class Block
{
    int id;
    string name;
    bool solid;
    bool see_through;
    bool plant;

    f32 sides_start_u;
    f32 sides_start_v;
    f32 sides_end_u;
    f32 sides_end_v;

    f32 top_start_u;
    f32 top_start_v;
    f32 top_end_u;
    f32 top_end_v;

    f32 bottom_start_u;
    f32 bottom_start_v;
    f32 bottom_end_u;
    f32 bottom_end_v;

    Block(){}

    void MakeUVs(int sides, int top, int bottom)
    {
        sides_start_u = f32(sides % 16) / 16.0f;
        sides_start_v = f32(sides / 16) / 16.0f;
        sides_end_u = sides_start_u + u_step;
        sides_end_v = sides_start_v + v_step;

        top_start_u = f32(top % 16) / 16.0f;
        top_start_v = f32(top / 16) / 16.0f;
        top_end_u = top_start_u + u_step;
        top_end_v = top_start_v + v_step;

        bottom_start_u = f32(bottom % 16) / 16.0f;
        bottom_start_v = f32(bottom / 16) / 16.0f;
        bottom_end_u = bottom_start_u + u_step;
        bottom_end_v = bottom_start_v + v_step;
    }
}

void AddBlock(const string&in name, bool solid, bool see_through, int allsides)
{
    Debug("name: "+name, 2);
    Block newblock;
    newblock.id = counter;
    newblock.name = name;
    newblock.solid = solid;
    newblock.see_through = see_through;
    newblock.MakeUVs(allsides, allsides, allsides);

    Blocks.push_back(@newblock);

    counter++;
}

void AddBlock(const string&in name, bool solid, bool see_through, int sides, int top_and_bottom)
{
    Debug("name: "+name, 2);
    Block newblock;
    newblock.id = counter;
    newblock.name = name;
    newblock.solid = solid;
    newblock.see_through = see_through;
    newblock.MakeUVs(sides, top_and_bottom, top_and_bottom);

    Blocks.push_back(@newblock);

    counter++;
}

void AddBlock(const string&in name, bool solid, bool see_through, int sides, int top, int bottom)
{
    Debug("name: "+name, 2);
    Block newblock;
    newblock.id = counter;
    newblock.name = name;
    newblock.solid = solid;
    newblock.see_through = see_through;
    newblock.MakeUVs(sides, top, bottom);

    Blocks.push_back(@newblock);

    counter++;
}

void AddPlantBlock(const string&in name, int sides)
{
    Block newblock;
    newblock.id = counter;
    newblock.name = name;
    newblock.solid = false;
    newblock.see_through = true;
    newblock.plant = true;
    newblock.MakeUVs(sides, sides, sides);

    Blocks.push_back(@newblock);

    counter++;
}