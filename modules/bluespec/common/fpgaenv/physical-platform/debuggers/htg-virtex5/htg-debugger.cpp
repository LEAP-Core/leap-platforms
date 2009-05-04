//
// Copyright (C) 2008 Intel Corporation
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//

#include <stdio.h>
#include <unistd.h>
#include <strings.h>
#include <assert.h>
#include <stdlib.h>
#include <sys/select.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <signal.h>
#include <string.h>
#include <iostream>

using namespace std;

#define INST_STATUS_FLAGS    0x001B0000
#define INST_STATUS_POINTERS 0x001C0000
#define INST_STATUS_VHDL     0x001D0000
#define INST_RUN             0x001E0000

#include "asim/provides/physical_platform_debugger.h"

// ============================================
//          Physical Platform Debugger              
// ============================================

// constructor
PHYSICAL_PLATFORM_DEBUGGER_CLASS::PHYSICAL_PLATFORM_DEBUGGER_CLASS(
    PLATFORMS_MODULE p,
    PHYSICAL_DEVICES d) :
        PLATFORMS_MODULE_CLASS(p)
{
    // cache links to useful physical devices
    pciExpressDevice = d->GetPCIExpressDevice();

    // start iid numbering
    iid = 0;

    // display banner
    printf("=================================================\n");
    printf("           HTG v5 PCIe Debugging Console         \n");
    printf("=================================================\n");
    printf("\n");
    printf("You may use the debugging functionalities only at\n");
    printf("the start of the program. Once you type \"run\", \n");
    printf("the benchmark will run to completion and there is\n");
    printf("no way to get back into the debugger.            \n");
    printf("\n");

    PrintHelp_Commands();

    // ugly: directly call Monitor
    Monitor();
}

// destructor
PHYSICAL_PLATFORM_DEBUGGER_CLASS::~PHYSICAL_PLATFORM_DEBUGGER_CLASS()
{
}

// monitor
void
PHYSICAL_PLATFORM_DEBUGGER_CLASS::Monitor()
{
    CSR_DATA  inst;
    CSR_DATA  data;
    CSR_INDEX index;
    
    char cmdline[256];
    char delims[] = " \t\n";
    int quit = 0;

    while (!quit)
    {
        // printf("Enter debugger command below (because @#$^%@$&#$ fflush is not working):\n");
        printf("htg-debugger > \n");
        fflush(stdout);

        fgets(cmdline, 256, stdin);
        
        char *cmd = strtok(cmdline, delims);
        if (cmd == NULL)
        {
            // do nothing
        }
        else if (!strcmp(cmd, "quit") || !strcmp(cmd, "exit"))
        {
            quit = 1;
        }
        else if (!strcmp(cmd, "help"))
        {
            char *topic = strtok(NULL, delims);
            if (topic == NULL)
            {
                PrintHelp_Help();
            }
            else if (!strcmp(topic, "commands"))
            {
                PrintHelp_Commands();
            }
            else if (!strcmp(topic, "csr"))
            {
                PrintHelp_CSR();
            }
            else if (!strcmp(topic, "inst"))
            {
                PrintHelp_Inst();
            }
            else
            {
                PrintHelp_Help();
            }
        }
        else if (!strcmp(cmd, "read"))
        {
            char *stridx = strtok(NULL, delims);
            if (!strcmp(stridx, "sys") || !strcmp(stridx, "SYS"))
            {
                data = pciExpressDevice->ReadSystemCSR();
                printf("    read CSR[sys] = %8X\n", data);
            }
            else
            {
                index = StoI(stridx);
                data  = pciExpressDevice->ReadCommonCSR(index);
                printf("    read CSR[%3u] = %8X\n", index, data);
            }
        }
        else if (!strcmp(cmd, "write"))
        {
            char *stridx = strtok(NULL, delims);
            if (!strcmp(stridx, "sys") || !strcmp(stridx, "SYS"))
            {
                inst = StoI(strtok(NULL, delims));
                pciExpressDevice->WriteSystemCSR(GenIID()|inst);
            }
            else
            {
                index = StoI(stridx);
                data  = StoI(strtok(NULL, delims));
                pciExpressDevice->WriteCommonCSR(index, data);
            }
        }
        else if (!strcmp(cmd, "exec"))
        {
            inst = StoI(strtok(NULL, delims));
            pciExpressDevice->WriteSystemCSR(GenIID()|inst);
        }
        else if (!strcmp(cmd, "init"))
        {
        }
        /*
        else if (!strcmp(cmd, "status"))
        {
            char *stridx = strtok(NULL, delims);
            if (stridx == NULL)
            {
                // do nothing
            }
            else if (!strcmp(stridx, "flags"))
            {
                pciExpressDevice->WriteSystemCSR(GenIID() | INST_STATUS_FLAGS);
                data = pciExpressDevice->ReadSystemCSR();
                PrintStatus_Flags(data);
            }
            else if (!strcmp(stridx, "pointers"))
            {
                pciExpressDevice->WriteSystemCSR(GenIID() | INST_STATUS_POINTERS);
                data = pciExpressDevice->ReadSystemCSR();
                PrintStatus_Pointers(data);
            }
            else if (!strcmp(stridx, "vhdl"))
            {
                pciExpressDevice->WriteSystemCSR(GenIID() | INST_STATUS_VHDL);
                data = pciExpressDevice->ReadSystemCSR();
                PrintStatus_VHDL(data);
            }
        }
        */
        else if (!strcmp(cmd, "reset"))
        {
            pciExpressDevice->ResetFPGA();
        }
        else if (!strcmp(cmd, "run"))
        {
            pciExpressDevice->WriteSystemCSR(GenIID() | INST_RUN);
            return;
        }
        else
        {
            printf("    invalid command.\n");
        }
    }

    // exit program
    CallbackExit(0);
}

