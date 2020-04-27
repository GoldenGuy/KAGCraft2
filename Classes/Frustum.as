
#include "Plane.as"
#include "AABB.as"

class Frustum
{
	Plane plane0;
	Plane plane1;
	Plane plane2;
	Plane plane3;
	Plane plane4;
	Plane plane5;
	
	Frustum(){}
	
	void Update(const float[]&in proj_view)
	{
		// left clipping plane
		plane2.normal.x = proj_view[3] + proj_view[0];
		plane2.normal.y = proj_view[7] + proj_view[4];
		plane2.normal.z = proj_view[11] + proj_view[8];
		plane2.distance_to_origin =	proj_view[15] + proj_view[12];

		// right clipping plane
		plane3.normal.x = proj_view[3] - proj_view[0];
		plane3.normal.y = proj_view[7] - proj_view[4];
		plane3.normal.z = proj_view[11] - proj_view[8];
		plane3.distance_to_origin =	proj_view[15] - proj_view[12];

		// top clipping plane
		plane4.normal.x = proj_view[3] - proj_view[1];
		plane4.normal.y = proj_view[7] - proj_view[5];
		plane4.normal.z = proj_view[11] - proj_view[9];
		plane4.distance_to_origin =	proj_view[15] - proj_view[13];

		// bottom clipping plane
		plane5.normal.x = proj_view[3] + proj_view[1];
		plane5.normal.y = proj_view[7] + proj_view[5];
		plane5.normal.z = proj_view[11] + proj_view[9];
		plane5.distance_to_origin =	proj_view[15] + proj_view[13];

		// far clipping plane
		plane1.normal.x = proj_view[3] - proj_view[2];
		plane1.normal.y = proj_view[7] - proj_view[6];
		plane1.normal.z = proj_view[11] - proj_view[10];
		plane1.distance_to_origin =	proj_view[15] - proj_view[14];

		// near clipping plane
		plane0.normal.x = proj_view[2];
		plane0.normal.y = proj_view[6];
		plane0.normal.z = proj_view[10];
		plane0.distance_to_origin =	proj_view[14];

		plane0.Normalize();
		plane1.Normalize();
		plane2.Normalize();
		plane3.Normalize();
		plane4.Normalize();
		plane5.Normalize();
	}
	
	bool ContainsAABB(const AABB&in box)
	{
		if (!plane0.Intersects(box))
			return false;
		if (!plane1.Intersects(box))
			return false;
		if (!plane2.Intersects(box))
			return false;
		if (!plane3.Intersects(box))
			return false;
		if (!plane4.Intersects(box))
			return false;
		if (!plane5.Intersects(box))
			return false;
		return true;
	}
	
	bool ContainsPoint(const Vec3f&in point)
	{
		if (plane0.DistanceToPoint(point) < 0)
			return false;
		if (plane1.DistanceToPoint(point) < 0)
			return false;
		if (plane2.DistanceToPoint(point) < 0)
			return false;
		if (plane3.DistanceToPoint(point) < 0)
			return false;
		if (plane4.DistanceToPoint(point) < 0)
			return false;
		if (plane5.DistanceToPoint(point) < 0)
			return false;
		return true;
	}

	bool ContainsSphere(const Vec3f&in point, f32 radius)
	{
		if (plane1.DistanceToPoint(point) < -radius)
			return false;
		if (plane0.DistanceToPoint(point) < -radius)
			return false;
		if (plane2.DistanceToPoint(point) < -radius)
			return false;
		if (plane3.DistanceToPoint(point) < -radius)
			return false;
		if (plane4.DistanceToPoint(point) < -radius)
			return false;
		if (plane5.DistanceToPoint(point) < -radius)
			return false;
		return true;
	}

	// stolen from irrlicht :)
	Vec3f getFarLeftUp()
	{
		Vec3f p;
		plane1.getIntersectionWithPlanes(plane4, plane2, p);
		return p;
	}

	Vec3f getFarLeftDown()
	{
		Vec3f p;
		plane1.getIntersectionWithPlanes(plane5, plane2, p);
		return p;
	}

	Vec3f getFarRightUp()
	{
		Vec3f p;
		plane1.getIntersectionWithPlanes(plane4, plane3, p);
		return p;
	}

	Vec3f getFarRightDown()
	{
		Vec3f p;
		plane1.getIntersectionWithPlanes(plane5, plane3, p);
		return p;
	}

	Vec3f getNearLeftUp()
	{
		Vec3f p;
		plane0.getIntersectionWithPlanes(plane4, plane2, p);
		return p;
	}

	Vec3f getNearLeftDown()
	{
		Vec3f p;
		plane0.getIntersectionWithPlanes(plane5, plane2, p);
		return p;
	}

	Vec3f getNearRightUp()
	{
		Vec3f p;
		plane0.getIntersectionWithPlanes(plane4,plane3, p);
		return p;
	}

	Vec3f getNearRightDown()
	{
		Vec3f p;
		plane0.getIntersectionWithPlanes(plane5, plane3, p);
		return p;
	}
}