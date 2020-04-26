
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
	
	bool Intersects(AABB box)
	{
		float d = DotProduct(box.center, normal);
		float r = box.dim.x * Maths::Abs(normal.x) + box.dim.y * Maths::Abs(normal.y) + box.dim.z * Maths::Abs(normal.z);
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

	void Normalize()
	{
		float length = normal.Length();

		normal /= length;
		distance_to_origin /= length;
	}

	// stolen from irrlicht
	bool getIntersectionWithPlane(Plane other, Vec3f&out LinePoint, Vec3f&out LineVect)
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

	bool getIntersectionWithPlanes(Plane o1, Plane o2, Vec3f&out Point)
	{
		Vec3f linePoint, lineVect;
		if (getIntersectionWithPlane(o1, linePoint, lineVect))
		{
			//print("inter with 2 planes");
			return o2.getIntersectionWithLine(linePoint, lineVect, Point);
		}
			

		return false;
	}

	bool getIntersectionWithLine(Vec3f linePoint, Vec3f lineVect, Vec3f&out Intersection)
	{
		float t2 = DotProduct(normal, lineVect);
		//print("normal: "+normal.FloatString());
		//print("normal: "+lineVect.FloatString());

		if (t2 == 0)
			return false;

		float t =- (DotProduct(normal, linePoint) + distance_to_origin) / t2;
		Intersection = linePoint + (lineVect * t);
		return true;
	}
}