
void onRenderScoreboard(CRules@ this)
{
	Vec2f top_right = Vec2f(getScreenWidth()-30, 30);
    Vec2f top_left = Vec2f(top_right.x - 20 - 240 - 30 - 180 - 30 - 48 - 20, top_right.y);

    int y = 0;
    int y_step = 16;

    GUI::DrawRectangle(top_left-Vec2f(10,10), Vec2f(top_right.x, top_right.y + getPlayersCount()*y_step)+Vec2f(10,10), 0xAA404040);
    
    for(int i = 0; i < getPlayersCount(); i++)
    {
        CPlayer@ player = getPlayer(i);
        SColor color = getNameColour(player);
        GUI::DrawLine2D(top_left+Vec2f(0,y+14), top_right+Vec2f(0,y+14), 0xAAAAAAAA);
        GUI::DrawText(player.getCharacterName(), top_left+Vec2f(0,y-1), color);
        GUI::DrawText(player.getUsername(), top_left+Vec2f(240+45,y-1), color);

        int ping_in_ms = int(player.getPing() * 1000.0f / 30.0f);
        int ping_icon = 0;
		if(ping_in_ms >= 66) ping_icon = 1;
		if(ping_in_ms >= 100) ping_icon = 2;
		if(ping_in_ms >= 200) ping_icon = 3;
		if(ping_in_ms >= 300) ping_icon = 4;
		GUI::DrawIcon("server_icons.png", 3+ping_icon, Vec2f(16, 16), top_left+Vec2f(240+45+180+45,y-1), 0.5f, 0);
		GUI::DrawText("" + (ping_in_ms > 2000 ? "∞" : (""+ping_in_ms)), top_left+Vec2f(240+45+180+45+18,y-1), color_white);

        y += y_step;
    }
}

SColor getNameColour(CPlayer@ p)
{
    SColor c;

    string seclev = getSecurity().getPlayerSeclev(p).getName();
    //print(seclev);

    if (p.isDev())	//dev
	{
        c = SColor(0xff9900DB);
    }
	else if (p.isGuard())	//guard
	{
        c = SColor(0xff5FCC5F);
    }
	else if (getSecurity().getPlayerSeclev(p).getName() == "Admin")	//cool
	{
        c = SColor(0xffF08020);
	}
	else if (p.getOldGold() && !p.isBot())	//gold
	{
        c = SColor(0xffBC8F14);
    }
	else	//normal
	{
		c = SColor(0xffffffff);
    }
	return c;
}