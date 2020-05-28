
Vertex[] block_mouse = {
		Vertex(-0.02f,	-0.02f,	-0.02f,	0,	1,	color_white),
		Vertex(-0.02f,	1.02f,	-0.02f,	0,	0,	color_white),
		Vertex(1.02f,	1.02f,	-0.02f,	1,	0,	color_white),
		Vertex(1.02f,	-0.02f,	-0.02f,	1,	1,	color_white),

		Vertex(1.02f,	-0.02f,	1.02f,	0,	1,	color_white),
		Vertex(1.02f,	1.02f,	1.02f,	0,	0,	color_white),
		Vertex(-0.02f,	1.02f,	1.02f,	1,	0,	color_white),
		Vertex(-0.02f,	-0.02f,	1.02f,	1,	1,	color_white),

		Vertex(-0.02f,	-0.02f,	1.02f,	0,	1,	color_white),
		Vertex(-0.02f,	1.02f,	1.02f,	0,	0,	color_white),
		Vertex(-0.02f,	1.02f,	-0.02f,	1,	0,	color_white),
		Vertex(-0.02f,	-0.02f,	-0.02f,	1,	1,	color_white),

		Vertex(1.02f,	-0.02f,	-0.02f,	0,	1,	color_white),
		Vertex(1.02f,	1.02f,	-0.02f,	0,	0,	color_white),
		Vertex(1.02f,	1.02f,	1.02f,	1,	0,	color_white),
		Vertex(1.02f,	-0.02f,	1.02f,	1,	1,	color_white),

		Vertex(-0.02f,	1.02f,	-0.02f,	0,	1,	color_white),
		Vertex(-0.02f,	1.02f,	1.02f,	0,	0,	color_white),
		Vertex(1.02f,	1.02f,	1.02f,	1,	0,	color_white),
		Vertex(1.02f,	1.02f,	-0.02f,	1,	1,	color_white),

		Vertex(-0.02f,	-0.02f,	1.02f,	0,	1,	color_white),
		Vertex(-0.02f,	-0.02f,	-0.02f,	0,	0,	color_white),
		Vertex(1.02f,	-0.02f,	-0.02f,	1,	0,	color_white),
		Vertex(1.02f,	-0.02f,	1.02f,	1,	1,	color_white)
};

Vertex[] player_head = {
		Vertex(0.25f,	0.5f,	0.25f,		0.125,	0.25,	color_white),	// front
		Vertex(-0.25f,	0.5f,	0.25f,		0.25,	0.25,	color_white),
		Vertex(-0.25f,	0.0f,	0.25f,		0.25,	0.5,	color_white),
		Vertex(0.25f,	0.0f,	0.25f,		0.125,	0.5,	color_white),

		Vertex(-0.25f,	0.5f,	-0.25f,		0.375,	0.25,	color_white),	// back
		Vertex(0.25f,	0.5f,	-0.25f,		0.5,	0.25,	color_white),
		Vertex(0.25f,	0.0f,	-0.25f,		0.5,	0.5,	color_white),
		Vertex(-0.25f,	0.0f,	-0.25f,		0.375,	0.5,	color_white),

		Vertex(0.25f,	0.5f,	-0.25f,		0.125,	0.0,	color_white),	// top
		Vertex(-0.25f,	0.5f,	-0.25f,		0.25,	0.0,	color_white),
		Vertex(-0.25f,	0.5f,	0.25f,		0.25,	0.25,	color_white),
		Vertex(0.25f,	0.5f,	0.25f,		0.125,	0.25,	color_white),

		Vertex(-0.25f,	0.0f,	-0.25f,		0.25,	0.0,	color_white),	// bottom
		Vertex(0.25f,	0.0f,	-0.25f,		0.375,	0.0,	color_white),
		Vertex(0.25f,	0.0f,	0.25f,		0.375,	0.25,	color_white),
		Vertex(-0.25f,	0.0f,	0.25f,		0.25,	0.25,	color_white),

		Vertex(0.25f,	0.5f,	-0.25f,		0.0,	0.25,	color_white),	// left
		Vertex(0.25f,	0.5f,	0.25f,		0.125,	0.25,	color_white),
		Vertex(0.25f,	0.0f,	0.25f,		0.125,	0.5,	color_white),
		Vertex(0.25f,	0.0f,	-0.25f,		0.0,	0.5,	color_white),

		Vertex(-0.25f,	0.5f,	0.25f,		0.25,	0.25,	color_white),	// right
		Vertex(-0.25f,	0.5f,	-0.25f,		0.375,	0.25,	color_white),
		Vertex(-0.25f,	0.0f,	-0.25f,		0.375,	0.5,	color_white),
		Vertex(-0.25f,	0.0f,	0.25f,		0.25,	0.5,	color_white)
};

