
Vertex[] HitBoxes;

void Debug(string text, int color = 0)
{
    return; // uncomment when release
    string[] path = getCurrentScriptName().split("/");
    string script = path[path.size()-1];
    print(script+" | ---> | "+text, colors[color]);
}

void DrawHitbox(float x, float y, float z, uint color)
{
	return; // uncomment when release
    HitBoxes.push_back(Vertex(x,	y,		z,		0,	1,	color));
	HitBoxes.push_back(Vertex(x,	y+1,	z,		1,	1,	color));
	HitBoxes.push_back(Vertex(x+1,	y+1,	z,		1,	0,	color));
	HitBoxes.push_back(Vertex(x+1,	y,		z,		0,	0,	color));

	HitBoxes.push_back(Vertex(x+1,	y,		z+1,	0,	1,	color));
	HitBoxes.push_back(Vertex(x+1,	y+1,	z+1,	1,	1,	color));
	HitBoxes.push_back(Vertex(x,	y+1,	z+1,	1,	0,	color));
	HitBoxes.push_back(Vertex(x,	y,		z+1,	0,	0,	color));

	HitBoxes.push_back(Vertex(x,	y,		z+1,	0,	1,	color));
	HitBoxes.push_back(Vertex(x,	y+1,	z+1,	1,	1,	color));
	HitBoxes.push_back(Vertex(x,	y+1,	z,		1,	0,	color));
	HitBoxes.push_back(Vertex(x,	y,		z,		0,	0,	color));

	HitBoxes.push_back(Vertex(x+1,	y,		z,		0,	1,	color));
	HitBoxes.push_back(Vertex(x+1,	y+1,	z,		1,	1,	color));
	HitBoxes.push_back(Vertex(x+1,	y+1,	z+1,	1,	0,	color));
	HitBoxes.push_back(Vertex(x+1,	y,		z+1,	0,	0,	color));

	HitBoxes.push_back(Vertex(x,	y+1,	z,		0,	1,	color));
	HitBoxes.push_back(Vertex(x,	y+1,	z+1,	1,	1,	color));
	HitBoxes.push_back(Vertex(x+1,	y+1,	z+1,	1,	0,	color));
	HitBoxes.push_back(Vertex(x+1,	y+1,	z,		0,	0,	color));

	HitBoxes.push_back(Vertex(x,	y,	z+1,	0,	1,	color));
	HitBoxes.push_back(Vertex(x,	y,	z,		1,	1,	color));
	HitBoxes.push_back(Vertex(x+1,	y,	z,		1,	0,	color));
	HitBoxes.push_back(Vertex(x+1,	y,	z+1,	0,	0,	color));
}

void DrawHitbox(AABB box, uint color)
{
	return; // uncomment when release
    HitBoxes.push_back(Vertex(box.min.x,	box.min.y,	box.min.z,	0,	1,	color));
	HitBoxes.push_back(Vertex(box.min.x,	box.max.y,	box.min.z,	1,	1,	color));
	HitBoxes.push_back(Vertex(box.max.x,	box.max.y,	box.min.z,	1,	0,	color));
	HitBoxes.push_back(Vertex(box.max.x,	box.min.y,	box.min.z,	0,	0,	color));

	HitBoxes.push_back(Vertex(box.max.x,	box.min.y,	box.max.z,	0,	1,	color));
	HitBoxes.push_back(Vertex(box.max.x,	box.max.y,	box.max.z,	1,	1,	color));
	HitBoxes.push_back(Vertex(box.min.x,	box.max.y,	box.max.z,	1,	0,	color));
	HitBoxes.push_back(Vertex(box.min.x,	box.min.y,	box.max.z,	0,	0,	color));

	HitBoxes.push_back(Vertex(box.min.x,	box.min.y,	box.max.z,	0,	1,	color));
	HitBoxes.push_back(Vertex(box.min.x,	box.max.y,	box.max.z,	1,	1,	color));
	HitBoxes.push_back(Vertex(box.min.x,	box.max.y,	box.min.z,	1,	0,	color));
	HitBoxes.push_back(Vertex(box.min.x,	box.min.y,	box.min.z,	0,	0,	color));

	HitBoxes.push_back(Vertex(box.max.x,	box.min.y,	box.min.z,	0,	1,	color));
	HitBoxes.push_back(Vertex(box.max.x,	box.max.y,	box.min.z,	1,	1,	color));
	HitBoxes.push_back(Vertex(box.max.x,	box.max.y,	box.max.z,	1,	0,	color));
	HitBoxes.push_back(Vertex(box.max.x,	box.min.y,	box.max.z,	0,	0,	color));

	HitBoxes.push_back(Vertex(box.min.x,	box.max.y,	box.min.z,	0,	1,	color));
	HitBoxes.push_back(Vertex(box.min.x,	box.max.y,	box.max.z,	1,	1,	color));
	HitBoxes.push_back(Vertex(box.max.x,	box.max.y,	box.max.z,	1,	0,	color));
	HitBoxes.push_back(Vertex(box.max.x,	box.max.y,	box.min.z,	0,	0,	color));

	HitBoxes.push_back(Vertex(box.min.x,	box.min.y,	box.max.z,	0,	1,	color));
	HitBoxes.push_back(Vertex(box.min.x,	box.min.y,	box.min.z,	1,	1,	color));
	HitBoxes.push_back(Vertex(box.max.x,	box.min.y,	box.min.z,	1,	0,	color));
	HitBoxes.push_back(Vertex(box.max.x,	box.min.y,	box.max.z,	0,	0,	color));
}

SColor[] colors = {
    0xFF8BFF60,
    0xFFFFC760,
    0xFF60B7FF,
    0xFFFF6060
};