
`timescale 1 ns/ 1 ps
module ldpc_decoder(
	clk,
	rst_n,
	code,
	msg,
	num_done,
	tx_en
	);

	input  clk;															// ϵͳʱ�� 50MHz
	input  num_done;
	input  rst_n;														// ��λ�źţ��͵�ƽ��Ч
	output reg tx_en;
	input  [11:0] code;													// ��Ϣ���� 
	output [3:0] msg;													// �������� 
	reg tx_en1;
	/*********************************************************************************************
    //  ģ�����ƣ�LDPC����ģ��
    //  ��������������Ϣ���н���LDPC����
	//			   ����(8��12)�����Ʋ�����LDPC�룬����Ϊ0.33������Ϊ3��4������Ϊ2��3 	                    
	//			   ���ڸ����У����� ���� ������������һ����ͬ��Ԫ ����û��4����6��
	//             �ɲ��ô����߼������㷨�������� ֻ�ܾ���һ���������		 	
 	//                11 10 9   8   7   6   5   4   3   2   1   0
	//   			| 0	 0	1	0	0	1	0	0	1	0	1	0 |
	//				| 0	 1	0	0	0	1	0	0	0	0	0	1 |
	//  			| 0	 1	0	0	0	0	1	0	0	0	1	0 |
	//  У�����H=  | 0	 0	0	1	1	1	0	0	0	1	0	0 |       ��code*H'=0 ��code��ȷ �ɻ�ԭ��ԭʼmsg
	//  			| 0	 0	0	1	0	0	0	1	1	0	0	1 |
	//  			| 1	 0	0	0	1	0	0	0	0	0	0	0 |
	//  			| 1	 0	1	0	0	0	1	1	0	0	0	0 |
	//   			| 0	 1	1	0	0	0	0	0	0	1	0	0 |

	//   ����У�����H��������˹��Ԫ���󣬿ɵ�P������н���col_recoeder
	//     | 1 1 1 0 |
	//	p= | 0 1 0 1 |      col_recoeder= |0 0 0 0 0 0 0 9| ��0���ñ任��
	//     | 0 0 0 1 |
	//     | 1 1 1 0 |
	//	   | 1 1 1 0 |
	//     | 0 1 0 0 |
	//     | 0 1 1 1 |
	//     | 0 1 1 1 |
    //*********************************************************************************************/	
	
	// ʱ�Ӽ��� ��1��ʱ�ӵȴ� ��2��ʱ�ӵ���25������������� ��26��ʱ�ӽ����б任��ԭ ��������ԭ����Ϣ����
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
	
	reg [11:0] code_check;												// �����ֽ��о���������
	reg [4:0]  state;
	reg [2:0]  s; 														// У����
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
			if((clk_count >= 5'd1)&&(clk_count <= 5'd24))				//���д����߼����� ����ÿ�����ص�У���� �������о�
			begin
				case(state)   
				5'd0:begin 												// ����code[11]
					s[2] <= #1 code[11]+code[7];
					s[1] <= #1 code[11]+code[9]+code[5]+code[4];
					s[0] <= #1 1'b0;
					state <= #1 5'd1;				
				end
				5'd1:begin 												// �о�code[11]
					if((s==3'b100)||(s==3'b010)||(s==3'b001)||(s==3'b000))
						code_check[11] <= #1 code[11];  				// code[11]���� �����޸�
					else
						code_check[11] <= #1 ~code[11];	 				// code[11]����
					state <= #1 5'd2;				
				end
			
				5'd2:begin 												// ����code[10]
					s[2] <= #1 code[10]+code[6]+code[0];
					s[1] <= #1 code[10]+code[5]+code[1];
					s[0] <= #1 code[10]+code[9]+code[2];	
					state <= #1 5'd3;				
				end
				5'd3:begin 												// �о�code[10]
					if((s==3'b100)||(s==3'b010)||(s==3'b001)||(s==3'b000))
						code_check[10] <= #1 code[10];  				// code[10]���� �����޸�
					else
						code_check[10] <= #1 ~code[10];	 				// code[10]����
					state <= #1 5'd4;						
				end
			
				5'd4:begin 												// ����code[9]
					s[2] <= #1 code[9]+code[6]+code[3]+code[1];
					s[1] <= #1 code[9]+code[5]+code[4];
					s[0] <= #1 code[9]+code[10]+code[2];		
					state <= #1 5'd5;				
				end
				5'd5:begin 												// �о�code[9]
					if((s==3'b100)||(s==3'b010)||(s==3'b001)||(s==3'b000))
						code_check[9] <= #1 code[9];  					// code[9]���� �����޸�
					else
						code_check[9] <= #1 ~code[9];	 				// code[9]����
					state <= #1 5'd6;						
				end
			
				5'd6:begin 												// ����code[8]
					s[2] <= #1 code[8]+code[7]+code[6]+code[2];
					s[1] <= #1 code[8]+code[4]+code[3]+code[0];
					s[0] <= #1 1'b0;		
					state <= #1 5'd7;				
				end
				5'd7:begin 												// �о�code[8]
					if((s==3'b100)||(s==3'b010)||(s==3'b001)||(s==3'b000))
						code_check[8] <= #1 code[8];  					// code[8]���� �����޸�
					else
						code_check[8] <= #1 ~code[8];	 				// code[8]����
					state <= #1 5'd8;						
				end
			
				5'd8:begin 												// ����code[7]
					s[2] <= #1 code[7]+code[8]+code[6]+code[2];
					s[1] <= #1 code[7]+code[11];
					s[0] <= #1 1'b0;		
					state <= #1 5'd9;				
				end
				5'd9:begin 												// �о�code[7]
					if((s==3'b100)||(s==3'b010)||(s==3'b001)||(s==3'b000))
						code_check[7] <= #1 code[7];  					// code[7]���� �����޸�
					else
						code_check[7] <= #1 ~code[7];	 				// code[7]����
					state <= #1 5'd10;						
				end
			
				5'd10:begin 											// ����code[6]
					s[2] <= #1 code[6]+code[9]+code[3]+code[1];
					s[1] <= #1 code[6]+code[10]+code[0];
					s[0] <= #1 code[6]+code[8]+code[7]+code[2];		
					state <= #1 5'd11;				
				end
				5'd11:begin 											// �о�code[6]
					if((s==3'b100)||(s==3'b010)||(s==3'b001)||(s==3'b000))
						code_check[6] <= #1 code[6];  					// code[6]���� �����޸�
					else
						code_check[6] <= #1 ~code[6];	 				// code[6]����
					state <= #1 5'd12;						
				end
			
				5'd12:begin 											// ����code[5]
					s[2] <= #1 code[5]+code[10]+code[1];
					s[1] <= #1 code[5]+code[11]+code[9]+code[4];
					s[0] <= #1 1'b0;		
					state <= #1 5'd13;				
				end
				5'd13:begin 											// �о�code[5]
					if((s==3'b100)||(s==3'b010)||(s==3'b001)||(s==3'b000))
						code_check[5] <= #1 code[5];  					// code[5]���� �����޸�
					else
						code_check[5] <= #1 ~code[5];	 				// code[5]����
					state <= #1 5'd14;						
				end
			
				5'd14:begin 											// ����code[4]
					s[2] <= #1 code[4]+code[8]+code[3]+code[0];
					s[1] <= #1 code[4]+code[11]+code[9]+code[5];
					s[0] <= #1 1'b0;		
					state <= #1 5'd15;				
				end
				5'd15:begin 											// �о�code[4]
					if((s==3'b100)||(s==3'b010)||(s==3'b001)||(s==3'b000))
						code_check[4] <= #1 code[4];  					// code[4]���� �����޸�
					else
						code_check[4] <= #1 ~code[4];	 				// code[4]����
					state <= #1 5'd16;						
				end
				
				5'd16:begin 											// ����code[3]
					s[2] <= #1 code[3]+code[9]+code[6]+code[1];
					s[1] <= #1 code[3]+code[8]+code[4]+code[0];
					s[0] <= #1 1'b0;		
					state <= #1 5'd17;				
				end
				5'd17:begin 											// �о�code[3]
					if((s==3'b100)||(s==3'b010)||(s==3'b001)||(s==3'b000))
						code_check[3] <= #1 code[3];  					// code[3]���� �����޸�
					else
						code_check[3] <= #1 ~code[3];	 				// code[3]����
					state <= #1 5'd18;						
				end
				
				5'd18:begin 											// ����code[2]
					s[2] <= #1 code[2]+code[8]+code[7]+code[6];
					s[1] <= #1 code[2]+code[10]+code[9];
					s[0] <= #1 1'b0;		
					state <= #1 5'd19;				
				end
				5'd19:begin 											// �о�code[2]
					if((s==3'b100)||(s==3'b010)||(s==3'b001)||(s==3'b000))
						code_check[2] <= #1 code[2];  					// code[2]���� �����޸�
					else
						code_check[2] <= #1 ~code[2];	 				// code[2]����
					state <= #1 5'd20;						
				end
				
				5'd20:begin 											// ����code[1]
					s[2] <= #1 code[1]+code[9]+code[6]+code[3];
					s[1] <= #1 code[1]+code[10]+code[5];
					s[0] <= #1 1'b0;		
					state <= #1 5'd21;				
				end
				5'd21:begin 											// �о�code[1]
					if((s==3'b100)||(s==3'b010)||(s==3'b001)||(s==3'b000))
						code_check[1] <= #1 code[1];  					// code[1]���� �����޸�
					else
						code_check[1] <= #1 ~code[1];				 	// code[1]����
					state <= #1 5'd22;						
				end
				
				5'd22:begin 											// ����code[0]
					s[2] <= #1 code[0]+code[10]+code[6];
					s[1] <= #1 code[0]+code[8]+code[4]+code[3];
					s[0] <= #1 1'b0;		
					state <= #1 5'd23;				
				end
				5'd23:begin 											// �о�code[0]
					if((s==3'b100)||(s==3'b010)||(s==3'b001)||(s==3'b000))
						code_check[0] <= #1 code[0];  					// code[1]���� �����޸�
					else
						code_check[0] <= #1 ~code[0];	 				// code[1]����
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
	
	// �����б任��ԭ	 |0 0 0 0 0 0 0 9| u=[c | s] 
	reg [11:0] code_col;												// �����ֽ����б任�������
	reg 	   decode_finish;											// ��������ź�
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
				code_col <= #1 {code_check[11:5],code_check[3],code_check[4],code_check[2:0]}; // ���е�8λ���9λ���н��� �ӵ�������
				decode_finish <= #1 1'b1;								// �������
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
				msg <= #1 code_col[3:0];								// ��������ԭ����Ϣ����
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

//LDPC����ģ�����⣺
//codeһ����12λ���������й���3λ�������Խ����4λ��ԭ��
//�����12λcode���������ɶ�Ӧ�ļ�������s�������У���ÿһλ����Ϊ��һ��������ԭλ���ɴ˿���׼ȷ��У��ÿһλcode
//���������û�г��ִ��󣬼�������s��ÿһ�Ӧ��Ϊ0�����s������1�������¼��������Ϊ���󣬲���ʱ�����޸�
//���ͬ��ʹ�ñ�����ʹ�õ�H���󣬽��ж�Ӧ���б任
	