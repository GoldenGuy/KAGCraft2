
#include "Frustum.as"

class Camera
{
	float[] view;
	float[] projection;
	
	float dir_x;
	float dir_y;
	float dir_z;
	float next_dir_x;
	float next_dir_y;
	float next_dir_z;
	float interpolated_dir_x;
	float interpolated_dir_y;
	float interpolated_dir_z;
	Vec3f pos;
	Vec3f next_pos;
	Vec3f interpolated_pos;
	Vec3f frustum_pos;
	
	float fov;
	float z_near;
	float z_far;
	
	Frustum frustum;
	
	Camera()
	{
		Matrix::MakeIdentity(view);
		
		dir_x = 0;
		dir_y = 0;
		dir_z = 0;
		next_dir_x = 0;
		next_dir_y = 0;
		next_dir_z = 0;
		
		fov = Maths::Pi/2.4000f;
		z_near = 0.1f;
		z_far = 85.0f;
		
		pos = Vec3f();
		next_pos = Vec3f();

		Matrix::MakePerspective(projection, fov, float(getDriver().getScreenWidth()) / float(getDriver().getScreenHeight()), z_near, z_far);
		updateFrustum();
	}
	
	void move(const Vec3f&in nextpos, bool instantly)
	{
		next_pos = nextpos;
		if(instantly)
		{
			pos = nextpos;
		}
	}
	
	void turn(float nextdir_x, float nextdir_y, float nextdir_z, bool instantly)
	{
		next_dir_x = nextdir_x;
		if(dir_x - next_dir_x > 180) dir_x -= 360;
		else if(next_dir_x - dir_x > 180) dir_x += 360;
		next_dir_y = nextdir_y;
		if(dir_y - next_dir_y > 180) dir_y -= 360;
		else if(next_dir_y - dir_y > 180) dir_y += 360;
		next_dir_z = nextdir_z;
		if(dir_z - next_dir_z > 180) dir_z -= 360;
		else if(next_dir_z - dir_z > 180) dir_z += 360;
		
		if(instantly)
		{
			dir_x = nextdir_x;
			dir_y = nextdir_y;
			dir_z = nextdir_z;
		}
		updateFrustum();
	}
	
	void render_update()
	{
		interpolated_dir_x = Maths::Lerp(dir_x, next_dir_x, getInterFrameTime());
		interpolated_dir_y = Maths::Lerp(dir_y, next_dir_y, getInterFrameTime());
		interpolated_dir_z = Maths::Lerp(dir_z, next_dir_z, getInterFrameTime());
		interpolated_pos = pos.Lerp(next_pos, getInterFrameTime());
		
		//Matrix::MakePerspective(projection, fov, float(getDriver().getScreenWidth()) / float(getDriver().getScreenHeight()), z_near, z_far);
		makeMatrix();
	}
	
	void tick_update()
	{
		dir_x = next_dir_x;
		dir_y = next_dir_y;
		dir_z = next_dir_z;
		pos = next_pos;
		if(!hold_frustum) frustum_pos = next_pos;
	}

	void updateFrustum()
	{
		float[] temp_mat;
		Matrix::MakeIdentity(temp_mat);
		float[] another_temp_mat;
		Matrix::MakeIdentity(another_temp_mat);
		
		Matrix::SetRotationDegrees(temp_mat, 0, next_dir_x, 0);
		Matrix::SetRotationDegrees(another_temp_mat, next_dir_y, 0, 0);
		temp_mat = Matrix_Multiply(temp_mat, another_temp_mat);
		temp_mat = Matrix_Multiply(projection, temp_mat);

		if(!hold_frustum) frustum.Update(temp_mat);
	}
	
	void makeMatrix()
	{
		//updateFrustum();
		float[] temp_mat;
		Matrix::MakeIdentity(temp_mat);
		float[] another_temp_mat;
		Matrix::MakeIdentity(another_temp_mat);
		
		Matrix::SetRotationDegrees(temp_mat, 0, interpolated_dir_x, 0);
		Matrix::SetRotationDegrees(another_temp_mat, interpolated_dir_y, 0, 0);
		temp_mat = Matrix_Multiply(another_temp_mat, temp_mat);
		
		Matrix::MakeIdentity(another_temp_mat);
		Matrix::SetTranslation(another_temp_mat, -interpolated_pos.x, -interpolated_pos.y, -interpolated_pos.z);
		
		Matrix::Multiply(temp_mat, another_temp_mat, view);
	}
	
	Vec3f getInterpolatedPosition()
	{
		return interpolated_pos;
	}
}