
void SetUpTree()
{
    tree.Init();
}

Root tree;
Chunk@[] chunks_to_render;

class Root
{
    AABB box;

    Branch@ BRxz;
    Branch@ BRx1z;
    Branch@ BRxz1;
    Branch@ BRx1z1;

    Branch@ BRx2z;
    Branch@ BRx3z;
    Branch@ BRx2z1;
    Branch@ BRx3z1;

    Branch@ BRxz2;
    Branch@ BRx1z2;
    Branch@ BRxz3;
    Branch@ BRx1z3;

    Branch@ BRx2z2;
    Branch@ BRx3z2;
    Branch@ BRx2z3;
    Branch@ BRx3z3;

    void Init()
    {
        box = AABB(Vec3f(0, 0, 0), Vec3f(world.map_width, world.map_height, world.map_depth));

        @BRxz =     @Branch(Vec3f(0,                0, 0),              Vec3f(world.map_width/4,      world.map_height, world.map_depth/4));
        @BRx1z =    @Branch(Vec3f(world.map_width/4,      0, 0),              Vec3f(world.map_width/2,      world.map_height, world.map_depth/4));
        @BRxz1 =    @Branch(Vec3f(0,                0, world.map_depth/4),    Vec3f(world.map_width/4,      world.map_height, world.map_depth/2));
        @BRx1z1 =   @Branch(Vec3f(world.map_width/4,      0, world.map_depth/4),    Vec3f(world.map_width/2,      world.map_height, world.map_depth/2));

        @BRx2z =    @Branch(Vec3f(world.map_width/2,      0, 0),              Vec3f(world.map_width/4*3,    world.map_height, world.map_depth/4));
        @BRx3z =    @Branch(Vec3f(world.map_width/4*3,    0, 0),              Vec3f(world.map_width,        world.map_height, world.map_depth/4));
        @BRx2z1 =   @Branch(Vec3f(world.map_width/2,      0, world.map_depth/4),    Vec3f(world.map_width/4*3,    world.map_height, world.map_depth/2));
        @BRx3z1 =   @Branch(Vec3f(world.map_width/4*3,    0, world.map_depth/4),    Vec3f(world.map_width,        world.map_height, world.map_depth/2));

        @BRxz2 =    @Branch(Vec3f(0,                0, world.map_depth/2),    Vec3f(world.map_width/4,      world.map_height, world.map_depth/4*3));
        @BRx1z2 =   @Branch(Vec3f(world.map_width/4,      0, world.map_depth/2),    Vec3f(world.map_width/2,      world.map_height, world.map_depth/4*3));
        @BRxz3 =    @Branch(Vec3f(0,                0, world.map_depth/4*3),  Vec3f(world.map_width/4,      world.map_height, world.map_depth));
        @BRx1z3 =   @Branch(Vec3f(world.map_width/4,      0, world.map_depth/4*3),  Vec3f(world.map_width/2,      world.map_height, world.map_depth));

        @BRx2z2 =   @Branch(Vec3f(world.map_width/2,      0, world.map_depth/2),    Vec3f(world.map_width/4*3,    world.map_height, world.map_depth/4*3));
        @BRx3z2 =   @Branch(Vec3f(world.map_width/4*3,    0, world.map_depth/2),    Vec3f(world.map_width,        world.map_height, world.map_depth/4*3));
        @BRx2z3 =   @Branch(Vec3f(world.map_width/2,      0, world.map_depth/4*3),  Vec3f(world.map_width/4*3,    world.map_height, world.map_depth));
        @BRx3z3 =   @Branch(Vec3f(world.map_width/4*3,    0, world.map_depth/4*3),  Vec3f(world.map_width,        world.map_height, world.map_depth));
    }

