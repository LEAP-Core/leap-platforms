import FIFOF::*;
import Vector::*;
import RegFile::*;
import RWire::*;

import FAST_BRAM::*;

interface ReadReq#(numeric type addrSz);
    method Action read(Bit#(addrSz) addr);
endinterface

interface ReadResp#(type dataT);
    method ActionValue#(dataT) read();
endinterface

interface Write#(numeric type addrSz, type dataT);
    method Action write(Bit#(addrSz) addr, dataT data);
endinterface

interface MultiPortBram#(numeric type readNum, numeric type writeNum, numeric type addrSz, type dataT);
    interface Vector#(readNum, ReadReq#(addrSz)) req;
    interface Vector#(readNum, ReadResp#(dataT)) resp;
    interface Vector#(writeNum, Write#(addrSz, dataT)) write;
    method Bool noPending();
endinterface

interface MultiReadBram#(numeric type readNum, numeric type addrSz, type dataT);
    interface Vector#(readNum, ReadReq#(addrSz)) req;
    interface Vector#(readNum, ReadResp#(dataT)) resp;
    method Action write(Bit#(addrSz) addr, dataT data);
    method Bool noPending();
endinterface

interface Bram#(numeric type addrSz, type dataT);
    method Action readReq(Bit#(addrSz) addr);
    method ActionValue#(dataT) readResp();
    method Action write(Bit#(addrSz) addr, dataT data);
    method Bool noPending();
endinterface

function Bool andBool(Bool a, Bool b);
    return a && b;
endfunction

interface BramRaw#(type addrSz, type dataT);
    method Action portReq1(Bit#(addrSz) addr, dataT data, Bool write);
    method dataT portResp1();
    method Action portReq2(Bit#(addrSz) addr, dataT data, Bool write);
    method dataT portResp2();
endinterface

module mkBramRaw(BramRaw#(addrSz, dataT))
        provisos(Bits#(dataT, dataSz));
    FAST_BRAM#(dataT, Bit#(addrSz)) fast_bram <- mkFAST_BRAM_verilog;
    method Action portReq1(Bit#(addrSz) addr, dataT data, Bool write);
        if (write)
            fast_bram.write(addr, data);
        else
            fast_bram.read(addr);
    endmethod
    method dataT portResp1() = fast_bram.readval();
    method Action portReq2(Bit#(addrSz) addr, dataT data, Bool write);
        if (write)
            fast_bram.write2(addr, data);
        else
            fast_bram.read2(addr);
    endmethod
    method dataT portResp2() = fast_bram.readval2();
endmodule

module mkDualWriteMultiReadBram(MultiPortBram#(readNum, 2, addrSz, dataT))
    provisos(Bits#(dataT, dataSz),
             Add#(1, pos, readNum),
             Add#(1, readNum, readNum1),
             Div#(readNum1, 2, bramNum));

    Vector#(bramNum, BramRaw#(addrSz, dataT)) ram <- replicateM(mkBramRaw());

    Vector#(readNum, FIFOF#(dataT))      buffer <- replicateM(mkFIFOF());
    Vector#(readNum, Reg#(Bit#(2)))     counter <- replicateM(mkReg(2));
    Vector#(readNum, Reg#(Bool))   readReqEnReg <- replicateM(mkReg(False));
    Vector#(readNum, PulseWire)       readReqEn <- replicateM(mkPulseWire);
    Vector#(readNum, PulseWire)      readRespEn <- replicateM(mkPulseWire);

    for(Integer i = 0; i < valueOf(readNum); i = i + 1)
    begin
        rule enqInto(readReqEnReg[i]);
            dataT data = ((i%2) == 0)? ram[i/2].portResp1(): ram[i/2].portResp2();
            buffer[i].enq(data);
        endrule

        rule alwaysBlock(True);
            readReqEnReg[i] <= readReqEn[i];
            if(readReqEn[i] && !readRespEn[i])
                counter[i] <= counter[i] - 1;
            else if(!readReqEn[i] && readRespEn[i])
                counter[i] <= counter[i] + 1;
        endrule
    end

    Vector#(readNum, ReadReq#(addrSz)) reqLocal = newVector();
    Vector#(readNum, ReadResp#(dataT)) respLocal = newVector();
    for(Integer i = 0; i < valueOf(readNum); i = i + 1)
    begin
        reqLocal[i] = ( interface ReadReq;
                            method Action read(Bit#(addrSz) addr) if(counter[i] > 0);
                                if((i%2) == 0)
                                    ram[i/2].portReq1(addr, ?, False);
                                else
                                    ram[i/2].portReq2(addr, ?, False);
                                readReqEn[i].send();
                            endmethod
                        endinterface);

        respLocal[i] = (interface ReadResp;
                            method ActionValue#(dataT) read();
                                readRespEn[i].send();
                                dataT data = buffer[i].first();
                                buffer[i].deq();
                                return data;
                            endmethod
                        endinterface);
    end

    Vector#(2, Write#(addrSz, dataT)) writeLocal = newVector();
    for(Integer i = 0; i < 2; i = i + 1)
    begin
        writeLocal[i] = (   interface Write;
                                method Action write(Bit#(addrSz) addr, dataT data);
                                    for(Integer j = 0; j < valueOf(bramNum); j = j + 1)
                                    begin
                                        if((i%2) == 0)
                                            ram[j].portReq1(addr, data, True);
                                        else
                                            ram[j].portReq2(addr, data, True);
                                    end
                                endmethod
                            endinterface);
    end

    interface req = reqLocal;
    interface resp = respLocal;
    interface write = writeLocal;

    method Bool noPending();
        Vector#(readNum, Bool) noPends = newVector();
        for(Integer i = 0; i < valueOf(readNum); i = i + 1)
            noPends[i] = counter[i] == 2;
        return fold(andBool, noPends);
    endmethod
endmodule

module mkMultiReadBram(MultiReadBram#(readNum, addrSz, dataT))
    provisos(Bits#(dataT, dataSz),
             Add#(1, pos, readNum));

    MultiPortBram#(readNum, 2, addrSz, dataT) bram <- mkDualWriteMultiReadBram();

    interface req = bram.req;
    interface resp = bram.resp;
    method write = bram.write[1].write;
    method noPending = bram.noPending;
endmodule

module mkBram(Bram#(addrSz, dataT))
    provisos(Bits#(dataT, dataSz));

    MultiReadBram#(1, addrSz, dataT) bram <- mkMultiReadBram();

    method readReq = bram.req[0].read;
    method readResp = bram.resp[0].read;
    method write = bram.write;
    method noPending = bram.noPending;
endmodule

module mkDualWriteMultiReadBramInitialized#(dataT init)(MultiPortBram#(readNum, 2, addrSz, dataT))
    provisos(Bits#(dataT, dataSz),
             Add#(1, pos, readNum),
             Add#(addrSz, 1, index1Sz));

    MultiPortBram#(readNum, 2, addrSz, dataT) bram <- mkDualWriteMultiReadBram();
    Reg#(Bit#(index1Sz)) initialize <- mkReg(0);
    Bool initialized = initialize[valueOf(addrSz)] == 1;

    rule initializing(!initialized);
        bram.write[0].write(truncate(initialize), init);
        initialize <= initialize + 1;
    endrule

    Vector#(readNum, ReadReq#(addrSz)) reqLocal = newVector();
    Vector#(readNum, ReadResp#(dataT)) respLocal = newVector();
    for(Integer i = 0; i < valueOf(readNum); i = i + 1)
    begin
        reqLocal[i] = ( interface ReadReq;
                            method Action read(Bit#(addrSz) addr) if(initialized);
                                bram.req[i].read(addr);
                            endmethod
                        endinterface);

        respLocal[i] = (interface ReadResp;
                            method ActionValue#(dataT) read() if(initialized);
                                dataT data <- bram.resp[i].read();
                                return data;
                            endmethod
                        endinterface);
    end

    Vector#(2, Write#(addrSz, dataT)) writeLocal = newVector();
    for(Integer i = 0; i < 2; i = i + 1)
    begin
        writeLocal[i] = (   interface Write;
                                method Action write(Bit#(addrSz) addr, dataT data) if(initialized);
                                    bram.write[i].write(addr, data);
                                endmethod
                            endinterface);
    end

    interface req = reqLocal;
    interface resp = respLocal;
    interface write = writeLocal;

    method Bool noPending() if(initialized);
        return bram.noPending();
    endmethod
endmodule

module mkMultiReadBramInitialized#(dataT init)(MultiReadBram#(readNum, addrSz, dataT))
    provisos(Bits#(dataT, dataSz),
             Add#(1, pos, readNum));

    MultiPortBram#(readNum, 2, addrSz, dataT) bram <- mkDualWriteMultiReadBramInitialized(init);

    interface req = bram.req;
    interface resp = bram.resp;
    method write = bram.write[1].write;
    method noPending = bram.noPending;
endmodule

module mkBramInitialized#(dataT init)(Bram#(addrSz, dataT))
    provisos(Bits#(dataT, dataSz));

    MultiReadBram#(1, addrSz, dataT) bram <- mkMultiReadBramInitialized(init);

    method readReq = bram.req[0].read;
    method readResp = bram.resp[0].read;
    method write = bram.write;
    method noPending = bram.noPending;
endmodule

module mkDualWriteMultiReadBramInitializedTest(MultiPortBram#(8, 2, 9, Bit#(32)));
    MultiPortBram#(8, 2, 9, Bit#(32)) bram <- mkDualWriteMultiReadBramInitialized(23);

    return bram;
endmodule