void
PHYSICAL_PLATFORM_DEBUGGER_CLASS::PrintHelp_Help()
{
    printf("\n");
    printf("    help topics: commands csr inst \n");
    printf("\n");
}

void
PHYSICAL_PLATFORM_DEBUGGER_CLASS::PrintHelp_Inst()
{
    printf("\n");
    printf("===== 24-bit Instruction Format =====\n");
    printf("\n");
    printf("    field:   [OPCODE]  [INDEX] [IMMEDIATE]\n");
    printf("    bits :    23-16     15-8      7-0\n");
    printf("\n");
    printf("    opcode 10: NOP\n");
    printf("           11: LEDs         := immediate\n");
    printf("           12: LEDs         := buffer_\n");
    // printf("           13: LEDs         := status_flags\n");
    printf("           14: buffer_      := immediate\n");
    printf("           15: buffer       := buffer << 8\n");
    printf("           16: buffer       := CSR[index]\n");
    printf("           17: CSR[index]   := buffer\n");
    printf("           18: CSR[index]_  := imediate\n");
    printf("           19: CSR[index : index+imm-1] := buffer : buffer+index-1\n");
    printf("           1A: CSR[sys]     := buffer\n");
    // printf("           1B: CSR[sys]     := status_flags\n");
    // printf("           1C: CSR[sys]     := status_pointers\n");
    // printf("           1D: CSR[sys]     := status_VHDL\n");
    printf("           20: CSR[sys]     := DRAM[index]_\n");
    printf("           21: DRAM[index]_ := imm\n");
    printf("\n");
}

void
PHYSICAL_PLATFORM_DEBUGGER_CLASS::PrintHelp_CSR()
{
    printf("\n");
    printf("======== Special CSRs ========\n");
    printf("\n");
    printf("    F2H_TAIL        246    0xF6\n");
    printf("    F2H_HEAD        247    0xF7    (owner)\n");
    printf("    H2F_TAIL        248    0xF8    (owner)\n");
    printf("    H2F_HEAD        249    0xF9\n");
    printf("\n");
    printf("    F2H_BUF_START   123    0x7B\n");
    printf("    F2H_BUF_END     244    0xF4\n");
    printf("    H2F_BUF_START     1    0x01\n");
    printf("    H2F_BUF_END     122    0x7A\n");
    printf("\n");
}