    void Check()
    {
        chunks_to_render.clear();
        generated = 0;

        BRxz.Check();
        BRx1z.Check();
        BRxz1.Check();
        BRx1z1.Check();

        BRx2z.Check();
        BRx3z.Check();
        BRx2z1.Check();
        BRx3z1.Check();

        BRxz2.Check();
        BRx1z2.Check();
        BRxz3.Check();
        BRx1z3.Check();

        BRx2z2.Check();
        BRx3z2.Check();
        BRx2z3.Check();
        BRx3z3.Check();
    }
}

class Branch
{
    bool leaf = false;

    AABB box;

    Branch@ BRxyz;
    Branch@ BRx1yz;
    Branch@ BRxyz1;
    Branch@ BRx1yz1;
    Branch@ BRxy1z;
    Branch@ BRx1y1z;
    Branch@ BRxy1z1;
    Branch@ BRx1y1z1;

    Chunk@ CHxyz;
    Chunk@ CHx1yz;
    Chunk@ CHxyz1;
    Chunk@ CHx1yz1;
    Chunk@ CHxy1z;
    Chunk@ CHx1y1z;
    Chunk@ CHxy1z1;
    Chunk@ CHx1y1z1;

    Branch(){}

    Branch(const Vec3f&in pos_start, const Vec3f&in pos_end)
    {
        box = AABB(pos_start, pos_end);

        if(pos_end.y-pos_start.y <= world.chunk_height*2)
        {
            // leaf, fill chunks here

            leaf = true;

            Vec3f chunk_pos_start = pos_start/Vec3f(world.chunk_width, world.chunk_height, world.chunk_depth);

            @CHxyz =     world.getChunk(chunk_pos_start.x, chunk_pos_start.y, chunk_pos_start.z);
            @CHx1yz =    world.getChunk(chunk_pos_start.x+1, chunk_pos_start.y, chunk_pos_start.z);
            @CHxyz1 =    world.getChunk(chunk_pos_start.x, chunk_pos_start.y, chunk_pos_start.z+1);
            @CHx1yz1 =   world.getChunk(chunk_pos_start.x+1, chunk_pos_start.y, chunk_pos_start.z+1);
            @CHxy1z =    world.getChunk(chunk_pos_start.x, chunk_pos_start.y+1, chunk_pos_start.z);
            @CHx1y1z =   world.getChunk(chunk_pos_start.x+1, chunk_pos_start.y+1, chunk_pos_start.z);
            @CHxy1z1 =   world.getChunk(chunk_pos_start.x, chunk_pos_start.y+1, chunk_pos_start.z+1);
            @CHx1y1z1 =  world.getChunk(chunk_pos_start.x+1, chunk_pos_start.y+1, chunk_pos_start.z+1);
        }
        else
        {
            // not leaf, we can continue

            Vec3f size = (pos_end-pos_start)/2;

            @BRxyz =    @Branch(pos_start,                   pos_start+size);
            @BRx1yz =   @Branch(pos_start+size*Vec3f(1,0,0), pos_end-size*Vec3f(0,1,1));
            @BRxyz1 =   @Branch(pos_start+size*Vec3f(0,0,1), pos_end-size*Vec3f(1,1,0));
            @BRx1yz1 =  @Branch(pos_start+size*Vec3f(1,0,1), pos_end-size*Vec3f(0,1,0));
            @BRxy1z =   @Branch(pos_start+size*Vec3f(0,1,0), pos_end-size*Vec3f(1,0,1));
            @BRx1y1z =  @Branch(pos_start+size*Vec3f(1,1,0), pos_end-size*Vec3f(0,0,1));
            @BRxy1z1 =  @Branch(pos_start+size*Vec3f(0,1,1), pos_end-size*Vec3f(1,0,0));
            @BRx1y1z1 = @Branch(pos_start+size,              pos_end);
        }
        getNet().server_KeepConnectionsAlive();
    }

