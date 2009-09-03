

#include "asim/provides/stats_device.h"

STAT_VECTOR_CLASS::STAT_VECTOR_CLASS(UINT32 id, UINT8 l) : 
    myID(id),
    length(l),
    curValues(new UINT64[l]),
    sawPosition(new bool[l]),
    everSawPosition(new bool[l])
{
    for (int x = 0; x < l; x++)
    {
        curValues[x] = 0;
        sawPosition[x] = false;
        everSawPosition[x] = false;
    }
}

STAT_VECTOR_CLASS::~STAT_VECTOR_CLASS() 
{ 
    delete [] curValues; 
    delete [] sawPosition; 
    delete [] everSawPosition; 
}

void
STAT_VECTOR_CLASS::AddStatValue(UINT32 val, UINT8 pos) 
{ 

    VERIFY(pos < length, "stats device: stat " << STATS_DICT::Name(myID) << " position out of bounds. Given: " << (int) pos << " Max: " << (int) length); 
  
    WARN(!sawPosition[pos], "stats device: stat " << STATS_DICT::Name(myID) << " appears more than once in vector positon " << (int) pos);

    curValues[pos] += val; 
    sawPosition[pos] = true; 
    everSawPosition[pos] = true; 
}

void
STAT_VECTOR_CLASS::DumpFinished()
{
    // Reset which positions we've seen.
    for (int x = 0; x < length; x++)
    {
        sawPosition[x] = false;
    }
}

UINT64* 
STAT_VECTOR_CLASS::GetStatValues() 
{ 
    return curValues; 
}

UINT64
STAT_VECTOR_CLASS::GetStatValue(UINT8 pos)  
{ 
    VERIFY(pos < length, "stats device: " << STATS_DICT::Name(myID) << " access to vector postion " << (int) pos << "out of bounds. Max: " << (int) length); 
    return curValues[pos]; 
}

UINT8
STAT_VECTOR_CLASS::GetLength() 
{ 
    return length; 
}

bool
STAT_VECTOR_CLASS::EverSawPosition(UINT8 pos) 
{ 
    VERIFY(pos < length, "stats device: " << STATS_DICT::Name(myID) << " access to visibilty vector postion " << (int) pos << "out of bounds. Max: " << (int) length); 
    return everSawPosition[pos];
}
