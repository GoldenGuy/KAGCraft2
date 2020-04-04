
class Tree
{
    AABB box;

    Branch@ BRxyz;
    Branch@ BRx1yz;
    Branch@ BRxyz1;
    Branch@ BRx1yz1;
    Branch@ BRxy1z;
    Branch@ BRx1y1z;
    Branch@ BRxy1z1;
    Branch@ BRx1y1z1;
}

class Branch
{
    bool leaf;

    AABB box;

    Branch@ BRxyz;
    Branch@ BRx1yz;
    Branch@ BRxyz1;
    Branch@ BRx1yz1;
    Branch@ BRxy1z;
    Branch@ BRx1y1z;
    Branch@ BRxy1z1;
    Branch@ BRx1y1z1;

    void Check()
    {

    }
}