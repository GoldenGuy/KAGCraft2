
#include "Frustum.as"

class Camera
{
	float[] view;
	float[] projection;
	
	f32 dir_x;
	f32 dir_y;
	f32 dir_z;
	f32 next_dir_x;
	f32 next_dir_y;
	f32 next_dir_z;
	f32 interpolated_dir_x;
	f32 interpolated_dir_y;
	f32 interpolated_dir_z;
	Vec3f pos;
	Vec3f next_pos;
	Vec3f interpolated_pos;
	
	f32 fov;
	f32 z_near;
	f32 z_far;
	
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
		
		fov = Maths::Pi/2.0000f;
		z_near = 0.1f;
		z_far = 80.0f;
		
		pos = Vec3f();
		next_pos = Vec3f();
	}
	
	void move(Vec3f nextpos, bool instantly)
	{
		next_pos = nextpos;
		if(instantly)
		{
			pos = nextpos;
		}
	}
	
	void turn(f32 nextdir_x, f32 nextdir_y, f32 nextdir_z, bool instantly)
	{
		next_dir_x = nextdir_x;
		next_dir_y = nextdir_y;
		next_dir_z = nextdir_z;
		if(instantly)
		{
			dir_x = nextdir_x;
			dir_y = nextdir_y;
			dir_z = nextdir_z;
		}
	}
	
	void render_update()
	{
		interpolated_dir_x = Maths::Lerp(dir_x, next_dir_x, getInterFrameTime());
		interpolated_dir_y = Maths::Lerp(dir_y, next_dir_y, getInterFrameTime());
		interpolated_dir_z = Maths::Lerp(dir_z, next_dir_z, getInterFrameTime());
		interpolated_pos = pos.Lerp(next_pos, getInterFrameTime());
		
		Matrix::MakePerspective(projection, fov, f32(getDriver().getScreenWidth()) / f32(getDriver().getScreenHeight()), z_near, z_far/*f32(render_distance)/2.0f*chunk_depth+5*/);
		makeMatrix();
	}
	
	void tick_update()
	{
		dir_x = next_dir_x;
		dir_y = next_dir_y;
		dir_z = next_dir_z;
		pos = next_pos;
	}
	
	void makeMatrix()
	{
		float[] temp_mat;
		Matrix::MakeIdentity(temp_mat);
		float[] another_temp_mat;
		Matrix::MakeIdentity(another_temp_mat);
		float[] and_another_temp_mat;
		
		Matrix::SetRotationDegrees(temp_mat, 0, interpolated_dir_x, 0);
		Matrix::SetRotationDegrees(another_temp_mat, -interpolated_dir_y, 0, 0);
		Matrix::Multiply(temp_mat, another_temp_mat, and_another_temp_mat);
		frustum.Update(projection, and_another_temp_mat);
		
		Matrix::MakeIdentity(temp_mat);
		Matrix::MakeIdentity(another_temp_mat);
		
		
		Matrix::SetRotationDegrees(temp_mat, 0, -interpolated_dir_x, 0);
		Matrix::SetRotationDegrees(another_temp_mat, interpolated_dir_y, 0, 0);
		Matrix::Multiply(another_temp_mat, temp_mat, and_another_temp_mat);
		
		Matrix::MakeIdentity(temp_mat);
		Matrix::SetTranslation(temp_mat, -interpolated_pos.x, -interpolated_pos.y, -interpolated_pos.z);
		
		Matrix::Multiply(and_another_temp_mat, temp_mat, view);
	}
	
	Vec3f getInterpolatedPosition()
	{
		return interpolated_pos;
	}
	
	void getInterpolatedAngle(f32 &out temp_dir_x, f32 &out temp_dir_y, f32 &out temp_dir_z)
	{
		temp_dir_x = interpolated_dir_x;
		temp_dir_y = interpolated_dir_y;
		temp_dir_z = interpolated_dir_z;
	}
}