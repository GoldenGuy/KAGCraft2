
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


UText[] u_texts;

class UText
{
    string text;
    SColor color;
    uint timer;

    UText(){}

    UText(const string&in _text, uint _color, uint _timer)
    {
        text = _text;
        color.set(_color);
        timer = getGameTime()+_timer;
    }

    bool Dead()
    {
        return timer <= getGameTime();
    }

    void Render(int index)
    {
        int almost_dead = 0;
        if(timer - getGameTime() < 32)
        {
            almost_dead = 32 - (timer - getGameTime());
        }

        GUI::DrawTextCentered(text, getDriver().getScreenCenterPos()-Vec2f(0, index*12+120), SColor(255-Maths::Max(0, almost_dead*8), color.getRed(), color.getGreen(), color.getBlue()));
    }
}

void AddUText(const string&in text, uint color, uint time)
{
    u_texts.push_back(UText(text, color, time));
}

void UpdateUTexts()
{
    for(int i = 0; i < u_texts.size(); i++)
    {
        if(u_texts[i].Dead())
        {
            u_texts.removeAt(i);
        }
        else
        {
            u_texts[i].timer -= (u_texts.size()-(i+1));
            if(u_texts[i].timer <= getGameTime())
            {
                u_texts.removeAt(i);
            }
        }
    }
}

void RenderUTexts()
{
    for(int i = 0; i < u_texts.size(); i++)
    {
        u_texts[i].Render(u_texts.size()-1-i);
    }
}