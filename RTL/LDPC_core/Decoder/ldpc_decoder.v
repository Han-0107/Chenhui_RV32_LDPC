
`timescale 1 ns/ 1 ps
module ldpc_decoder(
	clk,
	rst_n,
	code,
	msg,
	num_done,
	tx_en
	);

	input  clk;															// 系统时钟 50MHz
	input  num_done;
	input  rst_n;														// 复位信号，低电平有效
	output reg tx_en;
	input  [11:0] code;													// 信息序列 
	output [3:0] msg;													// 编码序列 
	reg tx_en1;
	/*********************************************************************************************
    //  模块名称：LDPC译码模块
    //  功能描述：对信息序列进行LDPC译码
	//			   采用(8，12)二进制不规则LDPC码，码率为0.33，行重为3和4，列重为2和3 	                    
	//			   由于该码的校验矩阵 满足 任意两行至多一个相同码元 该码没有4环和6环
	//             可采用大数逻辑译码算法进行译码 只能纠正一个错误比特		 	
 	//                11 10 9   8   7   6   5   4   3   2   1   0
	//   			| 0	 0	1	0	0	1	0	0	1	0	1	0 |
	//				| 0	 1	0	0	0	1	0	0	0	0	0	1 |
	//  			| 0	 1	0	0	0	0	1	0	0	0	1	0 |
	//  校验矩阵H=  | 0	 0	0	1	1	1	0	0	0	1	0	0 |       若code*H'=0 则code正确 可还原出原始msg
	//  			| 0	 0	0	1	0	0	0	1	1	0	0	1 |
	//  			| 1	 0	0	0	1	0	0	0	0	0	0	0 |
	//  			| 1	 0	1	0	0	0	1	1	0	0	0	0 |
	//   			| 0	 1	1	0	0	0	0	0	0	1	0	0 |

	//   根据校验矩阵H，经过高斯消元法后，可得P矩阵和列交换col_recoeder
	//     | 1 1 1 0 |
	//	p= | 0 1 0 1 |      col_recoeder= |0 0 0 0 0 0 0 9| （0不用变换）
	//     | 0 0 0 1 |
	//     | 1 1 1 0 |
	//	   | 1 1 1 0 |
	//     | 0 1 0 0 |
	//     | 0 1 1 1 |
	//     | 0 1 1 1 |
    //*********************************************************************************************/	
	
	// 时钟计数 第1个时钟等待 第2个时钟到第25个进行译码纠错 第26个时钟进行列变换还原 输出译码后还原的信息序列
	reg [4:0] clk_count;
	reg        rec_flag;
	
	always@(posedge clk or negedge rst_n)	
	   if(!rst_n)
	       rec_flag <= 0;
	   else if(num_done)
	       rec_flag <= 1;
	   else if(clk_count == 5'd25)
	       rec_flag <= 0;
	    else
	       rec_flag <= rec_flag;
	
	always@(posedge clk or negedge rst_n)								
	begin
		if(rst_n == 1'b0)
			clk_count <= #1 5'd0;
		else if(rec_flag)begin
			if(clk_count == 5'd25)
				clk_count <= #1 5'd0;
			else
				clk_count <= #1 clk_count + 1'b1;		
		end
		else
		  clk_count <= #1 5'd0;
	end
	
	reg [11:0] code_check;												// 对码字进行纠错后的码组
	reg [4:0]  state;
	reg [2:0]  s; 														// 校正子
	always@(posedge clk or negedge rst_n)
	begin
		if(rst_n == 1'b0)
		begin
			code_check   <= #1 12'b0;
			state <= #1 5'b0;
			s <= #1 3'b0;
		end
		else
		begin				
			if((clk_count >= 5'd1)&&(clk_count <= 5'd24))				//进行大数逻辑译码 计算每个比特的校正子 并进行判决
			begin
				case(state)   
				5'd0:begin 												// 计算code[11]
					s[2] <= #1 code[11]+code[7];
					s[1] <= #1 code[11]+code[9]+code[5]+code[4];
					s[0] <= #1 1'b0;
					state <= #1 5'd1;				
				end
				5'd1:begin 												// 判决code[11]
					if((s==3'b100)||(s==3'b010)||(s==3'b001)||(s==3'b000))
						code_check[11] <= #1 code[11];  				// code[11]有误 进行修改
					else
						code_check[11] <= #1 ~code[11];	 				// code[11]无误
					state <= #1 5'd2;				
				end
			
				5'd2:begin 												// 计算code[10]
					s[2] <= #1 code[10]+code[6]+code[0];
					s[1] <= #1 code[10]+code[5]+code[1];
					s[0] <= #1 code[10]+code[9]+code[2];	
					state <= #1 5'd3;				
				end
				5'd3:begin 												// 判决code[10]
					if((s==3'b100)||(s==3'b010)||(s==3'b001)||(s==3'b000))
						code_check[10] <= #1 code[10];  				// code[10]有误 进行修改
					else
						code_check[10] <= #1 ~code[10];	 				// code[10]无误
					state <= #1 5'd4;						
				end
			
				5'd4:begin 												// 计算code[9]
					s[2] <= #1 code[9]+code[6]+code[3]+code[1];
					s[1] <= #1 code[9]+code[5]+code[4];
					s[0] <= #1 code[9]+code[10]+code[2];		
					state <= #1 5'd5;				
				end
				5'd5:begin 												// 判决code[9]
					if((s==3'b100)||(s==3'b010)||(s==3'b001)||(s==3'b000))
						code_check[9] <= #1 code[9];  					// code[9]有误 进行修改
					else
						code_check[9] <= #1 ~code[9];	 				// code[9]无误
					state <= #1 5'd6;						
				end
			
				5'd6:begin 												// 计算code[8]
					s[2] <= #1 code[8]+code[7]+code[6]+code[2];
					s[1] <= #1 code[8]+code[4]+code[3]+code[0];
					s[0] <= #1 1'b0;		
					state <= #1 5'd7;				
				end
				5'd7:begin 												// 判决code[8]
					if((s==3'b100)||(s==3'b010)||(s==3'b001)||(s==3'b000))
						code_check[8] <= #1 code[8];  					// code[8]有误 进行修改
					else
						code_check[8] <= #1 ~code[8];	 				// code[8]无误
					state <= #1 5'd8;						
				end
			
				5'd8:begin 												// 计算code[7]
					s[2] <= #1 code[7]+code[8]+code[6]+code[2];
					s[1] <= #1 code[7]+code[11];
					s[0] <= #1 1'b0;		
					state <= #1 5'd9;				
				end
				5'd9:begin 												// 判决code[7]
					if((s==3'b100)||(s==3'b010)||(s==3'b001)||(s==3'b000))
						code_check[7] <= #1 code[7];  					// code[7]有误 进行修改
					else
						code_check[7] <= #1 ~code[7];	 				// code[7]无误
					state <= #1 5'd10;						
				end
			
				5'd10:begin 											// 计算code[6]
					s[2] <= #1 code[6]+code[9]+code[3]+code[1];
					s[1] <= #1 code[6]+code[10]+code[0];
					s[0] <= #1 code[6]+code[8]+code[7]+code[2];		
					state <= #1 5'd11;				
				end
				5'd11:begin 											// 判决code[6]
					if((s==3'b100)||(s==3'b010)||(s==3'b001)||(s==3'b000))
						code_check[6] <= #1 code[6];  					// code[6]有误 进行修改
					else
						code_check[6] <= #1 ~code[6];	 				// code[6]无误
					state <= #1 5'd12;						
				end
			
				5'd12:begin 											// 计算code[5]
					s[2] <= #1 code[5]+code[10]+code[1];
					s[1] <= #1 code[5]+code[11]+code[9]+code[4];
					s[0] <= #1 1'b0;		
					state <= #1 5'd13;				
				end
				5'd13:begin 											// 判决code[5]
					if((s==3'b100)||(s==3'b010)||(s==3'b001)||(s==3'b000))
						code_check[5] <= #1 code[5];  					// code[5]有误 进行修改
					else
						code_check[5] <= #1 ~code[5];	 				// code[5]无误
					state <= #1 5'd14;						
				end
			
				5'd14:begin 											// 计算code[4]
					s[2] <= #1 code[4]+code[8]+code[3]+code[0];
					s[1] <= #1 code[4]+code[11]+code[9]+code[5];
					s[0] <= #1 1'b0;		
					state <= #1 5'd15;				
				end
				5'd15:begin 											// 判决code[4]
					if((s==3'b100)||(s==3'b010)||(s==3'b001)||(s==3'b000))
						code_check[4] <= #1 code[4];  					// code[4]有误 进行修改
					else
						code_check[4] <= #1 ~code[4];	 				// code[4]无误
					state <= #1 5'd16;						
				end
				
				5'd16:begin 											// 计算code[3]
					s[2] <= #1 code[3]+code[9]+code[6]+code[1];
					s[1] <= #1 code[3]+code[8]+code[4]+code[0];
					s[0] <= #1 1'b0;		
					state <= #1 5'd17;				
				end
				5'd17:begin 											// 判决code[3]
					if((s==3'b100)||(s==3'b010)||(s==3'b001)||(s==3'b000))
						code_check[3] <= #1 code[3];  					// code[3]有误 进行修改
					else
						code_check[3] <= #1 ~code[3];	 				// code[3]无误
					state <= #1 5'd18;						
				end
				
				5'd18:begin 											// 计算code[2]
					s[2] <= #1 code[2]+code[8]+code[7]+code[6];
					s[1] <= #1 code[2]+code[10]+code[9];
					s[0] <= #1 1'b0;		
					state <= #1 5'd19;				
				end
				5'd19:begin 											// 判决code[2]
					if((s==3'b100)||(s==3'b010)||(s==3'b001)||(s==3'b000))
						code_check[2] <= #1 code[2];  					// code[2]有误 进行修改
					else
						code_check[2] <= #1 ~code[2];	 				// code[2]无误
					state <= #1 5'd20;						
				end
				
				5'd20:begin 											// 计算code[1]
					s[2] <= #1 code[1]+code[9]+code[6]+code[3];
					s[1] <= #1 code[1]+code[10]+code[5];
					s[0] <= #1 1'b0;		
					state <= #1 5'd21;				
				end
				5'd21:begin 											// 判决code[1]
					if((s==3'b100)||(s==3'b010)||(s==3'b001)||(s==3'b000))
						code_check[1] <= #1 code[1];  					// code[1]有误 进行修改
					else
						code_check[1] <= #1 ~code[1];				 	// code[1]无误
					state <= #1 5'd22;						
				end
				
				5'd22:begin 											// 计算code[0]
					s[2] <= #1 code[0]+code[10]+code[6];
					s[1] <= #1 code[0]+code[8]+code[4]+code[3];
					s[0] <= #1 1'b0;		
					state <= #1 5'd23;				
				end
				5'd23:begin 											// 判决code[0]
					if((s==3'b100)||(s==3'b010)||(s==3'b001)||(s==3'b000))
						code_check[0] <= #1 code[0];  					// code[1]有误 进行修改
					else
						code_check[0] <= #1 ~code[0];	 				// code[1]无误
					state <= #1 5'd0;						
				end
				
				default: begin
					state 	<= #1 5'b0;
					s 		<= #1 3'b0;
					code_check <= #1 12'b0;
				end
				
				endcase
			end
		
			else
			begin
				state <= #1 5'b0;
				s 	  <= #1 3'b0;
			end
		end
	end
	
	// 进行列变换还原	 |0 0 0 0 0 0 0 9| u=[c | s] 
	reg [11:0] code_col;												// 对码字进行列变换后的码组
	reg 	   decode_finish;											// 译码完成信号
	always@(posedge clk or negedge rst_n)
	begin
		if(rst_n == 1'b0)
		begin
			code_col   <= #1 8'b0;
			decode_finish <= #1 1'b0;
		end
			
		else
		begin
			if(clk_count == 5'd25)
			begin
				code_col <= #1 {code_check[11:5],code_check[3],code_check[4],code_check[2:0]}; // 序列第8位与第9位进行交换 从低往高数
				decode_finish <= #1 1'b1;								// 译码完成
			end
			
			else
			begin
				code_col   <= #1 code_col;
				decode_finish <= #1 1'b0;				
			end
		end
	end
	
	reg [3:0] msg;														
	always@(posedge clk or negedge rst_n)
	begin
		if(rst_n == 1'b0)
			msg <= #1 4'b0;
		else
		begin
			if(decode_finish == 1'b1)
				msg <= #1 code_col[3:0];								// 输出译码后还原的信息序列
			else
				msg <= #1 msg;
		end
	end
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        tx_en1 <= 0;
        tx_en <= 0;
     end
    else begin
        tx_en1 <= decode_finish;
        tx_en <= tx_en1;
    end
end	
endmodule

//LDPC译码模块的理解：
//code一共有12位，检验序列共有3位，但可以解码出4位的原码
//输入的12位code，可以生成对应的检验序列s。代码中，把每一位都作为了一次正交码原位，由此可以准确地校对每一位code
//如果传输中没有出现错误，检验序列s的每一项都应该为0。如果s出现了1，则将其记录下来，视为错误，并即时进行修改
//最后，同样使用编码器使用的H矩阵，进行对应的行变换
	