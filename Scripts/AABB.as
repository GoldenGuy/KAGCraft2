
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

	bool intersectsWithLine(Vec3f ray_pos, Vec3f ray_dir, float ray_dist)
	{
	    Vec3f ray_end = ray_pos+ray_dir*ray_dist;
		Vec3f ray_middle = (ray_end+ray_pos)/2.0f;

		Vec3f e = (max-min) * 0.5f;
	    Vec3f t = (min+max)/2.0f - ray_middle;

		float half_dist = ray_dist/2.0f;

	    if ((Maths::Abs(t.x) > e.x + half_dist * Maths::Abs(ray_dir.x)) ||
	        (Maths::Abs(t.y) > e.y + half_dist * Maths::Abs(ray_dir.y)) ||
	        (Maths::Abs(t.z) > e.z + half_dist * Maths::Abs(ray_dir.z)) )
	        return false;

	    float r = e.y * Maths::Abs(ray_dir.z) + e.z * Maths::Abs(ray_dir.y);
	    if (Maths::Abs(t.y*ray_dir.z - t.z*ray_dir.y) > r )
	        return false;

	    r = e.x * Maths::Abs(ray_dir.z) + e.z * Maths::Abs(ray_dir.x);
	    if (Maths::Abs(t.z*ray_dir.x - t.x*ray_dir.z) > r )
	        return false;

	    r = e.x * Maths::Abs(ray_dir.y) + e.y * Maths::Abs(ray_dir.x);
	    if (Maths::Abs(t.x*ray_dir.y - t.y*ray_dir.x) > r)
	        return false;

	    return true;
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