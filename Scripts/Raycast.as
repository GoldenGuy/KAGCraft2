
namespace Raycast
{
	enum State
	{
		S_NONE = 0,
		S_HIT,
		S_OOB_X,
		S_OOB_Y,
		S_OOB_Z,
		S_TOOFAR,
		S_OUTSIDE
	}
}
	
uint8 RaycastPrecise(const Vec3f&in ray_pos, const Vec3f&in ray_dir, float max_dist, Vec3f&out hit_pos, bool ignore_nonsolid)
{
	bool escaped_above = false;
	if(!world.inWorldBoundsIgnoreHeight(ray_pos.x, ray_pos.y, ray_pos.z)) return Raycast::S_OUTSIDE;
	if(ray_pos.y >= world.map_height) escaped_above = true;
	
	Vec3f ray_world_pos(int(ray_pos.x), int(ray_pos.y), int(ray_pos.z));
	Vec3f delta_dist(
		ray_dir.x == 0 ? 0.0f : Maths::Abs(1.0f / ray_dir.x),
		ray_dir.y == 0 ? 0.0f : Maths::Abs(1.0f / ray_dir.y),
		ray_dir.z == 0 ? 0.0f : Maths::Abs(1.0f / ray_dir.z)
	);
	Vec3f side_dist;
	Vec3f step;
	if(ray_dir.x < 0)
	{
		step.x = -1;
		side_dist.x = (ray_pos.x - ray_world_pos.x) * delta_dist.x;
	}
	else
	{
		step.x = 1;
		side_dist.x = (ray_world_pos.x + 1.0f - ray_pos.x) * delta_dist.x;
	}
	if(ray_dir.y < 0)
	{
		step.y = -1;
		side_dist.y = (ray_pos.y - ray_world_pos.y) * delta_dist.y;
	}
	else
	{
		step.y = 1;
		side_dist.y = (ray_world_pos.y + 1.0f - ray_pos.y) * delta_dist.y;
	}
	if(ray_dir.z < 0)
	{
		step.z = -1;
		side_dist.z = (ray_pos.z - ray_world_pos.z) * delta_dist.z;
	}
	else
	{
		step.z = 1;
		side_dist.z = (ray_world_pos.z + 1.0f - ray_pos.z) * delta_dist.z;
	}
	uint8 side = 0;
	while(max_dist > (ray_world_pos-ray_pos+Vec3f(0.5f, 0.5f, 0.5f)).Length())
	{
		if(side_dist.x < side_dist.y)
		{
			if(side_dist.x < side_dist.z)
			{
				side_dist.x += delta_dist.x;
				ray_world_pos.x += step.x;
				if(ray_world_pos.x >= world.map_width || ray_world_pos.x < 0)
				{
					hit_pos = ray_pos + ray_dir * (side_dist.x-delta_dist.x);
					return Raycast::S_OOB_X;
				}
				side = 0;
			}
			else
			{
				side_dist.z += delta_dist.z;
				ray_world_pos.z += step.z;
				if(ray_world_pos.z >= world.map_depth || ray_world_pos.z < 0)
				{
					hit_pos = ray_pos + ray_dir * (side_dist.z-delta_dist.z);
					return Raycast::S_OOB_Z;
				}
				side = 2;
			}
		}
		else
		{
			if(side_dist.y < side_dist.z)
			{
				side_dist.y += delta_dist.y;
				ray_world_pos.y += step.y;
				if(ray_world_pos.y < 0)
				{
					hit_pos = ray_pos + ray_dir * (side_dist.y-delta_dist.y);
					return Raycast::S_OOB_Y;
				}
				else if(ray_world_pos.y >= world.map_height)
				{
					escaped_above = true;
				}
				else
				{
					escaped_above = false;
				}
				side = 1;
			}
			else
			{
				side_dist.z += delta_dist.z;
				ray_world_pos.z += step.z;
				if(ray_world_pos.z >= world.map_depth || ray_world_pos.z < 0)
				{
					hit_pos = ray_pos + ray_dir * (side_dist.z-delta_dist.z);
					return Raycast::S_OOB_Z;
				}
				side = 2;
			}
		}
		if(escaped_above)
		{
			continue;
		}
		uint8 check = world.getBlock(ray_world_pos.x, ray_world_pos.y, ray_world_pos.z);//world.map[ray_world_pos.y][ray_world_pos.z][ray_world_pos.x];
		if((ignore_nonsolid && Block::solid[check]) || (!ignore_nonsolid && check != Block::air))
		{
			if(side == 0)
			{
				hit_pos = ray_pos + ray_dir * (side_dist.x-delta_dist.x);
			}
			else if(side == 1)
			{
				hit_pos = ray_pos + ray_dir * (side_dist.y-delta_dist.y);
			}
			else if(side == 2)
			{
				hit_pos = ray_pos + ray_dir * (side_dist.z-delta_dist.z);
			}
			return Raycast::S_HIT;
		}
	}
	hit_pos = ray_pos + ray_dir * max_dist;
	return Raycast::S_TOOFAR;
}

