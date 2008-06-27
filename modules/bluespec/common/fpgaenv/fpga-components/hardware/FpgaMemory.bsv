import FIFOF::*;
import Vector::*;
import RegFile::*;
import RWire::*;

interface ReadReq#(numeric type addrSz);
    method Action read(Bit#(addrSz) addr);
endinterface

interface ReadResp#(type dataT);
    method ActionValue#(dataT) read();
endinterface

interface Write#(numeric type addrSz, type dataT);
    method Action write(Bit#(addrSz) addr, dataT data);
endinterface

interface Bram#(numeric type addrSz, type dataT);
    method Action readReq(Bit#(addrSz) addr);
    method ActionValue#(dataT) readResp();
    method Action write(Bit#(addrSz) addr, dataT data);
    method Bool noPending();
endinterface

interface MultiReadBram#(numeric type readNum, numeric type addrSz, type dataT);
    interface Vector#(readNum, ReadReq#(addrSz)) req;
    interface Vector#(readNum, ReadResp#(dataT)) resp;
    method Action write(Bit#(addrSz) addr, dataT data);
    method Bool noPending();
endinterface

function Bool andBool(Bool a, Bool b);
    return a && b;
endfunction

import "BVI" Bram =
module mkUnguardedBramNonZero(Bram#(addrSz, dataT))
    provisos(Bits#(dataT, dataSz));

    parameter addrSize = valueOf(addrSz);
    parameter dataSize = valueOf(dataSz);
    parameter numRows = valueOf(TExp#(addrSz));

    method readReq(readAddr) enable(readEnable) ready(readReady);
    method readData readResp() enable(readDataEnable) ready(readDataReady);
    method write(writeAddr, writeData) enable(writeEnable) ready(writeReady);
    method noPendingBool noPending();

    schedule readReq C readReq;
    schedule readResp C readResp;
    schedule write C write;
    schedule readReq CF (readResp, write);
    schedule readResp CF write;
    schedule noPending CF (noPending, readReq, readResp, write);
endmodule

module mkUnguardedBramZero(Bram#(addrSz, dataT))
    provisos(Bits#(dataT, dataSz));

    method Action readReq(Bit#(addrSz) addr);
        noAction;
    endmethod

    method ActionValue#(dataT) readResp();
        return ?;
    endmethod

    method Action write(Bit#(addrSz) addr, dataT data);
        noAction;
    endmethod

    method Bool noPending();
        return True;
    endmethod
endmodule

module mkUnguardedBramSim(Bram#(addrSz, dataT))
    provisos(Bits#(dataT, dataSz));

    RegFile#(Bit#(addrSz), dataT) ram <- mkRegFileFull();
    Reg#(dataT)             outputReg <- mkRegU;

    method Action readReq(Bit#(addrSz) addr);
        outputReg <= ram.sub(addr);
    endmethod

    method ActionValue#(dataT) readResp();
        return outputReg;
    endmethod

    method Action write(Bit#(addrSz) addr, dataT data);
        ram.upd(addr, data);
    endmethod

    method Bool noPending();
        return True;
    endmethod
endmodule

module mkUnguardedBram(Bram#(addrSz, dataT))
    provisos(Bits#(dataT, dataSz));

    `ifdef SYNTH
    Bram#(addrSz, dataT) mem <- (valueOf(addrSz) == 0 || valueOf(dataSz) == 0)? mkUnguardedBramZero(): mkUnguardedBramNonZero();
    `else
    Bram#(addrSz, dataT) mem <- mkUnguardedBramSim();
    `endif
    return mem;
endmodule

module mkBram(Bram#(addrSz, dataT))
    provisos(Bits#(dataT, dataSz));

    Bram#(addrSz, dataT) ram <- mkUnguardedBram();
    FIFOF#(dataT) buffer <- mkFIFOF();
    Reg#(Bit#(2)) counter <- mkReg(2);
    Reg#(Bool) readReqEnReg <- mkReg(False);
    PulseWire readReqEn <- mkPulseWire;
    PulseWire readRespEn <- mkPulseWire;

    rule enqIntoFifo(readReqEnReg);
        dataT data <- ram.readResp();
        buffer.enq(data);
    endrule

    rule alwaysBlock(True);
        readReqEnReg <= readReqEn;
        if(readReqEn && !readRespEn)
            counter <= counter - 1;
        else if(!readReqEn && readRespEn)
            counter <= counter + 1;
    endrule

    method Action readReq(Bit#(addrSz) addr) if(counter > 0);
        ram.readReq(addr);
        readReqEn.send();
    endmethod

    method ActionValue#(dataT) readResp();
        readRespEn.send();
        dataT data = buffer.first();
        buffer.deq();
        return data;
    endmethod

    method Action write(Bit#(addrSz) addr, dataT data);
        ram.write(addr, data);
    endmethod

    method Bool noPending();
        return counter == 2;
    endmethod
endmodule

module mkMultiReadBram(MultiReadBram#(readNum, addrSz, dataT))
    provisos(Bits#(dataT, dataSz));

    Vector#(readNum, Bram#(addrSz, dataT)) ram <- replicateM(mkBram());

    Vector#(readNum, ReadReq#(addrSz))         reqLocal = newVector();
    Vector#(readNum, ReadResp#(dataT))        respLocal = newVector();

    for(Integer i = 0; i < valueOf(readNum); i = i + 1)
    begin
        reqLocal[i] = (interface ReadReq#(addrSz);
                           method read = ram[i].readReq;
                       endinterface);

        respLocal[i] = (interface ReadResp#(dataT);
                            method read = ram[i].readResp;
                        endinterface);
    end

    interface req = reqLocal;
    interface resp = respLocal;

    method Action write(Bit#(addrSz) addr, dataT data);
        for(Integer i = 0; i < valueOf(readNum); i = i + 1)
            ram[i].write(addr, data);
    endmethod

    method Bool noPending();
        Vector#(readNum, Bool) noPendings = newVector();
        for(Integer i = 0; i < valueOf(readNum); i = i + 1)
            noPendings[i] = ram[i].noPending();
        return foldl(andBool, True, noPendings);
    endmethod
endmodule

module mkBramInitialized#(dataT init)(Bram#(indexSz, dataT))
    provisos(Bits#(dataT, dataSz),
             Add#(indexSz, 1, index1Sz));

    Bram#(indexSz, dataT) mem <- mkBram();
    Reg#(Bit#(index1Sz))   initialize <- mkReg(0);

    Bool initialized = initialize[valueOf(indexSz)] == 1;

    rule initializing(!initialized);
        mem.write(truncate(initialize), init);
        initialize <= initialize + 1;
    endrule

    method Action readReq(Bit#(indexSz) index) if(initialized);
        mem.readReq(index);
    endmethod

    method ActionValue#(dataT) readResp() if(initialized);
        dataT resp <- mem.readResp();
        return resp;
    endmethod

    method Action write(Bit#(indexSz) index, dataT data) if(initialized);
        mem.write(index, data);
    endmethod

    method Bool noPending() if(initialized);
        return mem.noPending();
    endmethod
endmodule

module mkMultiReadBramInitialized#(dataT init)(MultiReadBram#(readNum, addrSz, dataT))
    provisos(Bits#(dataT, dataSz),
             Add#(addrSz, 1, addr1Sz));

    Vector#(readNum, Bram#(addrSz, dataT)) ram <- replicateM(mkBramInitialized(init));

    Vector#(readNum, ReadReq#(addrSz))         reqLocal = newVector();
    Vector#(readNum, ReadResp#(dataT))        respLocal = newVector();

    for(Integer i = 0; i < valueOf(readNum); i = i + 1)
    begin
        reqLocal[i] = (interface ReadReq#(addrSz);
                           method read = ram[i].readReq;
                       endinterface);

        respLocal[i] = (interface ReadResp#(dataT);
                            method read = ram[i].readResp;
                        endinterface);
    end

    interface req = reqLocal;
    interface resp = respLocal;

    method Action write(Bit#(addrSz) addr, dataT data);
        for(Integer i = 0; i < valueOf(readNum); i = i + 1)
            ram[i].write(addr, data);
    endmethod

    method Bool noPending();
        Vector#(readNum, Bool) noPendings = newVector();
        for(Integer i = 0; i < valueOf(readNum); i = i + 1)
            noPendings[i] = ram[i].noPending();
        return foldl(andBool, True, noPendings);
    endmethod
endmodule

module mkBramTest();
    MultiReadBram#(2, 8, Bit#(32)) ram <- mkMultiReadBramInitialized(23);
    Reg#(Bit#(10)) counter <- mkReg(0);

    rule count(True);
        counter <= counter + 1;
        if(counter == maxBound)
            $finish(0);
    endrule

    rule write(True);
        ram.write(truncate(counter), zeroExtend(counter));
        $display("write: %0d %0d %0d", counter, counter, $time);
    endrule

    rule readReq(counter >= 100);
        ram.req[0].read(truncate(counter - 100));
        $display("readReq: %0d %0d", counter-100, $time);
    endrule

    rule readResp(counter >= 200);
        Bit#(32) val <- ram.resp[0].read();
        $display("readResp: %0d %0d", val, $time);
    endrule
endmodule

/*
interface Read#(numeric type addrSz, type dataT);
    method ActionValue#(dataT) read(Bit#(addrSz) addr);
endinterface

interface RegisterFile#(numeric type addrSz, type dataT);
    method ActionValue#(dataT) read(Bit#(addrSz) addr);
    method Action write(Bit#(addrSz) addr, dataT data);
endinterface

interface MultiReadRegisterFile#(numeric type readNum, numeric type addrSz, type dataT);
    interface Vector#(readNum, Read#(addrSz, dataT)) read;
    method Action write(Bit#(addrSz) addr, dataT data);
endinterface

import "BVI" RegisterFile =
module mkRegisterFileNonZero(RegisterFile#(addrSz, dataT))
    provisos(Bits#(dataT, dataSz));

    parameter addrSize = valueOf(addrSz);
    parameter dataSize = valueOf(dataSz);
    parameter numRows = valueOf(TExp#(addrSz));

    method readData read(readAddr) enable(readEnable) ready(readReady);
    method write(writeAddr, writeData) enable(writeEnable) ready(writeReady);

    schedule read C read;
    schedule write C write;
    schedule read CF write;
endmodule

module mkRegisterFile(RegisterFile#(addrSz, dataT))
    provisos(Bits#(dataT, dataSz));

    RegFile#(Bit#(addrSz), dataT) ram <- mkRegFileFull();
    Wire#(void)                 dummy <- mkWire();

    method ActionValue#(dataT) read(Bit#(addrSz) addr);
        dummy <= ?;
        return ram.sub(addr);
    endmethod

    method Action write(Bit#(addrSz) addr, dataT data);
        ram.upd(addr, data);
    endmethod
endmodule

module mkMultiReadRegisterFile(MultiReadRegisterFile#(readNum, addrSz, dataT))
    provisos(Bits#(dataT, dataSz));

    Vector#(readNum, RegisterFile#(addrSz, dataT))    ram <- replicateM(mkRegisterFile());
    Vector#(readNum, Read#(addrSz, dataT)) readLocal = newVector();

    for(Integer i = 0; i < valueOf(readNum); i = i + 1)
    begin
        readLocal[i] = (interface Read#(addrSz, dataT);
                            method read = ram[i].read;
                        endinterface);
    end

    interface read = readLocal;

    method Action write(Bit#(addrSz) addr, dataT data);
        for(Integer i = 0; i < valueOf(readNum); i = i + 1)
            ram[i].write(addr, data);
    endmethod
endmodule

module mkRegisterFileInitialized#(dataT init)(RegisterFile#(addrSz, dataT))
    provisos(Bits#(dataT, dataSz),
             Add#(addrSz, 1, addr1Sz));

    RegisterFile#(addrSz, dataT)     mem <- mkRegisterFile();
    Reg#(Bit#(addr1Sz)) initialize <- mkReg(0);

    Bool initialized = initialize[valueOf(addrSz)] == 1;

    rule initializing(!initialized);
        initialize <= initialize + 1;
        mem.write(truncate(initialize), init);
    endrule

    method ActionValue#(dataT) read(Bit#(addrSz) addr) if(initialized);
        dataT data <- mem.read(addr);
        return data;
    endmethod

    method Action write(Bit#(addrSz) addr, dataT data) if(initialized);
        mem.write(addr, data);
    endmethod
endmodule

module mkMultiReadRegisterFileInitialized#(dataT init)(MultiReadRegisterFile#(readNum, addrSz, dataT))
    provisos(Bits#(dataT, dataSz),
             Add#(addrSz, 1, addr1Sz));

    Vector#(readNum, RegisterFile#(addrSz, dataT)) ram <- replicateM(mkRegisterFile());
    Reg#(Bit#(addr1Sz))               initialize <- mkReg(0);

    Vector#(readNum, Read#(addrSz, dataT)) readLocal = newVector();
    Bool initialized = initialize[valueOf(addrSz)] == 1;

    rule initializing(!initialized);
        initialize <= initialize + 1;
        for(Integer i = 0; i < valueOf(readNum); i = i + 1)
            ram[i].write(truncate(initialize), init);
    endrule

    for(Integer i = 0; i < valueOf(readNum); i = i + 1)
    begin
        readLocal[i] = (interface Read#(addrSz, dataT);
                            method ActionValue#(dataT) read(Bit#(addrSz) addr) if(initialized);
                                dataT data <- ram[i].read(addr);
                                return data;
                            endmethod
                        endinterface);
    end

    interface read = readLocal;

    method Action write(Bit#(addrSz) addr, dataT data) if(initialized);
        for(Integer i = 0; i < valueOf(readNum); i = i + 1)
            ram[i].write(addr, data);
    endmethod
endmodule

module mkRegisterFileTest();
    MultiReadRegisterFile#(2, 8, Bit#(32)) ram <- mkMultiReadRegisterFileInitialized(23);
    Reg#(Bit#(10)) counter <- mkReg(0);

    rule count(True);
        counter <= counter + 1;
        if(counter == maxBound)
            $finish(0);
    endrule

    rule write(True);
        ram.write(truncate(counter), zeroExtend(counter));
        $display("write: %0d %0d %0d", counter, counter, $time);
    endrule

    rule read(counter >= 100);
        let val = ram.read[0].read(truncate(counter - 100));
        $display("readReq: %0d %0d %0d", counter-100, val, $time);
    endrule
endmodule
*/
