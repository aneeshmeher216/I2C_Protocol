`timescale 1ns / 1ps

module I2C_master(
    input clk, rst,
    input [6:0] addr,           // address is generally 7-bit or 10-bit 
    input [7:0] data_in,        // we have consider data width to be 8-bits
    input enable, rd_wr,        //rd_wr tells whether to read or write data into I2C bus. 
    
    output reg [7:0] data_out,
    output ready,
    inout sda, scl
);
reg [3:0] state = 0;
parameter IDLE = 0,
          START = 1,
          WRITE_ADDR = 2,   //Sends READ_ADDR_ACKess bits (along with rd_wr bit) over SDA
          READ_ADDR_ACK = 3,     //Waits for an acknowledgement (ACK) from the slave after sending the address.
          WRITE_DATA = 4,   //Waits for ACK from the slave after data transmission
          WRITE_ACK = 5,    //Sends an ACK (by driving SDA low) back to the slave after a read.
          READ_DATA = 6,    //Receives data bits from the slave during a read operation
          READ_DATA_ACK = 7,
          STOP = 8;

parameter div_const = 2;

reg [7:0] temp_addr, temp_data;     //temp_addr is 8bit because along with 7bit addr, a rd_wr bit will also go
reg counter1;
reg [3:0] counter2 = 0;  
reg wr_en;
reg sda_out, sda_in, i2c_clk;              
reg scl_en = 0;

// Internal register used solely to capture the read data from the slave
reg [7:0] read_data;

// Delay counter for ACK stabilization in READ_ADDR_ACK state
reg [1:0] ack_delay;
parameter ACK_DELAY = 1; // Wait for 2 cycles
  
//I2C Clock Generation
always @(posedge clk or posedge rst) begin
    if(rst) begin
        i2c_clk <= 0;
        counter1 <= 0;
    end
    else begin
        if(counter1 == (div_const/2)) begin
            i2c_clk = ~i2c_clk;
            counter1 = 0;
        end
        else 
            counter1 = counter1 + 1;
    end
end

assign scl = (scl_en) ? i2c_clk : 1;

//Logic for scl_en: 
always @(posedge i2c_clk or posedge rst) begin
    if(rst) 
        scl_en <= 0;
    else if(state == IDLE || state == STOP)
        scl_en <= 0;
    else 
        scl_en <= 1;
end

// ACK_delay of one clock cycle is given only for read_addr_ack state. case becuase there was timing problem
// but there is not any ack_delay in read_data or write_data state.

always @(posedge i2c_clk or posedge rst) begin
    if(rst) begin
        state <= IDLE;
        counter2 <= 0;
        ack_delay  <= 0;
        wr_en <= 1;
        sda_out <= 1; 
    end
    else begin
        case(state)
              IDLE : begin
                        if(enable) begin
                            state <= START;
                            temp_addr <= {addr,rd_wr};
                            temp_data <= data_in;
                            wr_en <= 1;
                            sda_out <= 1;
                        end
                    end
                   
              START : begin
                        wr_en <= 1;
                        sda_out <= 0;
                        counter2 <= 7;
                        state <= WRITE_ADDR;     
                     end
             
              WRITE_ADDR : begin
                            sda_out <= temp_addr[counter2];     //remember, MSB is sent first 
    
                            if(counter2 == 0)
                                state <= READ_ADDR_ACK;
                            else
                                counter2 <= counter2 - 1;
                       end
                       
              READ_ADDR_ACK : begin
                                wr_en <= 0; 
                                    
                                if(ack_delay < ACK_DELAY) begin
                                    ack_delay <= ack_delay + 1;
                                end 
                                else begin
                                    ack_delay <= 0;  // Reset delay counter.
                                    
                                    if(sda == 0) begin  // ACK received (SDA pulled low).
                                        counter2 <= 7;  // Reset counter for next phase.
                                        
                                        if(temp_addr[0] == 0) begin
                                            wr_en <= 1;
                                            state <= WRITE_DATA;
                                        end 
                                        else begin
                                            state <= READ_DATA;
                                        end
                                    end 
                                    else begin
                                        state <= STOP;  // No ACK: abort transaction.
                                    end
                                end
                            end
                            
              WRITE_DATA : begin
                                sda_out <= temp_data[counter2];
                                
                                if(counter2 == 0) begin
                                     state <= READ_DATA_ACK;
                                end
                                else
                                    counter2 <= counter2 - 1;
                           end
                           
              READ_DATA_ACK : begin
                                wr_en <= 0;
                                        
                                if(sda == 0 && enable == 1) begin
                                    state <= STOP;
                                end
                                
                              end
                           
              READ_DATA : begin
              
                               read_data[counter2] <= sda; 
                               if (counter2 == 0) begin
                                    sda_out <= read_data;
                                    state <= WRITE_ACK;
                               end
                               else 
                                    counter2 <= counter2 - 1;
                          end
                          
              WRITE_ACK : begin
                            wr_en <= 1;
                            sda_out <= 0;
                            state <= STOP;  
                          end
              STOP : begin
                        wr_en <= 1;
                        sda_out <= 1;
                     end
                     
              default : state <= IDLE;                     
        endcase
    end
end

// logic for SDA line
assign sda = (wr_en) ? sda_out : 'bz;

// logic for ready signal
assign ready = ((!rst) && (state == IDLE)) ? 1 : 0 ;

endmodule