void
PHYSICAL_PLATFORM_DEBUGGER_CLASS::PrintStatus_Flags(
    unsigned int status)
{
    printf("\n");
    printf("========== status: flags =========\n");
    printf("\n");

    printf("    h2f empty = %u\n",  status        & 0x1);
    printf("    h2f full  = %u\n", (status >>  1) & 0x1);
    printf("    f2h empty = %u\n", (status >>  2) & 0x1);
    printf("    f2h full  = %u\n", (status >>  3) & 0x1);
    printf("\n");

    printf("    h2f head dirty = %u\n", (status >>  4) & 0x1);
    printf("    h2f tail valid = %u\n", (status >>  5) & 0x1);
    printf("    f2h head valid = %u\n", (status >>  6) & 0x1);
    printf("    f2h tail dirty = %u\n", (status >>  7) & 0x1);
    printf("\n");

    printf("    READ_ready   = %u\n", (status >>  8) & 0x1);
    printf("    READ_h2fTail = %u\n", (status >>  9) & 0x1);
    printf("    READ_f2hHead = %u\n", (status >> 10) & 0x1);
    printf("    READ_data    = %u\n", (status >> 11) & 0x1);
    printf("\n");

    printf("    initStage    = %u\n", (status >> 12) & 0xF);
    printf("\n");
}

void
PHYSICAL_PLATFORM_DEBUGGER_CLASS::PrintStatus_Pointers(
    unsigned int status)
{
    printf("\n");
    printf("========== status: pointers =========\n");
    printf("\n");

    printf("    f2h tail          = %u\n",  status        & 0xFF);
    printf("    f2h head (cached) = %u\n", (status >>  8) & 0xFF);
    printf("    h2f tail (cached) = %u\n", (status >> 16) & 0xFF);
    printf("    h2f head          = %u\n", (status >> 24) & 0xFF);
    printf("\n");
}

void
PHYSICAL_PLATFORM_DEBUGGER_CLASS::PrintStatus_VHDL(
    unsigned int status)
{
    printf("\n");
    printf("========== status: vhdl and synchronizers =========\n");
    printf("\n");

    printf("    read data = %u\n",  status        & 0xFFFF);
    printf("\n");

    printf("    read req ready  = %u\n", (status >> 16) & 0x1);
    printf("    read resp ready = %u\n", (status >> 17) & 0x1);
    printf("    write ready     = %u\n", (status >> 18) & 0x1);
    printf("\n");

    printf("    write sync depth (bsv)  = %u\n", (status >>  20) & 0x3);
    printf("    write sync depth (vhdl) = %u\n", (status >>  22) & 0x3);
    printf("    write sync #enqueues    = %u\n", (status >>  24) & 0xF);
    printf("    write sync #dequeues    = %u\n", (status >>  28) & 0xF);
    printf("\n");
}

void
PHYSICAL_PLATFORM_DEBUGGER_CLASS::PrintHelp_Commands()
{
    printf("\n");
    printf("========== Commands ==========\n");
    printf("\n");

    printf("    run\n");
    printf("    help   <topic>\n");
    printf("    read   <index>\n");
    printf("    write  <index> <data>\n");
    printf("    exec   <inst>\n");
    // printf("    status <flags|pointers|vhdl>\n");
    printf("    reset\n");
    printf("    quit\n");
    printf("\n");
}

unsigned int
PHYSICAL_PLATFORM_DEBUGGER_CLASS::StoI(
    const char *s)
{
    if (s[0] == '0' && s[1] == 'x')
        return strtol(&s[2], (char **)NULL, 16);
    else
        return strtol(s, (char **)NULL, 10);
}

// generate a new Instruction ID
CSR_DATA
PHYSICAL_PLATFORM_DEBUGGER_CLASS::GenIID()
{
    assert(sizeof(CSR_DATA) >= 4);
    iid = (iid == 255) ? 0 : (iid + 1);
    return (iid << 24);
}
