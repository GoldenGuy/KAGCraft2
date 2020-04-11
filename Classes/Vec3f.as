
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
	
	
	Vec3f(Vec3f vec, float Length)
	{
		vec.Normalize();
		if(Length == 0)
			print("invalid vector");
		x=Length*vec.x;
		y=Length*vec.y;
		z=Length*vec.z;
	}
	
	Vec3f opAdd(const Vec3f &in oof){return Vec3f(x + oof.x, y + oof.y, z + oof.z);}
	
	Vec3f opAdd(const float &in oof){return Vec3f(x + oof, y + oof, z + oof);}

	void opAddAssign(const Vec3f &in oof){x+=oof.x;y+=oof.y;z+=oof.z;}

	void opAddAssign(const float &in oof){x+=oof;y+=oof;z+=oof;}

	Vec3f opSub(const Vec3f &in oof){return Vec3f(x - oof.x, y - oof.y, z - oof.z);}
	
	Vec3f opSub(const float &in oof){return Vec3f(x - oof, y - oof, z - oof);}

	void opSubAssign(const Vec3f &in oof){x-=oof.x;y-=oof.y;z-=oof.z;}

	Vec3f opMul(const Vec3f &in oof){return Vec3f(x * oof.x, y * oof.y, z * oof.z);}

	Vec3f opMul(const float &in oof){return Vec3f(x * oof, y * oof, z * oof);}

	void opMulAssign(const float &in oof){x*=oof;y*=oof;z*=oof;}

	Vec3f opDiv(const Vec3f &in oof){return Vec3f(x / oof.x, y / oof.y, z / oof.z);}

	Vec3f opDiv(const float &in oof){return Vec3f(x / oof, y / oof, z / oof);}

	void opDivAssign(const float &in oof){x/=oof;y/=oof;z/=oof;}

	// only for asu's build, since as upgrade
	//void opAssign(const Vec3f &in oof){x=oof.x;y=oof.y;z=oof.z;}
	
	Vec3f Lerp(Vec3f desired, float t)
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
			//error("(Normalize) invalid vector");
			return;
		}
		x /= length;
		y /= length;
		z /= length;
	}
	
	float Length()
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

float DotProduct(Vec3f v1, Vec3f v2)
{
    return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z;
}

const float piboe = Maths::Pi/180.0f;