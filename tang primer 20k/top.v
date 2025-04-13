module top(
    input         clk,
    input         rst_n,
    input         s1,       
    output        uart_tx
);

  parameter CLK_FRE  = 27;      
  parameter UART_FRE = 115200;  

  wire button_pressed;
  assign button_pressed = ~s1;  //  flip since active low
  reg prev_pressed;
  reg [7:0] tx_data;
  reg       tx_data_valid;
  wire      tx_data_ready;


  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
       prev_pressed  <= 1'b0;
       tx_data       <= 8'd0;
       tx_data_valid <= 1'b0;
    end
    else begin
       tx_data_valid <= 1'b0;
       if (button_pressed && !prev_pressed) begin
         // rising edge on button_pressed (button press)
         if (tx_data_ready) begin
            tx_data       <= "1";
            tx_data_valid <= 1'b1;
         end
       end 
       else if (!button_pressed && prev_pressed) begin
         // falling edge on button_pressed (button release)
         if (tx_data_ready) begin
            tx_data       <= "0";
            tx_data_valid <= 1'b1;
         end
       end
       prev_pressed <= button_pressed;
    end
  end

  uart_tx #(
    .CLK_FRE(CLK_FRE),
    .BAUD_RATE(UART_FRE)
  )
  uart_tx_inst (
    .clk(clk),
    .rst_n(rst_n),
    .tx_data(tx_data),
    .tx_data_valid(tx_data_valid),
    .tx_data_ready(tx_data_ready),
    .tx_pin(uart_tx)
  );

endmodule
