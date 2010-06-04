#ifndef __JTAGDEBUG_SERVER__
#define __JTAGDEBUG_SERVER__

#include <stdio.h>
#include <sys/time.h>

#include "asim/provides/low_level_platform_interface.h"
#include "asim/provides/rrr.h"

#define TYPES_ONLY
#include "asim/rrr/server_stub_JTAGDEBUG.h"
#undef TYPES_ONLY

// this module provides the RRRTest server functionalities
typedef class JTAGDEBUG_SERVER_CLASS* JTAGDEBUG_SERVER;

class JTAGDEBUG_SERVER_CLASS: public RRR_SERVER_CLASS, 
                              public PLATFORMS_MODULE_CLASS
{
 private:
  // self-instantiation
  static JTAGDEBUG_SERVER_CLASS instance;

  // server stub
  RRR_SERVER_STUB serverStub;

 public:
  JTAGDEBUG_SERVER_CLASS();
  ~JTAGDEBUG_SERVER_CLASS();

  // static methods
  static JTAGDEBUG_SERVER GetInstance() { return &instance; }

  // required RRR methods
  void Init(PLATFORMS_MODULE);
  void Uninit();
  void Cleanup();

  //
  // RRR service methods
  //
  void   PutChar(UINT8 charin);
  void   StatusUpdate(UINT8 charin);

};


// Include the server stub
#include "asim/rrr/server_stub_JTAGDEBUG.h"

#endif
