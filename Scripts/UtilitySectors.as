
USector[] sectors;

class USector
{
    Vertex[] verts;
    uint timer;

    USector(){}

    USector(const AABB&in box, uint color, uint time)
    {
        MakeSector(box, color);
        timer = getGameTime()+time;
    }

    void MakeSector(const AABB&in box, uint color)
    {
        verts.push_back(Vertex(box.min.x,	box.min.y,	box.min.z,	0,	1,	color));
        verts.push_back(Vertex(box.min.x,	box.max.y,	box.min.z,	1,	1,	color));
        verts.push_back(Vertex(box.max.x,	box.max.y,	box.min.z,	1,	0,	color));
        verts.push_back(Vertex(box.max.x,	box.min.y,	box.min.z,	0,	0,	color));

        verts.push_back(Vertex(box.max.x,	box.min.y,	box.max.z,	0,	1,	color));
        verts.push_back(Vertex(box.max.x,	box.max.y,	box.max.z,	1,	1,	color));
        verts.push_back(Vertex(box.min.x,	box.max.y,	box.max.z,	1,	0,	color));
        verts.push_back(Vertex(box.min.x,	box.min.y,	box.max.z,	0,	0,	color));

        verts.push_back(Vertex(box.min.x,	box.min.y,	box.max.z,	0,	1,	color));
        verts.push_back(Vertex(box.min.x,	box.max.y,	box.max.z,	1,	1,	color));
        verts.push_back(Vertex(box.min.x,	box.max.y,	box.min.z,	1,	0,	color));
        verts.push_back(Vertex(box.min.x,	box.min.y,	box.min.z,	0,	0,	color));

        verts.push_back(Vertex(box.max.x,	box.min.y,	box.min.z,	0,	1,	color));
        verts.push_back(Vertex(box.max.x,	box.max.y,	box.min.z,	1,	1,	color));
        verts.push_back(Vertex(box.max.x,	box.max.y,	box.max.z,	1,	0,	color));
        verts.push_back(Vertex(box.max.x,	box.min.y,	box.max.z,	0,	0,	color));

        verts.push_back(Vertex(box.min.x,	box.max.y,	box.min.z,	0,	1,	color));
        verts.push_back(Vertex(box.min.x,	box.max.y,	box.max.z,	1,	1,	color));
        verts.push_back(Vertex(box.max.x,	box.max.y,	box.max.z,	1,	0,	color));
        verts.push_back(Vertex(box.max.x,	box.max.y,	box.min.z,	0,	0,	color));

        verts.push_back(Vertex(box.min.x,	box.min.y,	box.max.z,	0,	1,	color));
        verts.push_back(Vertex(box.min.x,	box.min.y,	box.min.z,	1,	1,	color));
        verts.push_back(Vertex(box.max.x,	box.min.y,	box.min.z,	1,	0,	color));
        verts.push_back(Vertex(box.max.x,	box.min.y,	box.max.z,	0,	0,	color));
    }

    bool Dead()
    {
        return timer <= getGameTime();
    }

    void Render()
    {
        Render::RawQuads("SOLID", verts);
    }
}

void AddSector(const AABB&in box, uint color, uint time)
{
    sectors.push_back(USector(box, color, time));
}

void UpdateSectors()
{
    for(int i = 0; i < sectors.size(); i++)
    {
        if(sectors[i].Dead())
        {
            sectors.removeAt(i);
        }
    }
}

void RenderSectors()
{
    for(int i = 0; i < sectors.size(); i++)
    {
        sectors[i].Render();
    }
}