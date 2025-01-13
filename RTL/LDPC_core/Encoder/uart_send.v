module uart_send(
	input				clk,
	input				rst_n,
	
	input				uart_en,
	input		[15:0]	uart_din,
	output	reg	        uart_tx
);

parameter		CLK_FREQ = 100_000_000;
parameter		UART_BPS = 115200;

localparam		BPS_CNT  = CLK_FREQ/UART_BPS;
//9318_0703_0514
//reg			uart_en_d0;
//reg			uart_en_d1;
reg [15:0]       data_reg;
reg	[15:0]	    clk_cnt;
reg	[7:0]		tx_cnt ;
reg				tx_flag;
reg [7:0]       tx_data;

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        data_reg <= 0;
    else if(uart_en)
        data_reg <= uart_din;
    else
        data_reg <= data_reg;
end


always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		tx_flag <= 1'b0;
	end
	else if(uart_en)begin
		tx_flag <= 1'b1;
	end
	else if((tx_cnt==8'd20)&&(clk_cnt==BPS_CNT/2))begin
		tx_flag <= 1'b0;
	end
	else begin
		tx_flag <= tx_flag;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		tx_data <= 0;
	end
	else if(tx_cnt<9)begin
		tx_data <= data_reg[7:0];
	end
	else if(tx_cnt>9&&tx_cnt<20)begin
        tx_data <= data_reg[15:8];
    end
   	else begin
   	    tx_data <= tx_data;
   	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		clk_cnt <= 16'd0;
		tx_cnt <= 8'd0;
	end
	else if(tx_flag)begin
		if(clk_cnt < BPS_CNT -1)begin
			clk_cnt <= clk_cnt + 1'b1;
			tx_cnt <= tx_cnt;
		end
		else begin
			tx_cnt <= tx_cnt + 1'b1;
			clk_cnt <= 16'd0;
		end
	end
	else begin
		clk_cnt <= 16'd0;
		tx_cnt <= 8'd0;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		uart_tx <= 1'b1;
	end
	else if(tx_flag)begin
		case(tx_cnt)
			8'd0:uart_tx <= 1'b0;
            8'd1:uart_tx <= tx_data[0];
            8'd2:uart_tx <= tx_data[1];
            8'd3:uart_tx <= tx_data[2];
            8'd4:uart_tx <= tx_data[3];
            8'd5:uart_tx <= tx_data[4];
            8'd6:uart_tx <= tx_data[5];
            8'd7:uart_tx <= tx_data[6];
            8'd8:uart_tx <= tx_data[7];
            8'd9:uart_tx <= 1'b1;
            8'd10:uart_tx <= 1'b0;
            8'd11:uart_tx <= tx_data[0];
            8'd12:uart_tx <= tx_data[1];
            8'd13:uart_tx <= tx_data[2];
            8'd14:uart_tx <= tx_data[3];
            8'd15:uart_tx <= tx_data[4];
            8'd16:uart_tx <= tx_data[5];
            8'd17:uart_tx <= tx_data[6];
            8'd18:uart_tx <= tx_data[7];
            8'd19:uart_tx <= 1'b1;
            8'd20:uart_tx <= 1'b1;
			default:uart_tx <= 1'b1;
		endcase
	end
	else
		uart_tx <= 1'b1;
end

endmodule
