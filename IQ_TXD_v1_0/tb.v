`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/04/26 14:12:14
// Design Name: 
// Module Name: tb
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


module tb();

    reg [31:0] tdata;
    reg tlast;
    wire tready;
    reg tvalid;
    reg reset_clk;
    reg reset;
    reg clk200;
    wire clk32;
    wire [1:0] iq;
    
    design_1_wrapper u1
       (.S_AXIS_tdata(tdata),
        .S_AXIS_tlast(tlast),
        .S_AXIS_tready(tready),
        .S_AXIS_tvalid(tvalid),
        .clk32(clk32),
        .iq_txd(iq),
        .reset(reset_clk),
        .s_aclk(clk200),
        .s_aresetn(reset));
        
        always begin
        #2.5 clk200 =~clk200;
        end
        
        initial
        begin 
        tdata = 32'b0 ;
        tlast = 1'b0;
        tvalid= 1'b0;
        clk200 =1'b0;
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
        tdata = 32'd1431655765;//3
        tvalid =1'b1;
        #3
        tdata = 32'd0;
        tvalid =1'b0;
        //2
        #2
        tdata =32'd65535;//1
        tvalid =1'b1;
        #3
        tdata = 32'd0;
        tvalid =1'b0;
        //3
        #2
        tdata = 32'd4294901760;//2
        tvalid =1'b1;
        #3
        tdata = 32'd0;
        tvalid =1'b0;
        //4
        #2
        tdata = 32'd1431655765;
        tvalid =1'b1;
        #3
        tdata = 32'd0;
        tvalid =1'b0;
        //5
        #2
        tdata =32'd65535;
        tvalid =1'b1;
        #3
        tdata = 32'd0;
        tvalid =1'b0;
        //6
        #2
        tdata = 32'd4294901760;
        tvalid =1'b1;
        #3
        tdata = 32'd0;
        tvalid =1'b0;
        //7
        #2
        tdata =32'd1431655765;
        tvalid =1'b1;
        #3
        tdata = 32'd0;
        tvalid =1'b0;
        //8
        #2
        tdata = 32'd65535;
        tvalid =1'b1;
        #3
        tdata = 32'd0;
        tvalid =1'b0;
        //9
        #2
        tdata =32'd4294901760;
        tvalid =1'b1;
        #3
        tdata = 32'd0;
        tvalid =1'b0;
        //10
        #2
        tdata = 32'd1431786839;
        tvalid =1'b1;
        #3
        tdata = 32'd0;
        tvalid =1'b0;
        //11
        #2
        tdata = 32'd65535;
        tvalid =1'b1;
        #3
        tdata = 32'd0;
        tvalid =1'b0;
         //12
        #2
        tdata = 32'd1431655765;
        tvalid =1'b1;
        tlast = 1'b1;
        #3
        tdata = 32'd0;
        tvalid =1'b0;
        tlast = 1'b0;                          
        #10000;
        end
        
endmodule
