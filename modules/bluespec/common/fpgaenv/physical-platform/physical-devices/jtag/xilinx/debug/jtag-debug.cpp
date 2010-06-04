#include <cstdio>
#include <cstdlib>
#include <iostream>
#include <iomanip>

#include "asim/syntax.h"
#include "asim/ioformat.h"
#include "asim/rrr/service_ids.h"
#include "asim/provides/hybrid_application.h"
#include "asim/provides/clocks_device.h"

using namespace std;

// constructor
HYBRID_APPLICATION_CLASS::HYBRID_APPLICATION_CLASS(
    VIRTUAL_PLATFORM vp)
{
  // instantiate client stub
  clientStub = new JTAGDEBUG_CLIENT_STUB_CLASS(NULL);
}

// destructor
HYBRID_APPLICATION_CLASS::~HYBRID_APPLICATION_CLASS()
{
  delete clientStub;
}

void
HYBRID_APPLICATION_CLASS::Init()
{
}

// main
void
HYBRID_APPLICATION_CLASS::Main()
{
  int i = 0;
  printf ("Entering JTAG test. XMD should be running....\n");
  while(1) {
    UINT8 returned = clientStub->GetChar((UINT8)++i);
    printf("Put in %x got back %x\n", i, returned);
  }
}
