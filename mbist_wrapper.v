`timescale 1ns / 1ps

//TOP LEVEL MODULE DESIGN:

//Module Definition:
module TOP #(parameter wcount=256, wlength=4)(
  input wire start, rst, clk, rwbarin,
  input wire [wlength-1:0] datain,
  input wire [$clog2(wcount)-1:0] address,
  output wire [wlength-1:0] dataout,
  output reg fail
);

//Wires:
wire tmode, ud, rwbar, rwbartest, stop;
wire [$clog2(wcount)-1:0] addrmem, addrtest;
wire [$clog2(wcount)+3:0] count;
wire [wlength-1:0] datamem, datatest, ramout;
wire [3:0] decode_in;

//Module Instantiation:
BIST_controller BIST_CTRL (
  .start(start),
  .rst(rst),
  .clk(clk),
  .stop(stop),
  .tmode(tmode)
);

//Pipelining the test mode signal
reg [6:0] tmode_ppln;
always@(posedge clk) begin
  tmode_ppln[6:0] <= {tmode_ppln[5:0],tmode};
end

counter #(.length($clog2(wcount)+4)) CNT (
  .clk(clk),
  .ud(ud),
  .en(tmode),
  .rst(rst),
  .q(count),
  .stop(stop)
);

//Pipelining the test rwbar signal
reg [5:0] rwbartest_ppln;
always@(posedge clk) begin
  rwbartest_ppln[5:0] <= {rwbartest_ppln[4:0],rwbartest};
end

//Value Assignments:
assign ud = 1'b1;
assign rwbartest = ~count[$clog2(wcount)];
assign rwbar = (~tmode_ppln[3]) ? rwbarin:rwbartest_ppln[2];
assign addrtest = count[$clog2(wcount)-1:0];
assign decode_in = {count[0],count[$clog2(wcount)+3:$clog2(wcount)+1]};

//Pipelining the test address signal
reg [$clog2(wcount)-1:0] addrtest_ppln0, addrtest_ppln1;
always@(posedge clk) begin
  addrtest_ppln0 <= addrtest;
  addrtest_ppln1 <= addrtest_ppln0;
end

decoder #(.wlength(wlength)) DECODE (
  .clk(clk),
  .in(decode_in),
  .out(datatest)
);

//MUX data and address to memory
mux #(.length(wlength)) DMUX (
  .clk(clk),
  .sel(tmode_ppln[2]),
  .in0(datain),
  .in1(datatest),
  .out(datamem)
);

mux #(.length($clog2(wcount))) AMUX (
  .clk(clk),
  .sel(tmode_ppln[2]),
  .in0(address),
  .in1(addrtest_ppln1),
  .out(addrmem)
);

//SRAM Instantiation:
single_port_ram #(.wcount(wcount),.wlength(wlength)) RAM_MEM (
  .datain(datamem),
  .addr(addrmem),
  .we(rwbar),
  .clk(clk),
  .dataout(ramout)
);

//Pipelining the test data
reg [wlength-1:0] datatest_ppln0, datatest_ppln1, datatest_ppln2;
always@(posedge clk) begin
  datatest_ppln0 <= datatest;
  datatest_ppln1 <= datatest_ppln0;
  datatest_ppln2 <= datatest_ppln1;
end

//Comparator
comparator #(.wlength(wlength)) COMP (
  .clk(clk),
  .in1(datatest_ppln2),
  .in2(ramout),
  .out(eq)
);

//Fail Variable Check:
always @(posedge clk) begin
  if (rst) fail <= 1'b0;
  else begin
    if (tmode_ppln[6] && ~rwbartest_ppln[5]) fail <= ~eq;
    else fail <= 1'b0;
  end
end

//Dataout Assignment:
assign dataout = ramout;

endmodule