    void Check()
    {
        if(camera.frustum.ContainsSphere( box.center-camera.frustum_pos, box.corner))//(camera.frustum.ContainsAABB(box - camera.frustum_pos))
        {
            if(leaf)
            {
                if(CHxyz !is null)
                if(!CHxyz.empty)
                {
                    if(camera.frustum.ContainsSphere( CHxyz.box.center-camera.frustum_pos, CHxyz.box.corner))
                    {
                        chunks_to_render.push_back(@CHxyz);
                        if(CHxyz.rebuild && generated < max_generate)
                        {
                            CHxyz.GenerateMesh();
                            generated++;
                        }
                    }
                }

                if(CHx1yz !is null)
                if(!CHx1yz.empty)
                {
                    if(camera.frustum.ContainsSphere( CHx1yz.box.center-camera.frustum_pos, CHx1yz.box.corner))
                    {
                        chunks_to_render.push_back(@CHx1yz);
                        if(CHx1yz.rebuild && generated < max_generate)
                        {
                            CHx1yz.GenerateMesh();
                            generated++;
                        }
                    }
                }

                if(CHxyz1 !is null)
                if(!CHxyz1.empty)
                {
                    if(camera.frustum.ContainsSphere( CHxyz1.box.center-camera.frustum_pos, CHxyz1.box.corner))
                    {
                        chunks_to_render.push_back(@CHxyz1);
                        if(CHxyz1.rebuild && generated < max_generate)
                        {
                            CHxyz1.GenerateMesh();
                            generated++;
                        }
                    }
                }

                if(CHx1yz1 !is null)
                if(!CHx1yz1.empty)
                {
                    if(camera.frustum.ContainsSphere( CHx1yz1.box.center-camera.frustum_pos, CHx1yz1.box.corner))
                    {
                        chunks_to_render.push_back(@CHx1yz1);
                        if(CHx1yz1.rebuild && generated < max_generate)
                        {
                            CHx1yz1.GenerateMesh();
                            generated++;
                        }
                    }
                }

                if(CHxy1z !is null)
                if(!CHxy1z.empty)
                {
                    if(camera.frustum.ContainsSphere( CHxy1z.box.center-camera.frustum_pos, CHxy1z.box.corner))
                    {
                        chunks_to_render.push_back(@CHxy1z);
                        if(CHxy1z.rebuild && generated < max_generate)
                        {
                            CHxy1z.GenerateMesh();
                            generated++;
                        }
                    }
                }

                if(CHx1y1z !is null)
                if(!CHx1y1z.empty)
                {
                    if(camera.frustum.ContainsSphere( CHx1y1z.box.center-camera.frustum_pos, CHx1y1z.box.corner))
                    {
                        chunks_to_render.push_back(@CHx1y1z);
                        if(CHx1y1z.rebuild && generated < max_generate)
                        {
                            CHx1y1z.GenerateMesh();
                            generated++;
                        }
                    }
                }

                if(CHxy1z1 !is null)
                if(!CHxy1z1.empty)
                {
                    if(camera.frustum.ContainsSphere( CHxy1z1.box.center-camera.frustum_pos, CHxy1z1.box.corner))
                    {
                        chunks_to_render.push_back(@CHxy1z1);
                        if(CHxy1z1.rebuild && generated < max_generate)
                        {
                            CHxy1z1.GenerateMesh();
                            generated++;
                        }
                    }
                }

                if(CHx1y1z1 !is null)
                if(!CHx1y1z1.empty)
                {
                    if(camera.frustum.ContainsSphere( CHx1y1z1.box.center-camera.frustum_pos, CHx1y1z1.box.corner))
                    {
                        chunks_to_render.push_back(@CHx1y1z1);
                        if(CHx1y1z1.rebuild && generated < max_generate)
                        {
                            CHx1y1z1.GenerateMesh();
                            generated++;
                        }
                    }
                }
            }
            else
            {
                BRxyz.Check();
                BRx1yz.Check();
                BRxyz1.Check();
                BRx1yz1.Check(); 
                BRxy1z.Check();
                BRx1y1z.Check();
                BRxy1z1.Check();
                BRx1y1z1.Check();
            }
        }
    }
}