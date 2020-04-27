
void SetUpTree()
{
    tree.Init();
    Debug("Tree is generated.");
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

    void Init()
    {
        box = AABB(Vec3f(0, 0, 0), Vec3f(map_width, map_height, map_depth));

        Branch _BRxz(Vec3f(0, 0, 0),                      Vec3f(map_width/2, map_height, map_depth/2));
        Branch _BRx1z(Vec3f(map_width/2, 0, 0),            Vec3f(map_width, map_height, map_depth/2));
        Branch _BRxz1(Vec3f(0, 0, map_depth/2),            Vec3f(map_width/2, map_height, map_depth));
        Branch _BRx1z1(Vec3f(map_width/2, 0, map_depth/2),  Vec3f(map_width, map_height, map_depth));

        @BRxz = @_BRxz;
        @BRx1z = @_BRx1z;
        @BRxz1 = @_BRxz1;
        @BRx1z1 = @_BRx1z1;
    }

    void Check()
    {
        chunks_to_render.clear();

        BRxz.Check();
        BRx1z.Check();
        BRxz1.Check();
        BRx1z1.Check();
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

        if(pos_end.x-pos_start.x <= chunk_width*2)
        {
            // leaf, fill chunks here

            leaf = true;

            Vec3f chunk_pos_start = pos_start/Vec3f(chunk_width, chunk_height, chunk_depth);

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

            Branch _BRxyz(pos_start,                        pos_start+size);            @BRxyz = @_BRxyz;
            Branch _BRx1yz(pos_start+size*Vec3f(1,0,0),     pos_end-size*Vec3f(0,1,1)); @BRx1yz = @_BRx1yz;
            Branch _BRxyz1(pos_start+size*Vec3f(0,0,1),     pos_end-size*Vec3f(1,1,0)); @BRxyz1 = @_BRxyz1;
            Branch _BRx1yz1(pos_start+size*Vec3f(1,0,1),    pos_end-size*Vec3f(0,1,0)); @BRx1yz1 = @_BRx1yz1;
            Branch _BRxy1z(pos_start+size*Vec3f(0,1,0),     pos_end-size*Vec3f(1,0,1)); @BRxy1z = @_BRxy1z;
            Branch _BRx1y1z(pos_start+size*Vec3f(1,1,0),    pos_end-size*Vec3f(0,0,1)); @BRx1y1z = @_BRx1y1z;
            Branch _BRxy1z1(pos_start+size*Vec3f(0,1,1),    pos_end-size*Vec3f(1,0,0)); @BRxy1z1 = @_BRxy1z1;
            Branch _BRx1y1z1(pos_start+size,                pos_end);                   @BRx1y1z1 = @_BRx1y1z1;
        }
    }

    void Check()
    {
        if(camera.frustum.ContainsSphere( box.center-camera.frustum_pos, box.corner))//(camera.frustum.ContainsAABB(box - camera.frustum_pos))
        {
            if(leaf)
            {
                if(!CHxyz.empty && camera.frustum.ContainsSphere( CHxyz.box.center-camera.frustum_pos, CHxyz.box.corner)) chunks_to_render.push_back(@CHxyz);
                if(!CHx1yz.empty && camera.frustum.ContainsSphere( CHx1yz.box.center-camera.frustum_pos, CHx1yz.box.corner)) chunks_to_render.push_back(@CHx1yz);
                if(!CHxyz1.empty && camera.frustum.ContainsSphere( CHxyz1.box.center-camera.frustum_pos, CHxyz1.box.corner)) chunks_to_render.push_back(@CHxyz1);
                if(!CHx1yz1.empty && camera.frustum.ContainsSphere( CHx1yz1.box.center-camera.frustum_pos, CHx1yz1.box.corner)) chunks_to_render.push_back(@CHx1yz1);
                if(!CHxy1z.empty && camera.frustum.ContainsSphere( CHxy1z.box.center-camera.frustum_pos, CHxy1z.box.corner)) chunks_to_render.push_back(@CHxy1z);
                if(!CHx1y1z.empty && camera.frustum.ContainsSphere( CHx1y1z.box.center-camera.frustum_pos, CHx1y1z.box.corner)) chunks_to_render.push_back(@CHx1y1z);
                if(!CHxy1z1.empty && camera.frustum.ContainsSphere( CHxy1z1.box.center-camera.frustum_pos, CHxy1z1.box.corner)) chunks_to_render.push_back(@CHxy1z1);
                if(!CHx1y1z1.empty && camera.frustum.ContainsSphere( CHx1y1z1.box.center-camera.frustum_pos, CHx1y1z1.box.corner)) chunks_to_render.push_back(@CHx1y1z1);
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