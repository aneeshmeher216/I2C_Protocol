`timescale 1ns / 1ps
module i2c_tb;

// Master interface signals
reg clk, rst;
reg [6:0] addr;
reg [7:0] data_in;
reg enable, rd_wr;
wire [7:0] data_out;
wire ready;

// Shared I2C lines (bidirectional)
wire sda, scl;
    
// Instantiate the I2C Master
I2C_master master(.clk(clk),
                    .rst(rst),
                    .addr(addr),
                    .data_in(data_in),
                    .enable(enable),
                    .rd_wr(rd_wr),
                    .data_out(data_out),
                    .ready(ready),
                    .sda(sda),
                    .scl(scl));

// Instantiate the I2C Slave
I2C_slave slave(.sda(sda), .scl(scl));

// Clock generation: 10 ns period
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

// Testbench stimulus
initial begin
    // Initial reset and signal defaults
    rst     = 1;
    enable  = 0;
    addr    = 7'b0;
    data_in = 8'h00;
    rd_wr   = 0;
    #20;
    rst = 0;
    
    #5; // allow signals to stabilize
    
    //==================================================
    // Test Case 1: Valid Write Transaction
    // Master writes 0xA5 to slave at address 0x01.
    //==================================================
    enable  = 1;
    addr    = 7'b1001101;  // correct slave address
    data_in = 8'hC8;       // sample data
    rd_wr   = 0;          // write operation


    //==================================================
    // Test Case 2: Valid Read Transaction
    // Master reads from slave at address 0x01.
    // (Note: In this example, the slave's read response 
    //  comes from its internal default 'data_out' value.)
    //==================================================
//    addr   = 7'b1001101;  // correct slave address
//    rd_wr  = 1;          // read operation
//    enable = 1;


    //==================================================
    // Test Case 3: Invalid Address Transaction
    // Master sends an address that does not match the slave.
    // The slave should not acknowledge (NACK).
    //==================================================
//    addr    = 7'b0000010;  // wrong address (slave expects 0x01)
//    data_in = 8'hFF;
//    rd_wr   = 0;          // write operation
//    enable  = 1;


end

endmodule
