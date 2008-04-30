// memory_virtual_device_datatypes

// A template for datatype definitions for the Memory Virtual Device.

// You probably won't need to change these.


// ***** Datatype definitions *****


// SCRATCHPAD_MEM_ADDRESS

// The address space the memory virtual device uses. A parameter by default.

typedef Bit#(`SCRATCHPAD_MEMORY_ADDR_SIZE) SCRATCHPAD_MEM_ADDRESS;


// SCRATCHPAD_MEM_VALUE

// The type of values stored in memory. A parameter by default.

typedef Bit#(`SCRATCHPAD_MEMORY_VALUE_SIZE) SCRATCHPAD_MEM_VALUE;


// SCRATCHPAD_MEM_REQUEST

// A request to the memory virtual device is either a load or a store.

typedef union tagged 
{
  SCRATCHPAD_MEM_ADDRESS SCRATCHPAD_MEM_LOAD;
  struct {SCRATCHPAD_MEM_ADDRESS addr; SCRATCHPAD_MEM_VALUE val; } SCRATCHPAD_MEM_STORE;
}
  SCRATCHPAD_MEM_REQUEST
    deriving
            (Eq, Bits);


// SCRATCHPAD_MEMORY_VIRTUAL_DEVICE

// The interface of the memory virtual device.

interface SCRATCHPAD_MEMORY_VIRTUAL_DEVICE;

    method Action makeMemRequest(SCRATCHPAD_MEM_REQUEST req);
    method ActionValue#(SCRATCHPAD_MEM_VALUE) getMemResponse(); //Data is assumed to come back inorder
    method ActionValue#(SCRATCHPAD_MEM_ADDRESS) getInvalidateRequest();

endinterface
