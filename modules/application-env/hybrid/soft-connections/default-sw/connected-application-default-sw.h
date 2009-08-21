
#ifndef __CONNECTED_APPLICATION__
#define __CONNECTED_APPLICATION__

#include "asim/provides/virtual_platform.h"

// Default software does nothing and immediately returns 0;

typedef class CONNECTED_APPLICATION_CLASS* CONNECTED_APPLICATION;
class CONNECTED_APPLICATION_CLASS
{
  public:
    CONNECTED_APPLICATION_CLASS(VIRTUAL_PLATFORM vp) {}
    void Init() {}
    int Main() { return 0; }
};


#endif
