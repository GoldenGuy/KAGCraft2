
class AABB
{
	Vec3f m_min;
	Vec3f m_max;
	Vec3f m_center;
	Vec3f m_dim;
	
	AABB()
	{
		m_min = Vec3f(0,0,0);
		m_max = Vec3f(0,0,0);
		m_center = Vec3f(0,0,0);
		m_dim = Vec3f(0,0,0);
	}
	
	AABB(Vec3f min, Vec3f max)
	{
		m_min = min;
		m_max = max;
		UpdateAttributes();
	}
	
	AABB(Vec3f middle, f32 range)
	{
		m_min = middle-range;
		m_max = middle+range;
		UpdateAttributes();
	}
	
	void UpdateAttributes()
	{
		m_center = (m_max + m_min) / 2.0f;

		m_dim.x = Maths::Abs(m_max.x - m_min.x);
		m_dim.y = Maths::Abs(m_max.y - m_min.y);
		m_dim.z = Maths::Abs(m_max.z - m_min.z);
	}
}

bool testAABBAABB(AABB a, AABB b)
{
    if ( a.m_min.x > b.m_max.x || a.m_max.x < b.m_min.x ) {return false;}
    if ( a.m_min.y > b.m_max.y || a.m_max.y < b.m_min.y ) {return false;}
    if ( a.m_min.z > b.m_max.z || a.m_max.z < b.m_min.z ) {return false;}
 
    // We have an overlap
    return true;
};