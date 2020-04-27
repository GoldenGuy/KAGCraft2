
class Plane
{
	Vec3f normal;
	float distance_to_origin;
	
	Plane()
	{
		normal = Vec3f(0,0,0);
		distance_to_origin = 0.0f;
	}

	Plane(float x, float y, float z, float scalar)
	{
		normal = Vec3f(x, y, z);
		distance_to_origin = scalar;
	}
	
	bool Intersects(const AABB&in box)
	{
		float d = DotProduct(box.center, normal);
		float r = box.dim.x * Maths::Abs(normal.x) + box.dim.y * Maths::Abs(normal.y) + box.dim.z * Maths::Abs(normal.z);
		float dpr = d + r;

		if (dpr < -distance_to_origin)
			return false;
		return true;
	}
	
	float DistanceToPoint(const Vec3f&in point)
	{
		return DotProduct(normal, point) + distance_to_origin;
	}
	
	void SetAndNormalize(const Vec3f&in _normal, float _distance_to_origin)
	{
		float length = _normal.Length();

		normal = normal / length;
		distance_to_origin = _distance_to_origin / length;
	}

	void Normalize()
	{
		float length = normal.Length();

		normal /= length;
		distance_to_origin /= length;
	}

	// stolen from irrlicht
	bool getIntersectionWithPlane(const Plane&in other, Vec3f&out LinePoint, Vec3f&out LineVect)
	{
		float fn00 = normal.Length();
		float fn01 = DotProduct(normal, other.normal);
		float fn11 = other.normal.Length();
		float det = fn00*fn11 - fn01*fn01;

		if (Maths::Abs(det) < 0.0000001f)
			return false;

		float invdet = 1.0 / det;
		float fc0 = (fn11*-distance_to_origin + fn01*other.distance_to_origin) * invdet;
		float fc1 = (fn00*-other.distance_to_origin + fn01*distance_to_origin) * invdet;

		LineVect = CrossProduct(normal, other.normal);
		LinePoint = normal*fc0 + other.normal*fc1;
		return true;
	}

	bool getIntersectionWithPlanes(const Plane&in o1, const Plane&in o2, Vec3f&out Point)
	{
		Vec3f linePoint, lineVect;
		if (getIntersectionWithPlane(o1, linePoint, lineVect))
		{
			return o2.getIntersectionWithLine(linePoint, lineVect, Point);
		}
		return false;
	}

	bool getIntersectionWithLine(const Vec3f&in linePoint, const Vec3f&in lineVect, Vec3f&out Intersection) const
	{
		float t2 = DotProduct(normal, lineVect);

		if (t2 == 0)
		{
			return false;
		}

		float t =- (DotProduct(normal, linePoint) + distance_to_origin) / t2;
		Intersection = linePoint + (lineVect * t);
		return true;
	}
}