uint8 RaycastWorld_Previous(const Vec3f&in ray_pos, const Vec3f&in ray_dir, float max_dist, Vec3f&out hit_pos)
{
	bool escaped_above = false;
	if(!world.inWorldBoundsIgnoreHeight(ray_pos.x, ray_pos.y, ray_pos.z)) return Raycast::S_OUTSIDE;
	if(ray_pos.y >= world.map_height) escaped_above = true;
	
	Vec3f ray_world_pos(int(ray_pos.x), int(ray_pos.y), int(ray_pos.z));
	Vec3f delta_dist(
		ray_dir.x == 0 ? 0.0f : Maths::Abs(1.0f / ray_dir.x),
		ray_dir.y == 0 ? 0.0f : Maths::Abs(1.0f / ray_dir.y),
		ray_dir.z == 0 ? 0.0f : Maths::Abs(1.0f / ray_dir.z)
	);
	Vec3f side_dist;
	Vec3f step;
	if(ray_dir.x < 0)
	{
		step.x = -1;
		side_dist.x = (ray_pos.x - ray_world_pos.x) * delta_dist.x;
	}
	else
	{
		step.x = 1;
		side_dist.x = (ray_world_pos.x + 1.0f - ray_pos.x) * delta_dist.x;
	}
	if(ray_dir.y < 0)
	{
		step.y = -1;
		side_dist.y = (ray_pos.y - ray_world_pos.y) * delta_dist.y;
	}
	else
	{
		step.y = 1;
		side_dist.y = (ray_world_pos.y + 1.0f - ray_pos.y) * delta_dist.y;
	}
	if(ray_dir.z < 0)
	{
		step.z = -1;
		side_dist.z = (ray_pos.z - ray_world_pos.z) * delta_dist.z;
	}
	else
	{
		step.z = 1;
		side_dist.z = (ray_world_pos.z + 1.0f - ray_pos.z) * delta_dist.z;
	}
	while(max_dist > (ray_world_pos-ray_pos+Vec3f(0.5f, 0.5f, 0.5)).Length())
	{
		hit_pos = ray_world_pos;
		if(side_dist.x < side_dist.y)
		{
			if(side_dist.x < side_dist.z)
			{
				side_dist.x += delta_dist.x;
				ray_world_pos.x += step.x;
				if(ray_world_pos.x >= world.map_width || ray_world_pos.x < 0)
				{
					return Raycast::S_OOB_X;
				}
			}
			else
			{
				side_dist.z += delta_dist.z;
				ray_world_pos.z += step.z;
				if(ray_world_pos.z >= world.map_depth || ray_world_pos.z < 0)
				{
					return Raycast::S_OOB_Z;
				}
			}
		}
		else
		{
			if(side_dist.y < side_dist.z)
			{
				side_dist.y += delta_dist.y;
				ray_world_pos.y += step.y;
				if(ray_world_pos.y < 0)
				{
					return Raycast::S_OOB_Y;
				}
				else if(ray_world_pos.y >= world.map_height)
				{
					escaped_above = true;
				}
				else
				{
					escaped_above = false;
				}
			}
			else
			{
				side_dist.z += delta_dist.z;
				ray_world_pos.z += step.z;
				if(ray_world_pos.z >= world.map_depth || ray_world_pos.z < 0)
				{
					return Raycast::S_OOB_Z;
				}
			}
		}
		if(escaped_above)
		{
			continue;
		}
		uint8 check = world.getBlock(ray_world_pos.x, ray_world_pos.y, ray_world_pos.z);//world.map[ray_world_pos.y][ray_world_pos.z][ray_world_pos.x];
		if(check != Block::air)
		{
			return Raycast::S_HIT;
		}
	}
	return Raycast::S_TOOFAR;
}

