module uart_recv(
	input					clk,
	input					rst_n,
	input					uart_rx,
	output    reg         uart_done,
	output					star_flag,
	output				num_done,
	output	[11:0]		uart_data_12bit
);

parameter   CLK_FREQ=100_000_000;
parameter   UART_BPS=115200;

localparam		BPS_CNT  = CLK_FREQ/UART_BPS;

reg [7:0]        uart_data;
reg			uart_rx_d0;
reg			uart_rx_d1;
reg	[3:0]		rx_cnt;
reg             num;
reg	[15:0]	clk_cnt;

reg				rx_flag;
reg	[ 7:0]	rxdata;
reg         uart_done_r1;

assign	star_flag = uart_rx_d1 & (~uart_rx_d0);

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		uart_rx_d1 <= 1'b0;
		uart_rx_d0 <= 1'b0;
	end
	else begin
		uart_rx_d0 <= uart_rx;
		uart_rx_d1 <= uart_rx_d0;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		rx_flag <= 1'b0;
	end
	else begin
		if(star_flag)
			rx_flag <= 1'b1;
		else if((rx_cnt == 4'd9)&&(clk_cnt==BPS_CNT/2))
			rx_flag <= 1'b0;
		else
			rx_flag <= rx_flag;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		clk_cnt <= 16'd0;
		rx_cnt <= 4'd0;
	end
	else if(rx_flag)begin
		if(clk_cnt < BPS_CNT-1)begin
			clk_cnt <= clk_cnt  + 1'b1;
			rx_cnt <= rx_cnt;
		end
		else begin
			rx_cnt <= rx_cnt + 1'b1;
			clk_cnt <= 16'd0;
		end
	end
	else begin
		clk_cnt <= 16'd0;
		rx_cnt <= 4'd0;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		rxdata <= 8'd0;
	end
	else if(rx_flag)
		if(clk_cnt == BPS_CNT/2)begin
			case(rx_cnt)
				4'd1:rxdata[0] <= uart_rx_d1;
				4'd2:rxdata[1] <= uart_rx_d1;
				4'd3:rxdata[2] <= uart_rx_d1;
				4'd4:rxdata[3] <= uart_rx_d1;
				4'd5:rxdata[4] <= uart_rx_d1;
				4'd6:rxdata[5] <= uart_rx_d1;
				4'd7:rxdata[6] <= uart_rx_d1;
				4'd8:rxdata[7] <= uart_rx_d1;
				4'd9:rxdata    <= rxdata;
			default:rxdata    <= rxdata;
			endcase
		end
		else
			rxdata <= rxdata;
	else
		rxdata <= 8'd0;
end


always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		uart_data <= 8'd0;
	end
	else if((rx_cnt == 4'd9)&&(clk_cnt==BPS_CNT/2))begin
		uart_data <= rxdata;
	end
	else begin
		uart_data <= uart_data;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		uart_done <= 1'b0;
	end
	else if((rx_cnt == 4'd9)&&(clk_cnt==BPS_CNT/2))begin
		uart_done <= 1'b1;
	end
	else begin
		uart_done <= 1'b0;
	end
end

reg     [2:0]   state;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        state <= 0;
    else
        case(state)
            0:begin
                if(uart_done)
                    state <= 1;
                else
                    state <=0;
            end
            1:begin
                if(uart_done)
                    state <= 2;
                else
                    state <= 1;
            end
            2:begin
                state <= 3;
            end
            3:begin
                state <= 0;
            end
        endcase
end


always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        uart_done_r1 <= 0;
    else
        uart_done_r1 <= uart_done;
end

reg [7:0]   uart_data1,uart_data2;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        uart_data1 <= 0;
        uart_data2 <= 0;
    end
    else if((state==1)&&(uart_done_r1))begin
        uart_data1 <= uart_data;
        uart_data2 <= 0;
    end
    else if(state==2)begin
        uart_data1 <= uart_data1;
        uart_data2 <= uart_data;
    end
    else begin
        uart_data1 <= uart_data1;
        uart_data2 <= uart_data2;
    end
end

assign  uart_data_12bit={uart_data2[3:0],uart_data1};
assign  num_done = (state==3)?1'b1:1'b0;

endmodule
	