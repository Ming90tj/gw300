
`timescale 1 ns / 1 ps

	module IQ_Transmit_v1_0_S00_AXIS #
	(
		// Users to add parameters here
        parameter integer IQ_WIDTH = 2,
		// User parameters ends
		// Do not modify the parameters beyond this line

		// AXI4Stream sink: Data Width
		parameter integer C_S_AXIS_TDATA_WIDTH	= 32
	)
	(
		// Users to add ports here
        output wire [IQ_WIDTH -1 :0 ] IQ_TXD,
        output wire CLK32,
		input  wire CLK32_IN,
		input  wire LOCKED,
		output wire POWER_DOWN,
		// User ports ends
		// Do not modify the ports beyond this line

		// AXI4Stream sink: Clock
		input wire  S_AXIS_ACLK,
		// AXI4Stream sink: Reset
		input wire  S_AXIS_ARESETN,
		// Ready to accept data in
		output wire  S_AXIS_TREADY,
		// Data in
		input wire [C_S_AXIS_TDATA_WIDTH-1 : 0] S_AXIS_TDATA,
		// Byte qualifier
		input wire [(C_S_AXIS_TDATA_WIDTH/8)-1 : 0] S_AXIS_TSTRB,
		// Indicates boundary of last packet
		input wire  S_AXIS_TLAST,
		// Data is in valid
		input wire  S_AXIS_TVALID
	);
	// function called clogb2 that returns an integer which has the 
	// value of the ceiling of the log base 2.
	function integer clogb2 (input integer bit_depth);
	  begin
	    for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
	      bit_depth = bit_depth >> 1;
	  end
	endfunction

	// Total number of input data.
	localparam NUMBER_OF_INPUT_WORDS  = 8;
	// bit_num gives the minimum number of bits needed to address 'NUMBER_OF_INPUT_WORDS' size of FIFO.
	localparam bit_num  = clogb2(NUMBER_OF_INPUT_WORDS-1);
	// Define the states of state machine
	// The control state machine oversees the writing of input streaming data to the FIFO,
	// and outputs the streaming data from the FIFO
	localparam [1:0] IDLE = 1'b0,        // This is the initial/idle state 

	                WRITE_FIFO  = 1'b1; // In this state FIFO is written with the
	                                    // input stream data S_AXIS_TDATA 
	wire  	axis_tready;
	// State variable
	reg mst_exec_state;  
	// FIFO implementation signals
//	genvar byte_index;     
	// FIFO write enable
	wire fifo_wren;
	// FIFO full flag
	reg fifo_full_flag;
	// FIFO write pointer
	reg [bit_num -1:0] write_pointer;
	// sink has accepted all the streaming data and stored in FIFO
	reg writes_done;
	// I/O Connections assignments
    
    //----------------User defined------------------//
	
	localparam i_base = 0;
	localparam q_base = 16;
	reg  [4:0] status = 0;
	reg  [1:0] iq_txd;
	wire [bit_num -1:0] wp_wire;
    wire locked;
	wire iq_start_wire;
	wire iq_next_wire;
	wire next_go;
	wire iq_end_wire;
	reg wp_clear;
    reg power_down;
    reg fifo_rden;
    reg iq_start;
	reg iq_next;
	reg next_2;
	reg next_1;
	reg readygo;
	reg first;
	reg iq_end = 1'b0;
    reg [bit_num -1: 0] read_pointer;
    reg [C_S_AXIS_TDATA_WIDTH - 1 : 0] stream_data_fifo [NUMBER_OF_INPUT_WORDS -1 : 0];
    reg [C_S_AXIS_TDATA_WIDTH - 1 : 0] iq_buffer;
    assign   POWER_DOWN     = power_down;
	assign 	 S_AXIS_TREADY	= axis_tready;
	assign   IQ_TXD         = iq_txd;
	assign   CLK32          = CLK32_IN;
	assign   locked         = LOCKED;
	assign	 iq_start_wire  =iq_start;
	assign	 iq_next_wire   =iq_next;
	assign   wp_wire        =write_pointer;
	assign	 iq_end_wire	=iq_end;
	// Control state machine implementation
	always @(posedge S_AXIS_ACLK) 
	begin  
	  if (!S_AXIS_ARESETN) 
	  // Synchronous reset (active low)
	    begin
	      mst_exec_state <= IDLE;
	    end  
	  else
	    case (mst_exec_state)
	      IDLE: 
	        // The sink starts accepting tdata when 
	        // there tvalid is asserted to mark the
	        // presence of valid streaming data 
	          if (S_AXIS_TVALID)
	            begin
	              mst_exec_state <= WRITE_FIFO;
	            end
	          else
	            begin
	              mst_exec_state <= IDLE;
	            end
	      WRITE_FIFO: 
	        // When the sink has accepted all the streaming input data,
	        // the interface swiches functionality to a streaming master
	        if (writes_done)
	          begin
	            mst_exec_state <= IDLE;
	          end
	        else
	          begin
	            // The sink accepts and stores tdata 
	            // into FIFO
	            mst_exec_state <= WRITE_FIFO;
	          end

	    endcase
	end
	// AXI Streaming Sink 
	// 
	// The example design sink is always ready to accept the S_AXIS_TDATA  until
	// the FIFO is not filled with NUMBER_OF_INPUT_WORDS number of input words.
	assign axis_tready = ((mst_exec_state == WRITE_FIFO) && readygo);

	always@(posedge S_AXIS_ACLK)
	begin
	  if(!S_AXIS_ARESETN)
	    begin
	      write_pointer <= 0;
	      writes_done <= 1'b0;
	    end  
	  else
		if(wp_clear && writes_done)begin
			write_pointer	= 0;
			end
			
	    if (fifo_wren)
	      begin
	        if ((write_pointer == NUMBER_OF_INPUT_WORDS-1)|| S_AXIS_TLAST)
	          begin
				// reads_done is asserted when NUMBER_OF_INPUT_WORDS numbers of streaming data 
				// has been written to the FIFO which is also marked by S_AXIS_TLAST(kept for optional usage).
				stream_data_fifo[write_pointer] <= S_AXIS_TDATA;
				writes_done <= 1'b1;

	          end
			else begin
		        // write pointer is incremented after every write to the FIFO
	            // when FIFO write signal is enabled.
				stream_data_fifo[write_pointer] <= S_AXIS_TDATA ;
	            write_pointer <= write_pointer + 1;
	            writes_done <= 1'b0;
	            end
	      end  
	end

	// FIFO write enable generation
	assign fifo_wren = S_AXIS_TVALID && axis_tready;

	// FIFO Implementation 8x8 FIFO 
//	generate 
//	  for(byte_index=0; byte_index<= (C_S_AXIS_TDATA_WIDTH/8-1); byte_index=byte_index+1)
//	  begin:FIFO_GEN

//	    reg  [(C_S_AXIS_TDATA_WIDTH/4)-1:0] stream_data_fifo [0 : NUMBER_OF_INPUT_WORDS-1];

//	    // Streaming input data is stored in FIFO

//	    always @( posedge S_AXIS_ACLK )
//	    begin
//	      if (fifo_wren)// && S_AXIS_TSTRB[byte_index])
//	        begin
//	          stream_data_fifo[write_pointer] <= S_AXIS_TDATA[(byte_index*8+7) -: 8];
//	        end  
//	    end  
//	  end		
//	endgenerate
    
	// Add user logic here
	
	//generate the fifo_rden
	
	always @( posedge S_AXIS_ACLK)
	begin 
	   if(!S_AXIS_ARESETN)
            begin
                fifo_rden  <= 1'b0;
                power_down <= 1'b1;
            end
       else
           if(writes_done && write_pointer >0)
               begin
                   fifo_rden  <= 1'b1;
                   power_down <= 1'b0;
               end
			else
				begin
					fifo_rden <=1'b0;
				end
    end
    
    //generate the read_pointer
    
    always @(posedge S_AXIS_ACLK)
    begin
        if(!S_AXIS_ARESETN)
            begin
                read_pointer <= 0;
                iq_start     <=1'b0;
				iq_buffer	 <= 0;
				readygo      <=1'b1;
				first		 <=1'b1;
				wp_clear     <=1'b0;
            end
        else	begin
			wp_clear <=1'b0;
            if( fifo_rden  && (next_go || first)  &&  locked )
                begin
					first <= 1'b0;
					if(wp_wire == NUMBER_OF_INPUT_WORDS-1)begin
						iq_buffer 	<= stream_data_fifo [read_pointer];
						iq_start	<= 1'b1;
						if (read_pointer == wp_wire)begin
							read_pointer <= 0;
							wp_clear	 <= 1'b1;
							readygo		 <= 1'b1;
							end
						else begin
							readygo		 <= 1'b0;
							read_pointer <= read_pointer + 1;
						end
					end
					else begin
						iq_buffer 	 <= stream_data_fifo [read_pointer];
						iq_start	 <= 1'b1;
						read_pointer <= read_pointer + 1;
						if (read_pointer == wp_wire)begin
							read_pointer <= 0;
							wp_clear	 <= 1'b1;
							readygo		 <= 1'b1;
							end
						else begin
							readygo		<=1'b0;
							end
					end
				end
			if( (!fifo_rden) && iq_end_wire) begin
				iq_start	<=1'b0;
				end
		end
    end
    
   
	
	//control of iq transmit proccess 
	always@ (posedge S_AXIS_ACLK)
	begin
		if(!S_AXIS_ARESETN)begin
			next_1 <= 1'b0;
			next_2 <= 1'b0;
			end
		else begin
			{next_2,next_1} = {next_1,iq_next_wire};
			end
	end
	
	assign next_go = ~next_1 && next_2;
	
	
	
	//IQ transmit proccess
	
    always @(posedge CLK32)
	begin
		iq_next <= 1'b0;

		if(iq_start_wire)
			begin
				iq_end <=1'b0;
				case(status)
				
				5'd0:begin
						iq_txd[0] <= iq_buffer[i_base + status];
						iq_txd[1] <= iq_buffer[q_base + status];
						status <= status + 1;
					end
				
				5'd1:begin
						iq_txd[0] <= iq_buffer[i_base + status];
						iq_txd[1] <= iq_buffer[q_base + status];
						status <= status + 1;
					end
				
				5'd2:begin
						iq_txd[0] <= iq_buffer[i_base + status];
						iq_txd[1] <= iq_buffer[q_base + status];
						status <= status + 1;
					end
				
				5'd3:begin
						iq_txd[0] <= iq_buffer[i_base + status];
						iq_txd[1] <= iq_buffer[q_base + status];
						status <= status + 1;
					end
				
				5'd4:begin
						iq_txd[0] <= iq_buffer[i_base + status];
						iq_txd[1] <= iq_buffer[q_base + status];
						status <= status + 1;
					end
					
				5'd5:begin
						iq_txd[0] <= iq_buffer[i_base + status];
						iq_txd[1] <= iq_buffer[q_base + status];
						status <= status + 1;
					end
					
				5'd6:begin
						iq_txd[0] <= iq_buffer[i_base + status];
						iq_txd[1] <= iq_buffer[q_base + status];
						status <= status + 1;
					end
				5'd7:begin
						iq_txd[0] <= iq_buffer[i_base + status];
						iq_txd[1] <= iq_buffer[q_base + status];
						status <= status + 1;
					end
					
				5'd8:begin
						iq_txd[0] <= iq_buffer[i_base + status];
						iq_txd[1] <= iq_buffer[q_base + status];
						status <= status + 1;
					end

				5'd9:begin
						iq_txd[0] <= iq_buffer[i_base + status];
						iq_txd[1] <= iq_buffer[q_base + status];
						status <= status + 1;
					end

				5'd10:begin
						iq_txd[0] <= iq_buffer[i_base + status];
						iq_txd[1] <= iq_buffer[q_base + status];
						status <= status + 1;
					end

				5'd11:begin
						iq_txd[0] <= iq_buffer[i_base + status];
						iq_txd[1] <= iq_buffer[q_base + status];
						status <= status + 1;
					end

				5'd12:begin
						iq_txd[0] <= iq_buffer[i_base + status];
						iq_txd[1] <= iq_buffer[q_base + status];
						status <= status + 1;
					end

				5'd13:begin
						iq_txd[0] <= iq_buffer[i_base + status];
						iq_txd[1] <= iq_buffer[q_base + status];
						status <= status + 1;
					end

				5'd14:begin
						iq_txd[0] <= iq_buffer[i_base + status];
						iq_txd[1] <= iq_buffer[q_base + status];
						status <= status + 1;
					end

				5'd15:begin
						iq_txd[0] <= iq_buffer[i_base + status];
						iq_txd[1] <= iq_buffer[q_base + status];
						status <= 5'd0;
						iq_next<= 1'b1;
						if(!fifo_rden)begin
							status <= 5'd16;
							end
					end
					
				5'd16:begin
						iq_txd <= 2'bzz;
						status <= 5'd0;
						iq_end <= 1'b1;
					end
					
			 endcase
	      end
	 end
	
	// User logic ends

	endmodule
