
class AABB
{
	Vec3f min;
	Vec3f max;
	Vec3f center;
	Vec3f dim;
	f32 corner; // radius of a sphere, that is outside the box and collides with each corner
	
	AABB()
	{
		min = Vec3f(0, 0, 0);
		max = Vec3f(0, 0, 0);
		center = Vec3f(0, 0, 0);
		dim = Vec3f(0, 0, 0);
	}
	
	AABB(const Vec3f&in _min, const Vec3f&in _max)
	{
		min = _min;
		max = _max;
		UpdateAttributes();
	}
	
	AABB(const Vec3f&in middle, float range)
	{
		min = middle-range;
		max = middle+range;
		UpdateAttributes();
	}

	AABB opAdd(const Vec3f&in oof) { return AABB(min + oof, max + oof); }
	AABB opSub(const Vec3f&in oof) { return AABB(min - oof, max - oof); }
	
	void UpdateAttributes()
	{
		dim.x = Maths::Abs(max.x - min.x);
		dim.y = Maths::Abs(max.y - min.y);
		dim.z = Maths::Abs(max.z - min.z);

		center = dim / 2.0f + min;

		corner = Maths::Pow( Maths::Pow(dim.x, 3) + Maths::Pow(dim.y, 3) + Maths::Pow(dim.z, 3), 1.0f / 3.0f) * 0.6f;
	}
}

bool testAABBAABB(const AABB&in a, const AABB&in b)
{
    if ( a.min.x > b.max.x || a.max.x < b.min.x ) {return false;}
    if ( a.min.y > b.max.y || a.max.y < b.min.y ) {return false;}
    if ( a.min.z > b.max.z || a.max.z < b.min.z ) {return false;}
 
    // We have an overlap
    return true;
};