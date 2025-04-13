module uart_rx#
(
  parameter CLK_FRE   = 50,      
  parameter BAUD_RATE = 115200   
)
(
  input               clk,          
  input               rst_n,        
  output reg [7:0]    rx_data,      
  output reg          rx_data_valid,
  input               rx_data_ready,
  input               rx_pin        
);

  localparam CYCLE = CLK_FRE * 1000000 / BAUD_RATE;

  localparam S_IDLE     = 1;
  localparam S_START    = 2;  // Start bit detection
  localparam S_REC_BYTE = 3;  // Receive data bits
  localparam S_STOP     = 4;  // Stop bit
  localparam S_DATA     = 5;  // Wait for external acknowledgment

  reg [2:0] state, next_state;
  reg rx_d0, rx_d1;                 // For synchronizing rx_pin
  wire rx_negedge;                  // Detected falling edge (start bit)
  reg [7:0] rx_bits;                // Latch for received bits
  reg [15:0] cycle_cnt;             // Baud counter
  reg [2:0] bit_cnt;                // Bit counter

  assign rx_negedge = rx_d1 & ~rx_d0;

  // Synchronize rx_pin signal
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_d0 <= 1'b0;
      rx_d1 <= 1'b0;
    end
    else begin
      rx_d0 <= rx_pin;
      rx_d1 <= rx_d0;
    end
  end

  // Update state on clock
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      state <= S_IDLE;
    else
      state <= next_state;
  end

  // Next state logic
  always @(*) begin
    case (state)
      S_IDLE:
        next_state = rx_negedge ? S_START : S_IDLE;
      S_START:
        next_state = (cycle_cnt == CYCLE - 1) ? S_REC_BYTE : S_START;
      S_REC_BYTE:
        next_state = (cycle_cnt == CYCLE - 1 && bit_cnt == 3'd7) ? S_STOP : S_REC_BYTE;
      S_STOP:
        next_state = (cycle_cnt == (CYCLE/2) - 1) ? S_DATA : S_STOP;
      S_DATA:
        next_state = rx_data_ready ? S_IDLE : S_DATA;
      default:
        next_state = S_IDLE;
    endcase
  end

  // Update data valid flag
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      rx_data_valid <= 1'b0;
    else if (state == S_STOP && next_state != state)
      rx_data_valid <= 1'b1;
    else if (state == S_DATA && rx_data_ready)
      rx_data_valid <= 1'b0;
  end

  // Latch received data at the end of stop bit
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      rx_data <= 8'd0;
    else if (state == S_STOP && next_state != state)
      rx_data <= rx_bits;
  end

  // Bit counter management
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      bit_cnt <= 3'd0;
    else if (state == S_REC_BYTE)
      if (cycle_cnt == CYCLE - 1)
        bit_cnt <= bit_cnt + 3'd1;
      else
        bit_cnt <= bit_cnt;
    else
      bit_cnt <= 3'd0;
  end

  // Cycle counter for baud timing
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      cycle_cnt <= 16'd0;
    else if ((state == S_REC_BYTE && cycle_cnt == CYCLE - 1) || next_state != state)
      cycle_cnt <= 16'd0;
    else
      cycle_cnt <= cycle_cnt + 16'd1;
  end

  // Sample rx_pin at mid-bit to capture data
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      rx_bits <= 8'd0;
    else if (state == S_REC_BYTE && cycle_cnt == (CYCLE/2) - 1)
      rx_bits[bit_cnt] <= rx_pin;
    else
      rx_bits <= rx_bits;
  end

endmodule