Vertex[] player_head_jenny = {
	    Vertex(0.25f,	0.5f,	0.25f,		0.125,	0.25,	color_white),	// front
	    Vertex(-0.25f,	0.5f,	0.25f,		0.25,	0.25,	color_white),
	    Vertex(-0.25f,	0.0f,	0.25f,		0.25,	0.5,	color_white),
	    Vertex(0.25f,	0.0f,	0.25f,		0.125,	0.5,	color_white),

	    Vertex(-0.25f,	0.5f,	-0.25f,		0.375,	0.25,	color_white),	// back
	    Vertex(0.25f,	0.5f,	-0.25f,		0.5,	0.25,	color_white),
	    Vertex(0.25f,	0.0f,	-0.25f,		0.5,	0.5,	color_white),
	    Vertex(-0.25f,	0.0f,	-0.25f,		0.375,	0.5,	color_white),

	    Vertex(0.25f,	0.5f,	-0.25f,		0.125,	0.0,	color_white),	// top
	    Vertex(-0.25f,	0.5f,	-0.25f,		0.25,	0.0,	color_white),
	    Vertex(-0.25f,	0.5f,	0.25f,		0.25,	0.25,	color_white),
	    Vertex(0.25f,	0.5f,	0.25f,		0.125,	0.25,	color_white),

	    Vertex(-0.25f,	0.0f,	-0.25f,		0.25,	0.0,	color_white),	// bottom
	    Vertex(0.25f,	0.0f,	-0.25f,		0.375,	0.0,	color_white),
	    Vertex(0.25f,	0.0f,	0.25f,		0.375,	0.25,	color_white),
	    Vertex(-0.25f,	0.0f,	0.25f,		0.25,	0.25,	color_white),

	    Vertex(0.25f,	0.5f,	-0.25f,		0.0,	0.25,	color_white),	// left
	    Vertex(0.25f,	0.5f,	0.25f,		0.125,	0.25,	color_white),
	    Vertex(0.25f,	0.0f,	0.25f,		0.125,	0.5,	color_white),
	    Vertex(0.25f,	0.0f,	-0.25f,		0.0,	0.5,	color_white),

	    Vertex(-0.25f,	0.5f,	0.25f,		0.25,	0.25,	color_white),	// right
	    Vertex(-0.25f,	0.5f,	-0.25f,		0.375,	0.25,	color_white),
	    Vertex(-0.25f,	0.0f,	-0.25f,		0.375,	0.5,	color_white),
	    Vertex(-0.25f,	0.0f,	0.25f,		0.25,	0.5,	color_white),

	    Vertex(0.6f,	0.65f,	-0.25f,		0.5,	0.25,	color_white),	// left hair
	    Vertex(0.1f,	0.65f,	-0.125f,	0.625,	0.25,	color_white),
	    Vertex(0.1f,	0.25f,	-0.125f,	0.625,	0.5,	color_white),
	    Vertex(0.6f,	0.25f,	-0.25f,		0.5,	0.5,	color_white),

	    Vertex(-0.1f,	0.65f,	-0.125f,	0.75,	0.25,	color_white),	// right hair
	    Vertex(-0.6f,	0.65f,	-0.25f,		0.875,	0.25,	color_white),
	    Vertex(-0.6f,	0.25f,	-0.25f,		0.875,	0.5,	color_white),
	    Vertex(-0.1f,	0.25f,	-0.125f,	0.75,	0.5,	color_white)
};

