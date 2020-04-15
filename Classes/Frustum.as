
#include "Plane.as"
#include "AABB.as"

class Frustum
{
	Plane m_plane0;
	Plane m_plane1;
	Plane m_plane2;
	Plane m_plane3;
	Plane m_plane4;
	Plane m_plane5;
	
	Frustum(){}
	
	void Update(float[] proj_view)
	{
		// left
		m_plane2.m_normal.x	= proj_view[12] + proj_view[0];
		m_plane2.m_normal.y	= proj_view[13] + proj_view[1];
		m_plane2.m_normal.z	= proj_view[14] + proj_view[2];
		m_plane2.m_scalar	= proj_view[15] + proj_view[3];

		// right
		m_plane3.m_normal.x	= proj_view[12] - proj_view[0];
		m_plane3.m_normal.y	= proj_view[13] - proj_view[1];
		m_plane3.m_normal.z	= proj_view[14] - proj_view[2];
		m_plane3.m_scalar	= proj_view[15] - proj_view[3];

		// bottom
		m_plane5.m_normal.x	= proj_view[12] + proj_view[4];
		m_plane5.m_normal.y	= proj_view[13] + proj_view[5];
		m_plane5.m_normal.z	= proj_view[14] + proj_view[6];
		m_plane5.m_scalar	= proj_view[15] + proj_view[7];

		// top
		m_plane4.m_normal.x	= proj_view[12] - proj_view[4];
		m_plane4.m_normal.y	= proj_view[13] - proj_view[5];
		m_plane4.m_normal.z	= proj_view[14] - proj_view[6];
		m_plane4.m_scalar	= proj_view[15] - proj_view[7];

		// near
		m_plane0.m_normal.x	= proj_view[12] + proj_view[8];
		m_plane0.m_normal.y	= proj_view[13] + proj_view[9];
		m_plane0.m_normal.z	= proj_view[14] + proj_view[10];
		m_plane0.m_scalar	= proj_view[15] + proj_view[11];

		// far
		m_plane1.m_normal.x	= proj_view[12] - proj_view[8];
		m_plane1.m_normal.y	= proj_view[13] - proj_view[9];
		m_plane1.m_normal.z	= proj_view[14] - proj_view[10];
		m_plane1.m_scalar	= proj_view[15] - proj_view[11];
	}
	
	bool ContainsAABB(AABB box)
	{
		if (!m_plane0.Intersects(box))
			return false;
		if (!m_plane1.Intersects(box))
			return false;
		if (!m_plane2.Intersects(box))
			return false;
		if (!m_plane3.Intersects(box))
			return false;
		if (!m_plane4.Intersects(box))
			return false;
		if (!m_plane5.Intersects(box))
			return false;
		return true;
	}
	
	bool ContainsPoint(Vec3f point)
	{
		if (m_plane0.DistanceFromPoint(point) < 0)
			return false;
		if (m_plane1.DistanceFromPoint(point) < 0)
			return false;
		if (m_plane2.DistanceFromPoint(point) < 0)
			return false;
		if (m_plane3.DistanceFromPoint(point) < 0)
			return false;
		if (m_plane4.DistanceFromPoint(point) < 0)
			return false;
		if (m_plane5.DistanceFromPoint(point) < 0)
			return false;
		return true;
	}

	bool ContainsSphere(Vec3f point, f32 radius)
	{
		if (m_plane0.DistanceFromPoint(point) < -radius)
			return false;
		if (m_plane1.DistanceFromPoint(point) < -radius)
			return false;
		if (m_plane2.DistanceFromPoint(point) < -radius)
			return false;
		if (m_plane3.DistanceFromPoint(point) < -radius)
			return false;
		if (m_plane4.DistanceFromPoint(point) < -radius)
			return false;
		if (m_plane5.DistanceFromPoint(point) < -radius)
			return false;
		return true;
	}
}