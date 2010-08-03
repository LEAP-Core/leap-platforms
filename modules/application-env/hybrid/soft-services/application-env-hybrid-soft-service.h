
#ifndef __APPLICATION_ENV__
#define __APPLICATION_ENV__

#include "asim/provides/virtual_platform.h"
#include "asim/provides/connected_application.h"

typedef class APPLICATION_ENV_CLASS* APPLICATION_ENV;
class APPLICATION_ENV_CLASS
{
  private:
    CONNECTED_APPLICATION app;
  public:
    APPLICATION_ENV_CLASS(VIRTUAL_PLATFORM vp);
    void InitApp(int arc, char** argv);
    int RunApp(int argc, char** argv);
};


#endif
