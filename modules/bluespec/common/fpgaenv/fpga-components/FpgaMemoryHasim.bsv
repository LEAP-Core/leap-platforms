import FpgaMemory::*;

typedef ReadReq#(addrWidth) READ_REQ#(numeric type addrWidth);
typedef ReadResp#(dataT) READ_RESP#(type dataT);
typedef Write#(addrWidth, dataT) WRITE#(numeric type addrWidth, type dataT);
typedef Bram#(indexWidth, dataT) BRAM#(numeric type indexWidth, type dataT);
typedef MultiReadBram#(readPortsNum, indexWidth, dataT) BRAM_MULTI_READ#(numeric type readPortsNum, numeric type indexWidth, type dataT);