Vertex[] player_body = {
        Vertex(0.25f,	1.5f,	0.125f,		0.3125,	0.625,	color_white),	// front
        Vertex(-0.25f,	1.5f,	0.125f,		0.4375,	0.625,	color_white),
        Vertex(-0.25f,	0.75f,	0.125f,		0.4375,	1,		color_white),
        Vertex(0.25f,	0.75f,	0.125f,		0.3125,	1,		color_white),

        Vertex(-0.25f,	1.5f,	-0.125f,	0.5,	0.625,	color_white),	// back
        Vertex(0.25f,	1.5f,	-0.125f,	0.625,	0.625,	color_white),
        Vertex(0.25f,	0.75f,	-0.125f,	0.625,	1,		color_white),
        Vertex(-0.25f,	0.75f,	-0.125f,	0.5,	1,		color_white),

        Vertex(0.25f,	1.5f,	-0.125f,	0.3125,	0.5,	color_white),	// top
        Vertex(-0.25f,	1.5f,	-0.125f,	0.4375,	0.5,	color_white),
        Vertex(-0.25f,	1.5f,	0.125f,		0.4375,	0.625,	color_white),
        Vertex(0.25f,	1.5f,	0.125f,		0.3125,	0.625,	color_white),

        Vertex(-0.25f,	0.75f,	-0.125f,	0.4375,	0.5,	color_white),	// bottom
        Vertex(0.25f,	0.75f,	-0.125f,	0.5625,	0.5,	color_white),
        Vertex(0.25f,	0.75f,	0.125f,		0.5625,	0.625,	color_white),
        Vertex(-0.25f,	0.75f,	0.125f,		0.4375,	0.625,	color_white),

        Vertex(0.25f,	1.5f,	-0.125f,	0.25,	0.625,	color_white),	// left
        Vertex(0.25f,	1.5f,	0.125f,		0.3125,	0.625,	color_white),
        Vertex(0.25f,	0.75f,	0.125f,		0.3125,	1,		color_white),
        Vertex(0.25f,	0.75f,	-0.125f,	0.25,	1,		color_white),

        Vertex(-0.25f,	1.5f,	0.125f,		0.4375,	0.625,	color_white),	// right
        Vertex(-0.25f,	1.5f,	-0.125f,	0.5,	0.625,	color_white),
        Vertex(-0.25f,	0.75f,	-0.125f,	0.5,	1,		color_white),
        Vertex(-0.25f,	0.75f,	0.125f,		0.4375,	1,		color_white)
};

Vertex[] player_arm_right = {
		Vertex(0.5f,	0.0f,	0.125f,		0.6875,	0.625,	color_white),	// front
		Vertex(0.25f,	0.0f,	0.125f,		0.75,	0.625,	color_white),
		Vertex(0.25f,	-0.75f,	0.125f,		0.75,	1,		color_white),
		Vertex(0.5f,	-0.75f,	0.125f,		0.6875,	1,		color_white),

		Vertex(0.25f,	0.0f,	-0.125f,	0.8125,	0.625,	color_white),	// back
		Vertex(0.5f,	0.0f,	-0.125f,	0.875,	0.625,	color_white),
		Vertex(0.5f,	-0.75f,	-0.125f,	0.875,	1,		color_white),
		Vertex(0.25f,	-0.75f,	-0.125f,	0.8125,	1,		color_white),

		Vertex(0.5f,	0.0f,	-0.125f,	0.6875,	0.5,	color_white),	// top
		Vertex(0.25f,	0.0f,	-0.125f,	0.75,	0.5,	color_white),
		Vertex(0.25f,	0.0f,	0.125f,		0.75,	0.625,	color_white),
		Vertex(0.5f,	0.0f,	0.125f,		0.6875,	0.625,	color_white),

		Vertex(0.25f,	-0.75f,	-0.125f,	0.75,	0.5,	color_white),	// bottom
		Vertex(0.5f,	-0.75f,	-0.125f,	0.8125,	0.5,	color_white),
		Vertex(0.5f,	-0.75f,	0.125f,		0.8125,	0.625,	color_white),
		Vertex(0.25f,	-0.75f,	0.125f,		0.75,	0.625,	color_white),

		Vertex(0.5f,	0.0f,	-0.125f,	0.625,	0.625,	color_white),	// left
		Vertex(0.5f,	0.0f,	0.125f,		0.6875,	0.625,	color_white),
		Vertex(0.5f,	-0.75f,	0.125f,		0.6875,	1,		color_white),
		Vertex(0.5f,	-0.75f,	-0.125f,	0.625,	1,		color_white),

		Vertex(0.25f,	0.0f,	0.125f,		0.75,	0.625,	color_white),	// right
		Vertex(0.25f,	0.0f,	-0.125f,	0.8125,	0.625,	color_white),
		Vertex(0.25f,	-0.75f,	-0.125f,	0.8125,	1,		color_white),
		Vertex(0.25f,	-0.75f,	0.125f,		0.75,	1,		color_white)
};
						
