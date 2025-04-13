module uart_tx#
(
  parameter CLK_FRE   = 27,      // Clock frequency in MHz
  parameter BAUD_RATE = 115200   // Baud rate in bps
)
(
  input             clk,           // Clock input
  input             rst_n,         // Asynchronous reset, active low
  input   [7:0]     tx_data,       // Data byte to transmit
  input             tx_data_valid, // Assert high when new data is valid
  output reg        tx_data_ready, // High when transmitter is ready for new data
  output            tx_pin         // Serial data output pin
);

  // Calculate the number of clock cycles per bit
  localparam CYCLE = CLK_FRE * 1000000 / BAUD_RATE;

  // FSM states for the UART transmitter
  localparam S_IDLE      = 1;
  localparam S_START     = 2;
  localparam S_SEND_BYTE = 3;
  localparam S_STOP      = 4;

  reg [2:0]   state, next_state;
  reg [15:0]  cycle_cnt;    // Baud rate counter
  reg [2:0]   bit_cnt;      // Data bit counter
  reg [7:0]   tx_data_latch;// Latched data byte
  reg         tx_reg;       // Internal register driving tx_pin

  assign tx_pin = tx_reg;

  // FSM state update
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      state <= S_IDLE;
    else
      state <= next_state;
  end

  // Next-state logic
  always @(*) begin
    case (state)
      S_IDLE:      next_state = tx_data_valid ? S_START : S_IDLE;
      S_START:     next_state = (cycle_cnt == CYCLE - 1) ? S_SEND_BYTE : S_START;
      S_SEND_BYTE: next_state = (cycle_cnt == CYCLE - 1 && bit_cnt == 3'd7) ? S_STOP : S_SEND_BYTE;
      S_STOP:      next_state = (cycle_cnt == CYCLE - 1) ? S_IDLE : S_STOP;
      default:     next_state = S_IDLE;
    endcase
  end

  // Generate the tx_data_ready signal
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      tx_data_ready <= 1'b0;
    else if (state == S_IDLE)
      tx_data_ready <= tx_data_valid ? 1'b0 : 1'b1;
    else if (state == S_STOP && cycle_cnt == CYCLE - 1)
      tx_data_ready <= 1'b1;
  end

  // Latch the input data when valid and idle
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      tx_data_latch <= 8'd0;
    else if (state == S_IDLE && tx_data_valid)
      tx_data_latch <= tx_data;
  end

  // Bit counter: increments during the send byte state
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      bit_cnt <= 3'd0;
    else if (state == S_SEND_BYTE)
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
    else if ((state == S_SEND_BYTE && cycle_cnt == CYCLE - 1) || next_state != state)
      cycle_cnt <= 16'd0;
    else
      cycle_cnt <= cycle_cnt + 16'd1;
  end

  // Transmit output generation: start bit, data bits, stop bit
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      tx_reg <= 1'b1;  // Idle state is high
    else begin
      case (state)
        S_IDLE, S_STOP:
          tx_reg <= 1'b1;
        S_START:
          tx_reg <= 1'b0;
        S_SEND_BYTE:
          tx_reg <= tx_data_latch[bit_cnt];
        default:
          tx_reg <= 1'b1;
      endcase
    end
  end

endmodule
