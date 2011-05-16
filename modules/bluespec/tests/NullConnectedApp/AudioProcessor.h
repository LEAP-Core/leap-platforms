//
// INTEL CONFIDENTIAL
// Copyright (c) 2008 Intel Corp.  Recipient is granted a non-sublicensable 
// copyright license under Intel copyrights to copy and distribute this code 
// internally only. This code is provided "AS IS" with no support and with no 
// warranties of any kind, including warranties of MERCHANTABILITY,
// FITNESS FOR ANY PARTICULAR PURPOSE or INTELLECTUAL PROPERTY INFRINGEMENT. 
// By making any use of this code, Recipient agrees that no other licenses 
// to any Intel patents, trade secrets, copyrights or other intellectual 
// property rights are granted herein, and no other licenses shall arise by 
// estoppel, implication or by operation of law. Recipient accepts all risks 
// of use.
//

// possibly use include paths to hide existing modules?

#ifndef __AUDIO_PROCESSOR_CONNECTED_APPLICATION__
#define __AUDIO_PROCESSOR_CONNECTED_APPLICATION__

#include "asim/provides/virtual_platform.h"

typedef class CONNECTED_APPLICATION_CLASS* CONNECTED_APPLICATION;
class CONNECTED_APPLICATION_CLASS : public PLATFORMS_MODULE_CLASS
{
 private:

 public:
  CONNECTED_APPLICATION_CLASS(VIRTUAL_PLATFORM vp);
  ~CONNECTED_APPLICATION_CLASS();
  void Init();
  void Main();
};

#endif
