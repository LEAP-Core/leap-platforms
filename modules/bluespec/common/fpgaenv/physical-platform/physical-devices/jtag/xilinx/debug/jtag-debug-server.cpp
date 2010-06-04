#include <cstdio>
#include <cstdlib>
#include <iostream>
#include <iomanip>

#include "asim/syntax.h"
#include "asim/rrr/service_ids.h"
#include "asim/provides/hybrid_application.h"

using namespace std;

// ===== service instantiation =====
JTAGDEBUG_SERVER_CLASS JTAGDEBUG_SERVER_CLASS::instance;

// constructor
JTAGDEBUG_SERVER_CLASS::JTAGDEBUG_SERVER_CLASS()
{
  // instantiate stub
  serverStub = new JTAGDEBUG_SERVER_STUB_CLASS(this);
}

// destructor
JTAGDEBUG_SERVER_CLASS::~JTAGDEBUG_SERVER_CLASS()
{
  Cleanup();
}

// init
void
JTAGDEBUG_SERVER_CLASS::Init(PLATFORMS_MODULE p)
{
  PLATFORMS_MODULE_CLASS::Init(p);
}

// uninit
void
JTAGDEBUG_SERVER_CLASS::Uninit()
{
  Cleanup();
  PLATFORMS_MODULE_CLASS::Uninit();
}

// cleanup
void
JTAGDEBUG_SERVER_CLASS::Cleanup()
{
  delete serverStub;
}

//
// RRR service methods
//

// F2HOneWayMsg
void
JTAGDEBUG_SERVER_CLASS::PutChar(
				    UINT8 payload)
{
  printf("Got %x from JTAG\n", payload);
}