Vertex[] player_arm_left = {
		Vertex(-0.25f,	0.0f,	0.125f,		0.75,	0.625,	color_white),	// front
		Vertex(-0.5f,	0.0f,	0.125f,		0.6875,	0.625,	color_white),
		Vertex(-0.5f,	-0.75f,	0.125f,		0.6875,	1,		color_white),
		Vertex(-0.25f,	-0.75f,	0.125f,		0.75,	1,		color_white),

		Vertex(-0.5f,	0.0f,	-0.125f,	0.875,	0.625,	color_white),	// back
		Vertex(-0.25f,	0.0f,	-0.125f,	0.8125,	0.625,	color_white),
		Vertex(-0.25f,	-0.75f,	-0.125f,	0.8125,	1,		color_white),
		Vertex(-0.5f,	-0.75f,	-0.125f,	0.875,	1,		color_white),

		Vertex(-0.25f,	0.0f,	-0.125f,	0.75,	0.5,	color_white),	// top
		Vertex(-0.5f,	0.0f,	-0.125f,	0.6875,	0.5,	color_white),
		Vertex(-0.5f,	0.0f,	0.125f,		0.6875,	0.625,	color_white),
		Vertex(-0.25f,	0.0f,	0.125f,		0.75,	0.625,	color_white),

		Vertex(-0.5f,	-0.75f,	-0.125f,	0.8125,	0.5,	color_white),	// bottom
		Vertex(-0.25f,	-0.75f,	-0.125f,	0.75,	0.5,	color_white),
		Vertex(-0.25f,	-0.75f,	0.125f,		0.75,	0.625,	color_white),
		Vertex(-0.5f,	-0.75f,	0.125f,		0.8125,	0.625,	color_white),

		Vertex(-0.25f,	0.0f,	-0.125f,	0.8125,	0.625,	color_white),	// left
		Vertex(-0.25f,	0.0f,	0.125f,		0.75,	0.625,	color_white),
		Vertex(-0.25f,	-0.75f,	0.125f,		0.75,	1,		color_white),
		Vertex(-0.25f,	-0.75f,	-0.125f,	0.8125,	1,		color_white),

		Vertex(-0.5f,	0.0f,	0.125f,		0.6875,	0.625,	color_white),	// right
		Vertex(-0.5f,	0.0f,	-0.125f,	0.625,	0.625,	color_white),
		Vertex(-0.5f,	-0.75f,	-0.125f,	0.625,	1,		color_white),
		Vertex(-0.5f,	-0.75f,	0.125f,		0.6875,	1,		color_white)
};

