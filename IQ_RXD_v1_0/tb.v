`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/05/09 17:08:45
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


module tb(

    );
    reg [1:0] iq;
    wire [31:0] tdata;
    wire tlast;
    reg  tready;
    wire [3:0] tstrb;
    wire tvalid;
    wire locked;
    reg clk200;
    reg reset;
    wire clk32;
    
    design_1_wrapper u1
       (.IQ_RXD(iq),
        .M00_AXIS_tdata(tdata),
        .M00_AXIS_tlast(tlast),
        .M00_AXIS_tready(tready),
        .M00_AXIS_tstrb(tstrb),
        .M00_AXIS_tvalid(tvalid),
        .locked(locked),
        .clk_out1(clk32),
        .m00_axis_aclk(clk200),
        .m00_axis_aresetn(reset));
        
        always
        begin
        # 2.5 clk200 = ~clk200;
        end
        
        
        always @ (negedge clk32)
        begin
            if(locked)begin
                iq <= iq + 1;
                end
         end
		
		initial begin
		iq     = 0;
		tready = 0;
		clk200 = 0;
		reset  = 1;
		
		
		#50 reset = 0;
		#10 reset = 1;
		#10000;
		end
endmodule
