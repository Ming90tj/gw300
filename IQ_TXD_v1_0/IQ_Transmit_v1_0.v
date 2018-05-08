
`timescale 1 ns / 1 ps

	module IQ_Transmit_v1_0 #
	(
		// Users to add parameters here
        parameter integer IQ_WIDTH = 2,
		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXIS
		parameter integer C_S00_AXIS_TDATA_WIDTH	= 32
	)
	(
		// Users to add ports here
        output wire [IQ_WIDTH -1 : 0] iq_txd,
		input  wire clk32_in,
        output wire clk32,
		input  wire locked,
		output wire power_down, 
		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S00_AXIS
		input wire  s00_axis_aclk,
		input wire  s00_axis_aresetn,
		output wire  s00_axis_tready,
		input wire [C_S00_AXIS_TDATA_WIDTH-1 : 0] s00_axis_tdata,
		input wire [(C_S00_AXIS_TDATA_WIDTH/8)-1 : 0] s00_axis_tstrb,
		input wire  s00_axis_tlast,
		input wire  s00_axis_tvalid
	);
// Instantiation of Axi Bus Interface S00_AXIS
	IQ_Transmit_v1_0_S00_AXIS # ( 
	    .IQ_WIDTH(IQ_WIDTH),
		.C_S_AXIS_TDATA_WIDTH(C_S00_AXIS_TDATA_WIDTH)
	) IQ_Transmit_v1_0_S00_AXIS_inst (
	    .IQ_TXD(iq_txd),
	    .CLK32(clk32),
		.CLK32_IN(clk32_in),
		.LOCKED(locked),
		.POWER_DOWN(power_down),
		.S_AXIS_ACLK(s00_axis_aclk),
		.S_AXIS_ARESETN(s00_axis_aresetn),
		.S_AXIS_TREADY(s00_axis_tready),
		.S_AXIS_TDATA(s00_axis_tdata),
		.S_AXIS_TSTRB(s00_axis_tstrb),
		.S_AXIS_TLAST(s00_axis_tlast),
		.S_AXIS_TVALID(s00_axis_tvalid)
	);

	// Add user logic here

	// User logic ends

	endmodule
