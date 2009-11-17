// The MIT License

// Copyright (c) 2009 Massachusetts Institute of Technology

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

// Author: Sam Gross sgross@mit.edu

import Connectable::*;
import GetPut::*;

typedef struct {
  Bit#(64) data;
  Bit#(4) addr;
} NPIReadWord deriving(Eq, Bits);

typedef struct {
  Bit#(64) data;
  Bit#(8) be;
} NPIWriteWord deriving(Eq, Bits);

typedef union tagged {
  struct { Bit#(32) addr; Bit#(4) size; } ReadCommand;
  struct { Bit#(32) addr; Bit#(4) size; Bool rmw; } WriteCommand;
} NPICommand deriving(Eq, Bits);

interface NPIClient;
  interface Get#(NPIWriteWord) write;
  interface Put#(NPIReadWord) read;
  interface Get#(NPICommand) command;
endinterface

interface NPIServer;
  interface Put#(NPIWriteWord) write;
  interface Get#(NPIReadWord) read;
  interface Put#(NPICommand) command;
  method Bit#(32) addrAcksRead();
  method Bit#(32) addrAcksWrite();
  method Bit#(32) clockTicks();
endinterface


instance Connectable#(NPIClient,NPIServer);
  module mkConnection#(NPIClient client, NPIServer server) ();
    mkConnection(client.write, server.write);
    mkConnection(client.read, server.read);
    mkConnection(client.command, server.command);
  endmodule
endinstance

instance Connectable#(NPIServer,NPIClient);
  module mkConnection#(NPIServer server, NPIClient client) ();
    mkConnection(client.write, server.write);
    mkConnection(client.read, server.read);
    mkConnection(client.command, server.command);
  endmodule
endinstance
