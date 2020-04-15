
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
	
	void Update(float[] proj_view)
	{
		// near
		plane0.normal.x	= proj_view[12] + proj_view[8];
		plane0.normal.y	= proj_view[13] + proj_view[9];
		plane0.normal.z	= proj_view[14] + proj_view[10];
		plane0.distance_to_origin = proj_view[15] + proj_view[11];

		// far
		plane1.normal.x	= proj_view[12] - proj_view[8];
		plane1.normal.y	= proj_view[13] - proj_view[9];
		plane1.normal.z	= proj_view[14] - proj_view[10];
		plane1.distance_to_origin = proj_view[15] - proj_view[11];
		
		// left
		plane2.normal.x	= proj_view[12] + proj_view[0];
		plane2.normal.y	= proj_view[13] + proj_view[1];
		plane2.normal.z	= proj_view[14] + proj_view[2];
		plane2.distance_to_origin = proj_view[15] + proj_view[3];

		// right
		plane3.normal.x	= proj_view[12] - proj_view[0];
		plane3.normal.y	= proj_view[13] - proj_view[1];
		plane3.normal.z	= proj_view[14] - proj_view[2];
		plane3.distance_to_origin = proj_view[15] - proj_view[3];

		// top
		plane4.normal.x	= proj_view[12] - proj_view[4];
		plane4.normal.y	= proj_view[13] - proj_view[5];
		plane4.normal.z	= proj_view[14] - proj_view[6];
		plane4.distance_to_origin = proj_view[15] - proj_view[7];

		// bottom
		plane5.normal.x	= proj_view[12] + proj_view[4];
		plane5.normal.y	= proj_view[13] + proj_view[5];
		plane5.normal.z	= proj_view[14] + proj_view[6];
		plane5.distance_to_origin = proj_view[15] + proj_view[7];
	}
	
	bool ContainsAABB(AABB box)
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
	
	bool ContainsPoint(Vec3f point)
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

	bool ContainsSphere(Vec3f point, f32 radius)
	{
		if (plane1.DistanceToPoint(point)*cam.z_far*10 < -radius) // -0.005
			return false;
		//if (plane0.DistanceToPoint(point) < -radius)
		//	return false;
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
}