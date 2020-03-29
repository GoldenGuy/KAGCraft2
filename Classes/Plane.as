
class Plane
{
	Vec3f m_normal;
	float m_scalar;
	
	Plane()
	{
		m_normal = Vec3f(0,0,0);
		m_scalar = 0.0f;
	}

	Plane(Plane plane)
	{
		m_normal = plane.m_normal;
		m_scalar = plane.m_scalar;
	}

	Plane(float x, float y, float z, float scalar)
	{
		m_normal = Vec3f(x, y, z);
		m_scalar = scalar;
	}
	
	bool Intersects(AABB box)
	{
		float d = DotProduct(box.m_center, m_normal);
		float r = box.m_dim.x * Maths::Abs(m_normal.x) + box.m_dim.y * Maths::Abs(m_normal.y) + box.m_dim.z * Maths::Abs(m_normal.z);
		float dpr = d + r;

		if (dpr < -m_scalar)
			return false;
		return true;
	}
	
	float DistanceFromPoint(Vec3f point)
	{
		return DotProduct(m_normal, point) + m_scalar;
	}
	
	void SetAndNormalize(Vec3f normal, float scalar)
	{
		float length = normal.Length();

		m_normal = normal / length;
		m_scalar = scalar / length;
	}
}