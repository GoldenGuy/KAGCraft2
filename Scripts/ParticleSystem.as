
int particle_cap = 250;

class ParticleSystem
{
    Particle[] particles;

    ParticleSystem()
    {
        particles.clear();
    }

    void AddParticle(uint8 block_id, const Vec3f&in pos, const Vec3f&in vel)
    {
        particles.push_back(Particle(block_id, pos, vel));
    }

    void Update()
    {
        for(int i = 0; i < particles.size(); i++)
        {
            particles[i].Update();
            if(particles[i].dead)
            {
                particles.removeAt(i);
            }
        }
    }

    void Render(Vec3f look)
    {
        Vertex[] verts;
        for(int i = 0; i < particles.size(); i++)
        {
            particles[i].Render(@verts, look);
        }
        Render::RawQuads("Block_Textures", verts);
    }
}

class Particle
{
    Vec3f pos, old_pos, vel;
    float u, v, _u, _v, scale;
    int timer;
    bool stick = false;
    bool dead = false;

    Particle(uint8 block_id, const Vec3f&in _pos, const Vec3f&in _vel)
    {
        timer = XORRandom(10)+40;
        pos = old_pos = _pos;
        vel = _vel;
        float _scale = XORRandom(3)+1;
        scale = _scale/16.0f;
        _u = _v = 0.00390625f*_scale;
        Vec2f temp_uv_start(XORRandom(16-_scale)*0.00390625f, XORRandom(16-_scale)*0.00390625f);
        switch (XORRandom(3))
        {
            case 0:
            {
                temp_uv_start.x += Block::u_sides_start[block_id];
                temp_uv_start.y += Block::v_sides_start[block_id];
                break;
            }
            case 1:
            {
                temp_uv_start.x += Block::u_top_start[block_id];
                temp_uv_start.y += Block::v_top_start[block_id];
                break;
            }
            case 2:
            {
                temp_uv_start.x += Block::u_bottom_start[block_id];
                temp_uv_start.y += Block::v_bottom_start[block_id];
                break;
            }
        }
        u = temp_uv_start.x;
        v = temp_uv_start.y;
        _u += u;
        _v += v;
    }

    void Update()
    {
        timer--;
        if(timer <= 0)
        {
            dead = true;
            return;
        }
        old_pos = pos;
        if(stick)
        {
            return;
        }
        pos += vel;
        vel.y -= 0.017f;
        vel.x *= 0.986f;
        vel.z *= 0.986f;
        uint8 block_id = world.getBlockSafe(pos.x, pos.y, pos.z);
        if(block_id != 255)
        {
            if(Block::solid[block_id])
            {
                stick = true;
                if(timer > 30)
                {
                    timer -= 15;
                }
            }
        }
    }

    void Render(Vertex[]@ verts, Vec3f look)
    {
        look /= 2;
        look *= scale;
        Vec3f render_pos = old_pos.Lerp(pos, getInterFrameTime());
        verts.push_back(Vertex(render_pos.x-look.x, render_pos.y, render_pos.z-look.z, u, _v, color_white));
        verts.push_back(Vertex(render_pos.x-look.x, render_pos.y+scale, render_pos.z-look.z, u, v, color_white));
        verts.push_back(Vertex(render_pos.x+look.x, render_pos.y+scale, render_pos.z+look.z, _u, v, color_white));
        verts.push_back(Vertex(render_pos.x+look.x, render_pos.y, render_pos.z+look.z, _u, _v, color_white));
    }
}