Vertex[] player_leg_right = {
		Vertex(0.25f,	0.0f,	0.125f,		0.0625,	0.625,	color_white),	// front
		Vertex(0.0f,	0.0f,	0.125f,		0.125,	0.625,	color_white),
		Vertex(0.0f,	-0.75f,	0.125f,		0.125,	1,		color_white),
		Vertex(0.25f,	-0.75f,	0.125f,		0.0625,	1,		color_white),

		Vertex(0.0f,	0.0f,	-0.125f,	0.1875,	0.625,	color_white),	// back
		Vertex(0.25f,	0.0f,	-0.125f,	0.25,	0.625,	color_white),
		Vertex(0.25f,	-0.75f,	-0.125f,	0.25,	1,		color_white),
		Vertex(0.0f,	-0.75f,	-0.125f,	0.1875,	1,		color_white),

		Vertex(0.25f,	0.0f,	-0.125f,	0.0625,	0.5,	color_white),	// top
		Vertex(0.0f,	0.0f,	-0.125f,	0.125,	0.5,	color_white),
		Vertex(0.0f,	0.0f,	0.125f,		0.125,	0.625,	color_white),
		Vertex(0.25f,	0.0f,	0.125f,		0.0625,	0.625,	color_white),

		Vertex(0.0f,	-0.75f,	-0.125f,	0.125,	0.5,	color_white),	// bottom
		Vertex(0.25f,	-0.75f,	-0.125f,	0.1875,	0.5,	color_white),
		Vertex(0.25f,	-0.75f,	0.125f,		0.1875,	0.625,	color_white),
		Vertex(0.0f,	-0.75f,	0.125f,		0.125,	0.625,	color_white),

		Vertex(0.25f,	0.0f,	-0.125f,	0.0,	0.625,	color_white),	// left
		Vertex(0.25f,	0.0f,	0.125f,		0.0625,	0.625,	color_white),
		Vertex(0.25f,	-0.75f,	0.125f,		0.0625,	1,		color_white),
		Vertex(0.25f,	-0.75f,	-0.125f,	0.0,	1,		color_white),

		Vertex(0.0f,	0.0f,	0.125f,		0.125,	0.625,	color_white),	// right
		Vertex(0.0f,	0.0f,	-0.125f,	0.1875,	0.625,	color_white),
		Vertex(0.0f,	-0.75f,	-0.125f,	0.1875,	1,		color_white),
		Vertex(0.0f,	-0.75f,	0.125f,		0.125,	1,		color_white)
};
						
Vertex[] player_leg_left = {
		Vertex(0.0f,	0.0f,	0.125f,		0.125,	0.625,	color_white),	// front
		Vertex(-0.25f,	0.0f,	0.125f,		0.0625,	0.625,	color_white),
		Vertex(-0.25f,	-0.75f,	0.125f,		0.0625,	1,		color_white),
		Vertex(0.0f,	-0.75f,	0.125f,		0.125,	1,		color_white),

		Vertex(-0.25f,	0.0f,	-0.125f,	0.25,	0.625,	color_white),	// back
		Vertex(0.0f,	0.0f,	-0.125f,	0.1875,	0.625,	color_white),
		Vertex(0.0f,	-0.75f,	-0.125f,	0.1875,	1,		color_white),
		Vertex(-0.25f,	-0.75f,	-0.125f,	0.25,	1,		color_white),

		Vertex(0.0f,	0.0f,	-0.125f,	0.125,	0.5,	color_white),	// top
		Vertex(-0.25f,	0.0f,	-0.125f,	0.0625,	0.5,	color_white),
		Vertex(-0.25f,	0.0f,	0.125f,		0.0625,	0.625,	color_white),
		Vertex(0.0f,	0.0f,	0.125f,		0.125,	0.625,	color_white),

		Vertex(-0.25f,	-0.75f,	-0.125f,	0.1875,	0.5,	color_white),	// bottom
		Vertex(0.0f,	-0.75f,	-0.125f,	0.125,	0.5,	color_white),
		Vertex(0.0f,	-0.75f,	0.125f,		0.125,	0.625,	color_white),
		Vertex(-0.25f,	-0.75f,	0.125f,		0.1875,	0.625,	color_white),

		Vertex(0.0f,	0.0f,	-0.125f,	0.1875,	0.625,	color_white),	// left
		Vertex(0.0f,	0.0f,	0.125f,		0.125,	0.625,	color_white),
		Vertex(0.0f,	-0.75f,	0.125f,		0.125,	1,		color_white),
		Vertex(0.0f,	-0.75f,	-0.125f,	0.1875,	1,		color_white),

		Vertex(-0.25f,	0.0f,	0.125f,		0.0625,	0.625,	color_white),	// right
		Vertex(-0.25f,	0.0f,	-0.125f,	0.0,	0.625,	color_white),
		Vertex(-0.25f,	-0.75f,	-0.125f,	0.0,	1,		color_white),
		Vertex(-0.25f,	-0.75f,	0.125f,		0.0625,	1,		color_white)
};

u16[] player_IDs = {
    0, 1, 2, 0, 2, 3,
    4, 5, 6, 4, 6, 7,
    8, 9, 10, 8, 10, 11,
    12, 13, 14, 12, 14, 15,
    16, 17, 18, 16, 18, 19,
    20, 21, 22, 20, 22, 23
};