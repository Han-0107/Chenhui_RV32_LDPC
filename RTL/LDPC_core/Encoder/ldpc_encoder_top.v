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


module ldpc_encoder_top(

    input          clk,
    input          rst_n,
    input          uart_rx,
    output   reg   uart_tx
       );
  
wire            uart_done;
wire    [7:0]   rx_data;
wire    [11:0]  code;
wire                tx_en;   
uart_recv uart_recv(
        .clk          (clk      ),
        .rst_n        (rst_n    ),
        .uart_rx      (uart_rx       ),
        .uart_done    (uart_done),
        .uart_data    (rx_data  ),
        .star_flag    ()
    );
    
    ldpc_encoder ldpc_encoder(
        .clk    (clk),
        .rst_n  (rst_n),
        .msg    (rx_data[3:0]),
        .tx_en    (tx_en),
        .uart_done    (uart_done),
        
        .code   (code)
        );
    
    uart_send uart_send(
        .clk        (clk        ),
        .rst_n      (rst_n      ),
        .uart_en    ( tx_en ),
        .uart_din   ({4'd0,code}    ),
        .uart_tx    (uart_tx         )
    );
endmodule
