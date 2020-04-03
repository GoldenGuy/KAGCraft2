
#include "Plane.as"
#include "AABB.as"

const f32 MAGIC_VALUE = -6;

class Frustum
{
	Plane[] m_planes;
	
	Frustum()
	{
		Plane[] _m_planes(6, Plane());
		m_planes = _m_planes;
	}
	
	void Update(float[] projection, float[] view)
	{
		float[] mat;// = Matrix_Multiply(view, projection);
        Matrix::Multiply(view, projection, mat);
		
		// left
		m_planes[2].m_normal.x	= mat[12] + mat[0];
		m_planes[2].m_normal.y	= mat[13] + mat[1];
		m_planes[2].m_normal.z	= mat[14] + mat[2];
		m_planes[2].m_scalar	= mat[15] + mat[3];

		// right
		m_planes[3].m_normal.x	= mat[12] - mat[0];
		m_planes[3].m_normal.y	= mat[13] - mat[1];
		m_planes[3].m_normal.z	= mat[14] - mat[2];
		m_planes[3].m_scalar	= mat[15] - mat[3];

		// bottom
		m_planes[5].m_normal.x	= mat[12] + mat[4];
		m_planes[5].m_normal.y	= mat[13] + mat[5];
		m_planes[5].m_normal.z	= mat[14] + mat[6];
		m_planes[5].m_scalar	= mat[15] + mat[7];

		// top
		m_planes[4].m_normal.x	= mat[12] - mat[4];
		m_planes[4].m_normal.y	= mat[13] - mat[5];
		m_planes[4].m_normal.z	= mat[14] - mat[6];
		m_planes[4].m_scalar	= mat[15] - mat[7];

		// near
		m_planes[0].m_normal.x	= mat[12] + mat[8];
		m_planes[0].m_normal.y	= mat[13] + mat[9];
		m_planes[0].m_normal.z	= mat[14] + mat[10];
		m_planes[0].m_scalar	= mat[15] + mat[11];

		// far
		m_planes[1].m_normal.x	= mat[12] - mat[8];
		m_planes[1].m_normal.y	= mat[13] - mat[9];
		m_planes[1].m_normal.z	= mat[14] - mat[10];
		m_planes[1].m_scalar	= mat[15] - mat[11];
	}
	
	bool Contains(AABB box)
	{
		if (!m_planes[0].Intersects(box))
			return false;
		if (!m_planes[1].Intersects(box))
			return false;
		if (!m_planes[2].Intersects(box))
			return false;
		if (!m_planes[3].Intersects(box))
			return false;
		if (!m_planes[4].Intersects(box))
			return false;
		if (!m_planes[5].Intersects(box))
			return false;
		return true;
	}
	
	bool Contains(Vec3f point)
	{
		if (m_planes[0].DistanceFromPoint(point) < MAGIC_VALUE)
			return false;
		if (m_planes[1].DistanceFromPoint(point) < MAGIC_VALUE)
			return false;
		if (m_planes[2].DistanceFromPoint(point) < MAGIC_VALUE)
			return false;
		if (m_planes[3].DistanceFromPoint(point) < MAGIC_VALUE)
			return false;
		if (m_planes[4].DistanceFromPoint(point) < MAGIC_VALUE)
			return false;
		if (m_planes[5].DistanceFromPoint(point) < MAGIC_VALUE)
			return false;
		return true;
	}
}

/*float[] Matrix_Multiply(float[] first, float[] second)
{
	float[] new(16);
	for(int i = 0; i < 4; i++)
		for(int j = 0; j < 4; j++)
			for(int k = 0; k < 4; k++)
				new[i+j*4] += first[i+k*4] * second[j+k*4];
	return new;
}*/