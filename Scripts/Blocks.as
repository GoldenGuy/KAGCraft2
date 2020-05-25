

namespace Block
{
    const float u_step = 1.0f/16.0f;
    const float v_step = 1.0f/16.0f;
    const float uv_fix = 0.0002f;
    
    enum block_id
    {
        air = 0,
        grass_dirt,
        dirt,
        stone,
        hard_stone,
        stone_wall,
        gold,
        crate,

        log_birch,
        log,
        leaves,
        planks_birch,
        planks,
        bricks,
        glass,
        wool_red,

        wool_orange,
        wool_yellow,
        wool_green,
        wool_cyan,
        wool_blue,
        wool_darkblue,
        wool_purple,
        wool_white,

        wool_gray,
        wool_black,
        wool_brown,
        wool_pink,
        metal_shiny,
        metal,
        gearbox,
        bedrock,

        fence,
        grass,
        tulip,
        edelweiss,
        log_palm,
        sand,
        water,
        watersecond,
        
        blocks_count
    }

    string[] block_names;
    bool[] solid;
    bool[] see_through;
    bool[] plant;
    float[] dig_speed;
    bool[] allowed_to_build;

    float[] u_sides_start;
    float[] v_sides_start;
    float[] u_sides_end;
    float[] v_sides_end;

    float[] u_top_start;
    float[] v_top_start;
    float[] u_top_end;
    float[] v_top_end;

    float[] u_bottom_start;
    float[] v_bottom_start;
    float[] u_bottom_end;
    float[] v_bottom_end;

    void MakeUVs(int sides, int top, int bottom)
    {
        float sides_start_u = float(sides % 16) / 16.0f + uv_fix;
        float sides_start_v = float(sides / 16) / 16.0f + uv_fix;
        float sides_end_u = sides_start_u + u_step - uv_fix*2.0f;
        float sides_end_v = sides_start_v + v_step - uv_fix*2.0f;

        float top_start_u = float(top % 16) / 16.0f + uv_fix;
        float top_start_v = float(top / 16) / 16.0f + uv_fix;
        float top_end_u = top_start_u + u_step - uv_fix*2.0f;
        float top_end_v = top_start_v + v_step - uv_fix*2.0f;

        float bottom_start_u = float(bottom % 16) / 16.0f + uv_fix;
        float bottom_start_v = float(bottom / 16) / 16.0f + uv_fix;
        float bottom_end_u = bottom_start_u + u_step - uv_fix*2.0f;
        float bottom_end_v = bottom_start_v + v_step - uv_fix*2.0f;

        u_sides_start.push_back(sides_start_u);
        v_sides_start.push_back(sides_start_v);
        u_sides_end.push_back(sides_end_u);
        v_sides_end.push_back(sides_end_v);

        u_top_start.push_back(top_start_u);
        v_top_start.push_back(top_start_v);
        u_top_end.push_back(top_end_u);
        v_top_end.push_back(top_end_v);

        u_bottom_start.push_back(bottom_start_u);
        v_bottom_start.push_back(bottom_start_v);
        u_bottom_end.push_back(bottom_end_u);
        v_bottom_end.push_back(bottom_end_v);
    }
}

//int block_counter = 0;
void InitBlocks()
{
    //block_counter = 0;
    Block::block_names.clear();
    Block::solid.clear();
    Block::see_through.clear();
    Block::plant.clear();
    Block::dig_speed.clear();
    Block::allowed_to_build.clear();

    Block::u_sides_start.clear();
    Block::v_sides_start.clear();
    Block::u_sides_end.clear();
    Block::v_sides_end.clear();
    Block::u_top_start.clear();
    Block::v_top_start.clear();
    Block::u_top_end.clear();
    Block::v_top_end.clear();
    Block::u_bottom_start.clear();
    Block::v_bottom_start.clear();
    Block::u_bottom_end.clear();
    Block::v_bottom_end.clear();

    //Blocks.clear();
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
    AddBlock("Fence", true, true, 241);
    AddPlantBlock("Grass", 112);
    AddPlantBlock("Tulip", 113);
    AddPlantBlock("Edelweiss", 114);
    AddBlock("Palm log", true, false, 85, 84);
    AddBlock("Sand", true, false, 15);
    AddBlock("Water", true, false, 17);
    AddBlock("Deep water", true, false, 18);

    Block::dig_speed[Block::bedrock] = 0;
    Block::dig_speed[Block::fence] = 2.2;
    Block::dig_speed[Block::leaves] = 13;
    Block::dig_speed[Block::stone] = 3;
    Block::dig_speed[Block::hard_stone] = 3;
    Block::dig_speed[Block::water] = 15;
    Block::dig_speed[Block::watersecond] = 15;
    Block::dig_speed[Block::glass] = 20;

    Block::allowed_to_build[Block::air] = false;
    Block::allowed_to_build[Block::bedrock] = false;
}

void AddBlock(const string&in name, bool _solid, bool _see_through, int allsides)
{
    Block::block_names.push_back(name);
    Block::solid.push_back(_solid);
    Block::see_through.push_back(_see_through);
    Block::plant.push_back(false);
    Block::dig_speed.push_back(6);
    Block::allowed_to_build.push_back(true);

    Block::MakeUVs(allsides, allsides, allsides);
}

void AddBlock(const string&in name, bool _solid, bool _see_through, int sides, int top_and_bottom)
{
    Block::block_names.push_back(name);
    Block::solid.push_back(_solid);
    Block::see_through.push_back(_see_through);
    Block::plant.push_back(false);
    Block::dig_speed.push_back(6);
    Block::allowed_to_build.push_back(true);

    Block::MakeUVs(sides, top_and_bottom, top_and_bottom);
}

void AddBlock(const string&in name, bool _solid, bool _see_through, int sides, int top, int bottom)
{
    Block::block_names.push_back(name);
    Block::solid.push_back(_solid);
    Block::see_through.push_back(_see_through);
    Block::plant.push_back(false);
    Block::dig_speed.push_back(6);
    Block::allowed_to_build.push_back(true);

    Block::MakeUVs(sides, top, bottom);
}

void AddPlantBlock(const string&in name, int sides)
{
    Block::block_names.push_back(name);
    Block::solid.push_back(false);
    Block::see_through.push_back(true);
    Block::plant.push_back(true);
    Block::dig_speed.push_back(30);
    Block::allowed_to_build.push_back(true);

    Block::MakeUVs(sides, sides, sides);
}