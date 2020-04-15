
class Plane
{
	Vec3f normal;
	float distance_to_origin;
	
	Plane()
	{
		normal = Vec3f(0,0,0);
		distance_to_origin = 0.0f;
	}

	Plane(Plane plane)
	{
		normal = plane.normal;
		distance_to_origin = plane.distance_to_origin;
	}

	Plane(float x, float y, float z, float scalar)
	{
		normal = Vec3f(x, y, z);
		distance_to_origin = scalar;
	}
	
	bool Intersects(AABB box) // fake, just checks sphere with 
	{
		float d = DotProduct(box.m_center, normal);
		float r = box.m_dim.x * Maths::Abs(normal.x) + box.m_dim.y * Maths::Abs(normal.y) + box.m_dim.z * Maths::Abs(normal.z);
		float dpr = d + r;

		if (dpr < -distance_to_origin)
			return false;
		return true;
	}
	
	float DistanceToPoint(Vec3f point)
	{
		return DotProduct(normal, point) + distance_to_origin;
	}
	
	void SetAndNormalize(Vec3f normal, float scalar)
	{
		float length = normal.Length();

		normal = normal / length;
		distance_to_origin = scalar / length;
	}
}