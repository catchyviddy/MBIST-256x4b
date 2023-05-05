`timescale 1ns / 1ps

//SRAM:
module single_port_ram #(parameter wcount=256, wlength=4) (
  input wire [wlength-1:0] datain,
  input wire [$clog2(wcount)-1:0] addr,
  input wire we, clk,
  output reg [wlength-1:0] dataout
);

/* Declare the RAM variable - split into multiple RAMs */
reg [3:0] ram1[(wcount/4)-1:0];
reg [3:0] ram2[(wcount/4)-1:0];
reg [3:0] ram3[(wcount/4)-1:0];
reg [3:0] ram4[(wcount/4)-1:0];

/* Pipelining write address decode + Variable to hold the registered read address*/
reg [1:0] mem_sel, mem_sel_reg;
reg [$clog2(wcount)-3:0] mem_addr, mem_addr_reg;
reg [wlength-1:0] datain_reg;
reg we_reg;

always@(posedge clk) begin
  /*Write*/
  mem_sel <= addr[$clog2(wcount)-1:$clog2(wcount)-2];
  mem_addr <= addr[$clog2(wcount)-3:0];
  datain_reg <= datain;
  we_reg <= we;
  if (we_reg) begin
    case(mem_sel)
      'd0: ram1[mem_addr] <= datain_reg;
      'd1: ram2[mem_addr] <= datain_reg;
      'd2: ram3[mem_addr] <= datain_reg;
      'd3: ram4[mem_addr] <= datain_reg;
      default: ; //do nothing
    endcase
  end
  mem_sel_reg <= mem_sel;
  mem_addr_reg <= mem_addr;
end

/* Continuous assignment implies read returns NEW datain.
This is the natural behavior of the TriMatrix memory blocks in Single Port mode*/
always@(*) begin
  case(mem_sel_reg)
    'd0: dataout = ram1[mem_addr_reg];
    'd1: dataout = ram2[mem_addr_reg];
    'd2: dataout = ram3[mem_addr_reg];
    'd3: dataout = ram4[mem_addr_reg];
     default: ; //do nothing
  endcase
end
endmodule

