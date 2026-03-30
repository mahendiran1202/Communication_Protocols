`timescale 1ns/1ps

module uart_top_tb;

    // Parameters
    localparam integer CLK_FREQ   = 50_000_000;     // 50 MHz
    localparam integer BAUD_RATE  = 115200;         // baud
    localparam integer BIT_PERIOD = 1_000_000_000 / BAUD_RATE; // ns per bit

    // DUT signals
    reg        clk;
    reg        rst;
    reg        tx_start;
    reg  [7:0] data_in;
    reg        p_sel;
    wire       tx;
    wire [7:0] data_out;
    wire       busy;
    wire       error;

    // Instantiate DUT
    uart_top #(
        .CLK_FREQ (CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) dut (
        .clk      (clk),
        .rst      (rst),
        .tx_start (tx_start),
        .data_in  (data_in),
        .p_sel    (p_sel),
        .tx       (tx),
//       .rx		  (rx)
        .data_out (data_out),
        .busy     (busy),
        .error    (error)
    );

    // Clock generation: 50 MHz ? 20 ns period
    always #10 clk = ~clk;

    // Task: send one byte
    task send_byte(input [7:0] d, input parity);
    begin
        @(posedge clk);
        data_in  = d;
        p_sel    = parity;
        tx_start = 1'b1;
        @(posedge clk);
        tx_start = 1'b0;  // pulse
    end
    endtask

    // VCD dump
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, uart_top_tb);
    end

    // Monitor output
    initial begin
        $monitor("T=%0t ns | TX=%b | DATA_IN=%h | RX_DATA=%h | P_SEL=%b | BUSY=%b | ERROR=%b",
                  $time, tx, data_in, data_out, p_sel, busy, error);
    end

    // Test sequence
    initial begin
        // Initialize
        clk      = 0;
        rst      = 1;
        tx_start = 0;
        data_in  = 8'h00;
        p_sel    = 0;

        // Release reset
        #100;
        rst = 0;

        // Wait before sending
        #1000;

        // Send bytes with even parity (p_sel=0)
        send_byte(8'hA5, 1'b0);
        #(12*BIT_PERIOD);

        send_byte(8'h5A, 1'b0);
        #(12*BIT_PERIOD);

        // Send bytes with odd parity (p_sel=1)
        send_byte(8'hFF, 1'b1);
        #(12*BIT_PERIOD);

        send_byte(8'h00, 1'b1);
        #(12*BIT_PERIOD);

        // Extra test: alternating pattern
        send_byte(8'h55, 1'b0);
        #(12*BIT_PERIOD);

        send_byte(8'hAA, 1'b1);
        #(12*BIT_PERIOD);

        // Finish simulation
        #20000;
        $stop;
    end

endmodule
