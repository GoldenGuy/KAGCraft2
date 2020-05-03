
class Vec3f
{
	float x;
	float y;
	float z;
	
	Vec3f()
	{
		x = 0;
		y = 0;
		z = 0;
	}
	
	Vec3f(float _x, float _y, float _z)
	{
		x = _x;
		y = _y;
		z = _z;
	}
	
	
	Vec3f(Vec3f&in vec, float len)
	{
		vec.Normalize();
		if(len == 0)
			print("invalid vector");
		x = len * vec.x;
		y = len * vec.y;
		z = len * vec.z;
	}
	
	Vec3f opAdd(const Vec3f&in oof) const { return Vec3f(x + oof.x, y + oof.y, z + oof.z); }
	
	Vec3f opAdd(float oof) const { return Vec3f(x + oof, y + oof, z + oof); }

	void opAddAssign(const Vec3f&in oof) { x += oof.x; y += oof.y; z += oof.z; }

	void opAddAssign(float oof) { x += oof; y += oof; z += oof; }

	Vec3f opSub(const Vec3f&in oof) const { return Vec3f(x - oof.x, y - oof.y, z - oof.z); }
	
	Vec3f opSub(float oof) const { return Vec3f(x - oof, y - oof, z - oof); }

	void opSubAssign(const Vec3f&in oof) { x -= oof.x; y -= oof.y; z -= oof.z; }

	Vec3f opMul(const Vec3f&in oof) { return Vec3f(x * oof.x, y * oof.y, z * oof.z); }

	Vec3f opMul(float oof) const { return Vec3f(x * oof, y * oof, z * oof); }

	void opMulAssign(float oof) { x *= oof; y *= oof; z *= oof; }

	Vec3f opDiv(const Vec3f&in oof) const { return Vec3f(x / oof.x, y / oof.y, z / oof.z); }

	Vec3f opDiv(float oof) { return Vec3f(x / oof, y / oof, z / oof); }

	void opDivAssign(float oof) { x /= oof; y /= oof; z /= oof; }

	bool opEquals(const Vec3f&in oof) const { return x == oof.x && y == oof.y && z == oof.z; }

	// only for asu's build, since as upgrade
	void opAssign(const Vec3f &in oof){ x=oof.x;y=oof.y;z=oof.z; }
	
	Vec3f Lerp(const Vec3f&in desired, float t)
	{
		return Vec3f((((1 - t) * this.x) + (t * desired.x)), (((1 - t) * this.y) + (t * desired.y)), (((1 - t) * this.z) + (t * desired.z)));
	}
	
	void Print()
	{
		print("x: "+x+"; y: "+y+"; z: "+z);
	}
	
	void Normalize()
	{
		float length = this.Length();
		if(length == 0)
		{
			return;
		}
		x /= length;
		y /= length;
		z /= length;
	}
	
	float Length() const
	{
		return Maths::Sqrt(x*x + y*y + z*z);
	}

	void RotateXZ(float degr)
	{
		Vec2f new = Vec2f(x,z);
		new.RotateByDegrees(degr);
		x = new.x; z = new.y;
	}

	string IntString()
	{
		return int(x)+", "+int(y)+", "+int(z);
	}

	string FloatString()
	{
		return x+", "+y+", "+z;
	}
}

float DotProduct(const Vec3f&in v1, const Vec3f&in v2)
{
    return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z;
}

Vec3f CrossProduct(const Vec3f&in v1, const Vec3f&in v2)
{
    return Vec3f(v1.y * v2.z - v1.z * v2.y, v1.z * v2.x - v1.x * v2.z, v1.x * v2.y - v1.y * v2.x);
}

const float piboe = Maths::Pi/180.0f;

float[] Matrix_Multiply(const float[]&in first, const float[]&in second) // inbuilt function is retarded
{
	float[] new(16);
	for(int i = 0; i < 4; i++)
		for(int j = 0; j < 4; j++)
			for(int k = 0; k < 4; k++)
				new[i+j*4] += first[i+k*4] * second[j+k*4];
	return new;
}