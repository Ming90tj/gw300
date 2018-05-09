
`timescale 1 ns / 1 ps

	module IQ_RXD_v1_0_M00_AXIS #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of S_AXIS address bus. The slave accepts the read and write addresses of width C_M_AXIS_TDATA_WIDTH.
		parameter integer C_M_AXIS_TDATA_WIDTH	= 32,
		// Start count is the number of clock cycles the master will wait before initiating/issuing any transaction.
		parameter integer C_M_START_COUNT	= 32
	)
	(
		// Users to add ports here
		input wire [1:0] IQ_RXD,
        input wire CLK32,
		// User ports ends
		// Do not modify the ports beyond this line

		// Global ports
		input wire  M_AXIS_ACLK,
		// 
		input wire  M_AXIS_ARESETN,
		// Master Stream Ports. TVALID indicates that the master is driving a valid transfer, A transfer takes place when both TVALID and TREADY are asserted. 
		output wire  M_AXIS_TVALID,
		// TDATA is the primary payload that is used to provide the data that is passing across the interface from the master.
		output wire [C_M_AXIS_TDATA_WIDTH-1 : 0] M_AXIS_TDATA,
		// TSTRB is the byte qualifier that indicates whether the content of the associated byte of TDATA is processed as a data byte or a position byte.
		output wire [(C_M_AXIS_TDATA_WIDTH/8)-1 : 0] M_AXIS_TSTRB,
		// TLAST indicates the boundary of a packet.
		output wire  M_AXIS_TLAST,
		// TREADY indicates that the slave can accept a transfer in the current cycle.
		input wire  M_AXIS_TREADY
	);
	// Total number of output data                                                 
	localparam NUMBER_OF_OUTPUT_WORDS = 8;                                               
	                                                                                     
	// function called clogb2 that returns an integer which has the                      
	// value of the ceiling of the log base 2.                                           
	function integer clogb2 (input integer bit_depth);                                   
	  begin                                                                              
	    for(clogb2=0; bit_depth>0; clogb2=clogb2+1)                                      
	      bit_depth = bit_depth >> 1;                                                    
	  end                                                                                
	endfunction                                                                          
	                                                                                     
	// WAIT_COUNT_BITS is the width of the wait counter.                                 
	localparam integer WAIT_COUNT_BITS = clogb2(C_M_START_COUNT-1);                      
	                                                                                     
	// bit_num gives the minimum number of bits needed to address 'depth' size of FIFO.  
	localparam bit_num  = clogb2(NUMBER_OF_OUTPUT_WORDS);                                
	                                                                                     
	// Define the states of state machine                                                
	// The control state machine oversees the writing of input streaming data to the FIFO,
	// and outputs the streaming data from the FIFO                                      
	localparam [1:0] IDLE = 2'b00,        // This is the initial/idle state               
	                                                                                     
	                INIT_COUNTER  = 2'b01, // This state initializes the counter, once   
	                                // the counter reaches C_M_START_COUNT count,        
	                                // the state machine changes state to SEND_STREAM     
	                SEND_STREAM   = 2'b10; // In this state the                          
	                                     // stream data is output through M_AXIS_TDATA   
	// State variable                                                                    
	reg [1:0] mst_exec_state;                                                            
	// Example design FIFO read pointer                                                  
	reg [bit_num-1:0] read_pointer;                                                      

	// AXI Stream internal signals
	//wait counter. The master waits for the user defined number of clock cycles before initiating a transfer.
	reg [WAIT_COUNT_BITS-1 : 0] 	count;
	//streaming data valid
	wire  	axis_tvalid;
	//streaming data valid delayed by one clock cycle
	reg  	axis_tvalid_delay;
	//Last of the streaming data 
	wire  	axis_tlast;
	//Last of the streaming data delayed by one clock cycle
	reg  	axis_tlast_delay;
	//FIFO implementation signals
	reg [C_M_AXIS_TDATA_WIDTH-1 : 0] 	stream_data_out;
	wire  	tx_en;
	//The master has issued all the streaming data stored in FIFO
	reg  	tx_done;


	// I/O Connections assignments

	assign M_AXIS_TVALID	= axis_tvalid_delay;
	assign M_AXIS_TDATA	= stream_data_out;
	assign M_AXIS_TLAST	= axis_tlast_delay;
	assign M_AXIS_TSTRB	= {(C_M_AXIS_TDATA_WIDTH/8){1'b1}};
	
	
	//----------------------- user defined ------------------------------
	//To Judge the clk32's pos and neg
	reg [2:0] counter_i;
	reg [1:0] counter_x;
	reg clk_1;
	reg clk_2;
	reg window_old;
	reg window_new;
	wire clk_pos;
	wire clk_hold;
	wire mid_tx_next;
	assign clk_pos = ~clk_2 & clk_1;
	assign clk_hold = ((~clk_1 & clk_2) || (~clk_2 & clk_1));
	assign mid_tx_next = ~window_old && window_new ;
	//FIFO status reg
	reg [C_M_AXIS_TDATA_WIDTH-1:0] stream_data_fifo [NUMBER_OF_OUTPUT_WORDS -1:0];
	reg [bit_num -1:0] write_pointer;
	reg clk_start;
	reg iq_last;
	
	//IQ receive processe
	reg [C_M_AXIS_TDATA_WIDTH-1:0] mid_buff;
	reg [(C_M_AXIS_TDATA_WIDTH)/2 -1:0] i_receive;
	reg [(C_M_AXIS_TDATA_WIDTH)/2 -1:0] q_receive;
	reg [3:0]  rxd_status;
	reg mid_tx_en;
	reg tvalid_en;
	reg iq_last_ready;
	// Control state machine implementation                             
	always @(posedge M_AXIS_ACLK)                                             
	begin                                                                     
	  if (!M_AXIS_ARESETN)                                                    
	  // Synchronous reset (active low)                                       
	    begin                                                                 
	      mst_exec_state <= IDLE;                                             
	      count    <= 0;                                                      
	    end                                                                   
	  else                                                                    
	    case (mst_exec_state)                                                 
	      IDLE:                                                               
	        // The slave starts accepting tdata when                          
	        // there tvalid is asserted to mark the                           
	        // presence of valid streaming data                               
	        //if ( count == 0 )                                                 
	        //  begin                                                           
	            mst_exec_state  <= INIT_COUNTER;                              
	        //  end                                                             
	        //else                                                              
	        //  begin                                                           
	        //    mst_exec_state  <= IDLE;                                      
	        //  end                                                             
	                                                                          
	      INIT_COUNTER:                                                       
	        // The slave starts accepting tdata when                          
	        // there tvalid is asserted to mark the                           
	        // presence of valid streaming data                               
	        if ( count == C_M_START_COUNT - 1 )                               
	          begin                                                           
	            mst_exec_state  <= SEND_STREAM;                               
	          end                                                             
	        else                                                              
	          begin                                                           
	            count <= count + 1;                                           
	            mst_exec_state  <= INIT_COUNTER;                              
	          end                                                             
	                                                                          
	      SEND_STREAM:                                                        
	        // The example design streaming master functionality starts       
	        // when the master drives output tdata from the FIFO and the slave
	        // has finished storing the S_AXIS_TDATA                          
	        if (tx_done)                                                      
	          begin                                                           
	            mst_exec_state <= IDLE;                                       
	          end                                                             
	        else                                                              
	          begin                                                           
	            mst_exec_state <= SEND_STREAM;                                
	          end                                                             
	    endcase                                                               
	end                                                                       


	//tvalid generation
	//axis_tvalid is asserted when the control state machine's state is SEND_STREAM and
	//number of output streaming data is less than the NUMBER_OF_OUTPUT_WORDS.
	assign axis_tvalid = ((mst_exec_state == SEND_STREAM) && (write_pointer > 0) && tvalid_en);
	                                                                                               
	// AXI tlast generation                                                                        
	// axis_tlast is asserted number of output streaming data is NUMBER_OF_OUTPUT_WORDS-1          
	// (0 to NUMBER_OF_OUTPUT_WORDS-1)                                                             
	assign axis_tlast = ((read_pointer == write_pointer) && (write_pointer > 0));                                
	
	
	assign tx_en = M_AXIS_TREADY && axis_tvalid;
	// Delay the axis_tvalid and axis_tlast signal by one clock cycle                              
	// to match the latency of M_AXIS_TDATA                                                        
	always @(posedge M_AXIS_ACLK)                                                                  
	begin                                                                                          
	  if (!M_AXIS_ARESETN)                                                                         
	    begin                                                                                      
	      axis_tvalid_delay <= 1'b0;                                                               
	      axis_tlast_delay <= 1'b0;                                                                
	    end                                                                                        
	  else                                                                                         
	    begin                                                                                      
	      axis_tvalid_delay <= axis_tvalid;                                                        
	      axis_tlast_delay <= axis_tlast;                                                          
	    end                                                                                        
	end                                                                                            

	// -----------------------Add user logic here-----------------------------
	//Make window to detect the status of the clk32
	always @(posedge M_AXIS_ACLK)
		begin
		if(!M_AXIS_ARESETN)begin
			{clk_2,clk_1}	<=	2'b00;
			end
		else begin
			{clk_2,clk_1}	<=	{clk_1,CLK32};
			end
		end
	//Make window to detect the status of the mid_tx_en
	always @(posedge M_AXIS_ACLK)
		begin
		if(!M_AXIS_ARESETN)begin
			window_old <=1'b0;
			window_new <=1'b0;
			end
		else 
			{window_old,window_new} <= {window_new,mid_tx_en};
		end
		
	//when the clk32 doesn't change within 3'sys_clk,
	//Assert the iq_last (Active High)
	always@ (posedge M_AXIS_ACLK)
		begin
		if(!M_AXIS_ARESETN)begin
			counter_i <= 3'd0;
			counter_x <= 2'd0;
			iq_last   <= 1'b0;
			clk_start <= 1'b0;
			end
		else begin 
			if(clk_pos)begin
				clk_start <=1'b1;
				end
			if((counter_i < 7) && clk_start)begin
				counter_i <= counter_i + 1;
				end
			if(clk_start && clk_hold)begin
				counter_x <= counter_x + 1;
				end	
			if(counter_i == 7)begin
				counter_i <= 3'd0;
				if (counter_x  < 2)begin
					iq_last   <= 1'b1;
					counter_x <= 2'b00;
					clk_start <= 1'b0;
					end
				else begin	
					counter_x <= 2'b00;
					iq_last   <= 1'b0;
					end
				end
			end
		end
		
	//wire_pointer pointer
	//when Front end recceived 32bits and transfer to the mid_buff
	always@ (posedge M_AXIS_ACLK)
		begin
		if(!M_AXIS_ARESETN)begin
			write_pointer <= 3'd0;
			read_pointer  <= 3'd0;
			tvalid_en 	  <= 1'b0;
			tx_done		  <= 1'b0;
			stream_data_out <= 32'd0;
			end
		else begin
		      if(mid_tx_next)begin
				if(mid_buff == 0)begin
					tvalid_en <= 1'b0;
					end
				else if(write_pointer < 7)begin
						stream_data_fifo[write_pointer] <= mid_buff;
						write_pointer <= write_pointer +1;
						tvalid_en	<= 1'b0;
						end
					else
						stream_data_fifo[write_pointer] <= mid_buff;
						tvalid_en <= 1'b1;
			     end
			else if(iq_last)begin
					stream_data_fifo[write_pointer] <= mid_buff;
					tvalid_en <= 1'b1;
					end
			end
			
			if(tx_en)begin
				stream_data_out  <= stream_data_fifo[read_pointer];
				if(read_pointer < write_pointer)begin
					read_pointer <= read_pointer + 1;
					tx_done		 <= 1'b0;
					end
				else
					tx_done	<= 1'b1;
					read_pointer <=3'd0;
					write_pointer<=3'd0;
					tvalid_en	 <=1'b0;
				end
		   end
	//IQ receive the signal
	//when received 2*16 bits signal, asserted the mid_tx_en
	always@ (posedge M_AXIS_ACLK)
		begin
		if(!M_AXIS_ARESETN)begin
			rxd_status    <= 4'd0;
			mid_tx_en     <= 1'b0;
			i_receive     <= 16'd0;
			q_receive     <= 16'd0;
			mid_buff   	  <= 32'd0;
			iq_last_ready <= 1'b0;
			end
		else begin
			if (clk_pos)begin
				iq_last_ready <= 1'b0;
				case (rxd_status)
				
				4'd0:begin
				i_receive[rxd_status] <= IQ_RXD[0];
				q_receive[rxd_status] <= IQ_RXD[1];
				rxd_status <= rxd_status + 1;
				end
				4'd1:begin
				i_receive[rxd_status] <= IQ_RXD[0];
				q_receive[rxd_status] <= IQ_RXD[1];
				rxd_status <= rxd_status + 1;
				end
				4'd2:begin
				i_receive[rxd_status] <= IQ_RXD[0];
				q_receive[rxd_status] <= IQ_RXD[1];
				rxd_status <= rxd_status + 1;
				end
				4'd3:begin
				i_receive[rxd_status] <= IQ_RXD[0];
				q_receive[rxd_status] <= IQ_RXD[1];
				rxd_status <= rxd_status + 1;
				end	
				4'd4:begin
				i_receive[rxd_status] <= IQ_RXD[0];
				q_receive[rxd_status] <= IQ_RXD[1];
				rxd_status <= rxd_status + 1;
				end	
				4'd5:begin
				i_receive[rxd_status] <= IQ_RXD[0];
				q_receive[rxd_status] <= IQ_RXD[1];
				rxd_status <= rxd_status + 1;
				end	
				4'd6:begin
				i_receive[rxd_status] <= IQ_RXD[0];
				q_receive[rxd_status] <= IQ_RXD[1];
				rxd_status <= rxd_status + 1;
				end
				4'd7:begin
				i_receive[rxd_status] <= IQ_RXD[0];
				q_receive[rxd_status] <= IQ_RXD[1];
				rxd_status <= rxd_status + 1;
				end
				4'd8:begin
				i_receive[rxd_status] <= IQ_RXD[0];
				q_receive[rxd_status] <= IQ_RXD[1];
				rxd_status <= rxd_status + 1;
				end
				4'd9:begin
				i_receive[rxd_status] <= IQ_RXD[0];
				q_receive[rxd_status] <= IQ_RXD[1];
				rxd_status <= rxd_status + 1;
				end
				4'd10:begin
				i_receive[rxd_status] <= IQ_RXD[0];
				q_receive[rxd_status] <= IQ_RXD[1];
				rxd_status <= rxd_status + 1;
				end
				4'd11:begin
				i_receive[rxd_status] <= IQ_RXD[0];
				q_receive[rxd_status] <= IQ_RXD[1];
				rxd_status <= rxd_status + 1;
				end
				4'd12:begin
				i_receive[rxd_status] <= IQ_RXD[0];
				q_receive[rxd_status] <= IQ_RXD[1];
				rxd_status <= rxd_status + 1;
				end
				4'd13:begin
				i_receive[rxd_status] <= IQ_RXD[0];
				q_receive[rxd_status] <= IQ_RXD[1];
				rxd_status <= rxd_status + 1;
				end
				4'd14:begin
				i_receive[rxd_status] <= IQ_RXD[0];
				q_receive[rxd_status] <= IQ_RXD[1];
				rxd_status <= rxd_status + 1;
				end
				4'd15:begin
				rxd_status <= rxd_status + 1;
				i_receive[rxd_status] = IQ_RXD[0];
				q_receive[rxd_status] = IQ_RXD[1];
				mid_buff [0] <= i_receive;
				mid_buff [16]<= q_receive;
				mid_tx_en    <= 1'b1;
				end
				endcase
				end
			else if(iq_last && rxd_status> 0)begin
			    case (rxd_status)
			    4'd1:begin
				i_receive[15:1] = 0;
				q_receive[15:1] = 0;
				end
				4'd2:begin
				i_receive[15:2] = 0;
                q_receive[15:2] = 0;
                end
                4'd3:begin
				i_receive[15:3] = 0;
                q_receive[15:3] = 0;
                end 
                4'd4:begin
                i_receive[15:4] = 0;
                q_receive[15:4] = 0;
                end
                4'd5:begin
                i_receive[15:5] = 0;
                q_receive[15:5] = 0;
                end           
                4'd6:begin
                i_receive[15:6] = 0;
                q_receive[15:6] = 0;
                end
                4'd7:begin
                i_receive[15:7] = 0;
                q_receive[15:7] = 0;
                end           
                4'd8:begin
                i_receive[15:8] = 0;
                q_receive[15:8] = 0;
                end           
                4'd9:begin
                i_receive[15:9] = 0;
                q_receive[15:9] = 0;
                end           
                4'd10:begin
                i_receive[15:10] = 0;
                q_receive[15:10] = 0;
                end
                4'd11:begin
                i_receive[15:11] = 0;
                q_receive[15:11] = 0;
                end             
                4'd12:begin
                i_receive[15:12] = 0;
                q_receive[15:12] = 0;
                end            
                4'd13:begin
                i_receive[15:13] = 0;
                q_receive[15:13] = 0;
                end            
                4'd14:begin
                i_receive[15:14] = 0;
                q_receive[15:14] = 0;
                end       
                4'd15:begin
                i_receive[15] = 0;
                q_receive[15] = 0;
                end         
                endcase                                                                                                                          
				mid_buff [0] <= i_receive;
				mid_buff [16]<= q_receive; 
				iq_last_ready <=  1'b1;
				end
		      end
		   end
	// User logic ends

	endmodule
