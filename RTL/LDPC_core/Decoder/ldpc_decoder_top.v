`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/10/30 07:58:48
// Design Name: 
// Module Name: ldpc_encoder_top
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


module ldpc_decoder_top(

    input       clk,
    input       rst_n,
    input       uart_rx,
    output      uart_tx
       );
  
wire            uart_done;
wire    [11:0]   rx_data;
wire    [11:0]  code;
wire                tx_en;   
wire    [3:0]   msg;
wire            num_done;
uart_recv uart_recv(
        .clk          (clk      ),
        .rst_n        (rst_n    ),
        .uart_rx      (uart_rx       ),
        .num_done    (num_done),
        .uart_done(uart_done),
        .uart_data_12bit    (rx_data  ),
        .star_flag    ()
    );
    
    ldpc_decoder ldpc_decoder(
        .clk    (clk),
        .rst_n  (rst_n),
        .msg    (msg),
        .tx_en    (tx_en),
        .num_done    (num_done),
        .code   (rx_data)
        );
    
    uart_send uart_send(
        .clk        (clk        ),
        .rst_n      (rst_n      ),
        .uart_en    ( tx_en ),
        .uart_din   ({4'd0,msg}  ),//{4'd0,msg}
        .uart_tx    (uart_tx         )
    );
endmodule
