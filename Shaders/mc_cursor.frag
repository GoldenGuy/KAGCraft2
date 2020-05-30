uniform sampler2D baseMap; 
uniform float screenWidth;
uniform float screenHeight;

vec3 iResolution = vec3(screenWidth,screenHeight,0.0);

#define RES iResolution.xy

bool cursor(vec2 p)
{
	bool vertLineY = (p.y > (screenHeight/2. - 8) && p.y < (screenHeight/2. + 8));
	bool horizLineY = (p.y > (screenHeight/2. - 1) && p.y < (screenHeight/2. + 1));
	
	bool vertLineX = (p.x > (screenWidth/2. - 1) && p.x < (screenWidth/2. + 1));
	bool horizLineX = (p.x > (screenWidth/2. - 8) && p.x < (screenWidth/2. + 8));
	
	if((vertLineY && vertLineX) || (horizLineY && horizLineX))
		return true;
	return false;
}

void main()
{
	vec2 uv2 = gl_FragCoord.xy / RES;
	vec4 uv = vec4( uv2, uv2 - (1./RES * 0.8));
	
	vec3 col;
	if(cursor(gl_FragCoord.xy))
	{
		col = texture2D(baseMap, uv).rgb;
		col = vec3(1.-col.r, 1.-col.b, 1.-col.g);
	}
	else
		col = texture2D(baseMap, uv).rgb;

	gl_FragColor = vec4( col, 1. );
}