
#include "Plane.as"
#include "AABB.as"

class Frustum
{
	//Plane[] m_planes;

	Plane m_plane0;
	Plane m_plane1;
	Plane m_plane2;
	Plane m_plane3;
	Plane m_plane4;
	Plane m_plane5;
	
	Frustum()
	{
		//Plane[] _m_planes(6, Plane());
		//m_planes = _m_planes;
	}
	
	void Update(float[] projection, float[] view)
	{
		float[] mat = Matrix_Multiply(view, projection);
		
		// left
		m_plane2.m_normal.x	= mat[12] + mat[0];
		m_plane2.m_normal.y	= mat[13] + mat[1];
		m_plane2.m_normal.z	= mat[14] + mat[2];
		m_plane2.m_scalar	= mat[15] + mat[3];

		// right
		m_plane3.m_normal.x	= mat[12] - mat[0];
		m_plane3.m_normal.y	= mat[13] - mat[1];
		m_plane3.m_normal.z	= mat[14] - mat[2];
		m_plane3.m_scalar	= mat[15] - mat[3];

		// bottom
		m_plane5.m_normal.x	= mat[12] + mat[4];
		m_plane5.m_normal.y	= mat[13] + mat[5];
		m_plane5.m_normal.z	= mat[14] + mat[6];
		m_plane5.m_scalar	= mat[15] + mat[7];

		// top
		m_plane4.m_normal.x	= mat[12] - mat[4];
		m_plane4.m_normal.y	= mat[13] - mat[5];
		m_plane4.m_normal.z	= mat[14] - mat[6];
		m_plane4.m_scalar	= mat[15] - mat[7];

		// near
		m_plane0.m_normal.x	= mat[12] + mat[8];
		m_plane0.m_normal.y	= mat[13] + mat[9];
		m_plane0.m_normal.z	= mat[14] + mat[10];
		m_plane0.m_scalar	= mat[15] + mat[11];

		// far
		m_plane1.m_normal.x	= mat[12] - mat[8];
		m_plane1.m_normal.y	= mat[13] - mat[9];
		m_plane1.m_normal.z	= mat[14] - mat[10];
		m_plane1.m_scalar	= mat[15] - mat[11];
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