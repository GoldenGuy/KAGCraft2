
uint32 saving_map_packet_size = 0;
uint32 saving_map_packets_amount = 0;
uint32 saving_map_packet = 0;

uint32 loading_map_packet_size = 0;//world.chunk_width*world.chunk_depth*world.chunk_height*32; // 32 chunks per load
uint32 loading_map_packets_amount = 0;//world.map_size / loading_map_packet_size;
uint32 loading_map_packet = 0;

bool map_saving = false;
bool map_loading = false;

void StartSaving()
{
    print("Starting saving map.");
    saving_map_packet = 0;
    loading_map_packet = 0;
    map_saving = true;
    map_loading = false;

    saving_map_packet_size = world.chunk_width*world.chunk_depth*world.chunk_height*8; // 4 chunks per save
    saving_map_packets_amount = world.map_size / saving_map_packet_size;
}

uint32 temp_image_size = 0;
uint32 temp_image_wh = 0;

void UpdateSL()
{
    if(map_saving)
    {
        if(saving_map_packet == 0)
        {
            ConfigFile cfg = ConfigFile();
            cfg.add_bool("pog", true);
            cfg.saveFile("TEMPFOLDERNNAME/temp_map_name.cfg");
            temp_image_size = saving_map_packet_size;
            temp_image_wh = Maths::Sqrt(float(temp_image_size));
        }

        CFileImage image(temp_image_wh, temp_image_wh, true);
	    image.setFilename("TEMPFOLDERNNAME/packet_n"+saving_map_packet+".png", IMAGE_FILENAME_BASE_CACHE);
        image.nextPixel();

        uint32 start = saving_map_packet*saving_map_packet_size;
        uint32 end = start+saving_map_packet_size;

        for(uint32 i = start; i < end; i += 4)
        {
            Vec3f pos1 = world.getPosFromWorldIndex(i);
            Vec3f pos2 = world.getPosFromWorldIndex(i+1);
            Vec3f pos3 = world.getPosFromWorldIndex(i+2);
            Vec3f pos4 = world.getPosFromWorldIndex(i+3);
            SColor color = SColor(world.getBlockSafe(pos1.x, pos1.y, pos1.z), world.getBlockSafe(pos2.x, pos2.y, pos2.z), world.getBlockSafe(pos3.x, pos3.y, pos3.z), world.getBlockSafe(pos4.x, pos4.y, pos4.z));
            image.setPixelAndAdvance(color);
            getNet().server_KeepConnectionsAlive();
        }

        image.Save();

        saving_map_packet++;
        if(saving_map_packet >= saving_map_packets_amount)
        {
            print("Map saving done.");
            saving_map_packet = 0;
            map_saving = false;
            return;
        }
    }
    else if(map_loading)
    {

    }
}