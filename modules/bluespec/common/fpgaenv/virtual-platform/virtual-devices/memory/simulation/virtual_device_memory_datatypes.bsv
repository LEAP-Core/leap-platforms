// virtual_device_memory_datatypes

// This file contains one change beyond the template:
// The definition of a simulation-sized address.

// ***** Datatype definitions *****

// SIM_ADDRESS

// Simulation memory is a smaller size to speed up simulation.
// Set by a parameter.

typedef Bit#(`MEMORY_SIM_ADDR_SIZE) SIM_ADDRESS;

// No changes beyond this point.


// MEM_ADDRESS

// The address space the memory virtual device uses.

typedef Bit#(`MEMORY_ADDR_SIZE) MEM_ADDRESS;


// MEM_VALUE

// The type of values stored in memory.

typedef Bit#(`MEMORY_VALUE_SIZE) MEM_VALUE;

// MEM_REQUEST

// A request to the memory virtual device is either a load or a store.

typedef union tagged 
{
  MEM_ADDRESS MEM_LOAD;
  struct {MEM_ADDRESS addr; MEM_VALUE val; } MEM_STORE;
}
  MEM_REQUEST
    deriving
            (Eq, Bits);


// MEMORY_VIRTUAL_DEVICE

// The interface of the memory virtual device.

interface MEMORY_VIRTUAL_DEVICE;

    method Action makeMemRequest(MEM_REQUEST req);
    method ActionValue#(MEM_VALUE) getMemResponse(); //Data is assumed to come back inorder
    method ActionValue#(MEM_ADDRESS) getInvalidateRequest();

endinterface

