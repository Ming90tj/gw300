`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/04/19 17:07:24
// Design Name: 
// Module Name: testbench
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module testbench(
 );
 reg [31:0] tdata;
 reg tlast;
 wire tready;
 reg tvalid;
 reg reset_clk;
 reg reset;
 reg clk100;
 wire clk32;
 wire [1:0] iq;
  design_1_wrapper u1
   (.S_AXIS_tdata(tdata),
    .S_AXIS_tlast(tlast),
    .S_AXIS_tready(tready),
    .S_AXIS_tvalid(tvalid),
    .aresetn(reset),
    .clk100(clk100),
    .clk32(clk32),
    .iq_txd(iq),
    .reset(reset_clk));
    
    always begin
    #5 clk100 =~clk100;
    end
    
    initial
    begin 
    tdata = 32'b0 ;
    tlast = 1'b0;
    tvalid= 1'b0;
    clk100 =1'b0;
    reset = 1'b1;
    reset_clk = 1'b0;
    
    #10 
    reset =1'b0;
    reset_clk =1'b1;
    
    #10
    reset =1'b1;
    reset_clk =1'b0;
    //1
    #75
    tdata = 32'd1431655765;
    
    #1
    tvalid =1'b1;
    
    #10
    tdata = 32'd0;
    tvalid =1'b0;
    //2
    #1
    tdata =32'd65535;
    tvalid =1'b1;
    #10
    tdata = 32'd0;
    tvalid =1'b0;
    //3
    #1
    tdata = 32'd4294901760;
    tvalid =1'b1;
    #10
    tdata = 32'd0;
    tvalid =1'b0;
    //4
    #1
    tdata = 32'd1431655765;
    tvalid =1'b1;
    #10
    tdata = 32'd0;
    tvalid =1'b0;
    //5
    #1
    tdata =32'd65535;
    tvalid =1'b1;
    #10
    tdata = 32'd0;
    tvalid =1'b0;
    //6
    #1
    tdata = 32'd4294901760;
    tvalid =1'b1;

    #10
    tdata = 32'd0;
    tvalid =1'b0;

    //7
    #1
    tdata =32'd65535;
    tvalid =1'b1;
    tlast =1'b1;
    #10
    tdata = 32'd0;
    tvalid =1'b0;
    tlast  =1'b0;
    //8
//      #1
//      tdata = 32'd4294901760;
//      tvalid =1'b1;
//      tlast = 1'b1;
//      #10
//      tdata = 32'd0;
//      tvalid =1'b0;
//      tlast =1'b0;
//      #1
//      tdata =32'd65535;
//      tvalid =1'b1;
//      #10
//      tdata = 32'd0;
//      tvalid =1'b0;
    
//      #1
//      tdata = 32'd4294901760;
//      tvalid =1'b1;
//      tlast = 1'b1;
//      #10
//      tdata = 32'd0;
//      tvalid =1'b0;
//      tlast = 1'b0;                  
    #10000;
    end
endmodule