uint8 RaycastWorld(const Vec3f&in ray_pos, const Vec3f&in ray_dir, float max_dist, Vec3f&out hit_pos)
{
	bool escaped_above = false;
	if(!world.inWorldBoundsIgnoreHeight(ray_pos.x, ray_pos.y, ray_pos.z)) return Raycast::S_OUTSIDE;
	if(ray_pos.y >= world.map_height) escaped_above = true;

	Vec3f ray_world_pos(int(ray_pos.x), int(ray_pos.y), int(ray_pos.z));
	Vec3f delta_dist(
		ray_dir.x == 0 ? 0.0f : Maths::Abs(1.0f / ray_dir.x),
		ray_dir.y == 0 ? 0.0f : Maths::Abs(1.0f / ray_dir.y),
		ray_dir.z == 0 ? 0.0f : Maths::Abs(1.0f / ray_dir.z)
	);
	Vec3f side_dist;
	Vec3f step;
	if(ray_dir.x < 0)
	{
		step.x = -1;
		side_dist.x = (ray_pos.x - ray_world_pos.x) * delta_dist.x;
	}
	else
	{
		step.x = 1;
		side_dist.x = (ray_world_pos.x + 1.0f - ray_pos.x) * delta_dist.x;
	}
	if(ray_dir.y < 0)
	{
		step.y = -1;
		side_dist.y = (ray_pos.y - ray_world_pos.y) * delta_dist.y;
	}
	else
	{
		step.y = 1;
		side_dist.y = (ray_world_pos.y + 1.0f - ray_pos.y) * delta_dist.y;
	}
	if(ray_dir.z < 0)
	{
		step.z = -1;
		side_dist.z = (ray_pos.z - ray_world_pos.z) * delta_dist.z;
	}
	else
	{
		step.z = 1;
		side_dist.z = (ray_world_pos.z + 1.0f - ray_pos.z) * delta_dist.z;
	}
	while(max_dist > (ray_world_pos-ray_pos+Vec3f(0.5f, 0.5f, 0.5f)).Length())
	{
		if(side_dist.x < side_dist.y)
		{
			if(side_dist.x < side_dist.z)
			{
				side_dist.x += delta_dist.x;
				ray_world_pos.x += step.x;
				if(ray_world_pos.x >= world.map_width || ray_world_pos.x < 0)
				{
					return Raycast::S_OOB_X;
				}
			}
			else
			{
				side_dist.z += delta_dist.z;
				ray_world_pos.z += step.z;
				if(ray_world_pos.z >= world.map_depth || ray_world_pos.z < 0)
				{
					return Raycast::S_OOB_Z;
				}
			}
		}
		else
		{
			if(side_dist.y < side_dist.z)
			{
				side_dist.y += delta_dist.y;
				ray_world_pos.y += step.y;
				if(ray_world_pos.y < 0)
				{
					return Raycast::S_OOB_Y;
				}
				else if(ray_world_pos.y >= world.map_height)
				{
					escaped_above = true;
				}
				else
				{
					escaped_above = false;
				}
			}
			else
			{
				side_dist.z += delta_dist.z;
				ray_world_pos.z += step.z;
				if(ray_world_pos.z >= world.map_depth || ray_world_pos.z < 0)
				{
					return Raycast::S_OOB_Z;
				}
			}
		}
		if(escaped_above)
		{
			continue;
		}
		uint8 check = world.getBlock(ray_world_pos.x, ray_world_pos.y, ray_world_pos.z);//world.map[ray_world_pos.y][ray_world_pos.z][ray_world_pos.x];
		if(check != Block::air)
		{
			hit_pos = ray_world_pos;
			return Raycast::S_HIT;
		}
	}
	return Raycast::S_TOOFAR;
}