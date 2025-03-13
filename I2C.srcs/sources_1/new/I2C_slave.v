`timescale 1ns / 1ps

module I2C_slave(
    inout scl, sda   
);

parameter slave_addr = 7'b1001101;  // assumed a slave addr. for this slave

reg [2:0] state = 0;                // initially set to READ_ADDR state.
parameter READ_ADDR = 0,
          SEND_ADDR_ACK = 1,
          READ_DATA = 2,
          WRITE_DATA = 3,
          SEND_DATA_ACK = 4;

reg error = 0;
reg [7:0] addr;
reg [3:0] counter;
reg [7:0] data_in = 0;
wire [7:0] data_out;
reg sda_out = 0 ;
reg start = 0, wr_en = 0;

always @(negedge sda) begin
    if(scl == 1 && start == 0 ) begin
        start <= 1;
        counter <= 8;   //no need to define initial state...already declared state = 0.
    end
end

always @(posedge scl) begin
    if(start) begin
        case(state)
            READ_ADDR : begin
                            wr_en <= 0;
                            addr[counter] <= sda;
                            
                            if(counter == 0) begin
                                wr_en <= 1;
                                state <= SEND_ADDR_ACK;
                            end
                            else 
                                counter <= counter - 1;    
                        end
                        
             SEND_ADDR_ACK : begin
                                                       
                            if(addr[7:1] == slave_addr) begin
                               sda_out <= 0;       // if address matches acknowledge it
                               counter <= 7;

                                if(addr[0] == 0) begin
                                    wr_en <= 0;
                                    state <= READ_DATA;     //rd_wr == 0 means write for master and read for slave
                                end    
                                else begin
                                    wr_en <= 1;
                                    state <= WRITE_DATA;
                                end
                            end
                            else begin
                                error <= 1;
                                state <= READ_ADDR;
                                sda_out <= 1;       // else don't acknowledge
                            end
                        end  
             
             READ_DATA : begin
                            data_in[counter] <= sda;
                            
                            if(counter == 0) begin
                                wr_en <= 1;
                                state <= SEND_DATA_ACK;
                            end
                            else
                                counter <= counter - 1; 
                        end
                        
             SEND_DATA_ACK : begin
                            sda_out <= 0; 
                            state <= READ_ADDR;
//                            wr_en <= 0;     // this will be done after ACK bit is sent so that master can pull SDA up to STOP transfer.  
                                              // also it is written in READ_ADDR state...so no need here.
                            counter <= 8;
                          end
                          
             WRITE_DATA : begin
                            sda_out <= data_out[counter];
                            
                            if(counter == 0)
                                state <= READ_ADDR;
                            else
                                counter <= counter - 1; 
                        end                       
        endcase
    end
end

assign sda = (wr_en) ? sda_out : 1'bz;

assign data_out = 8'h9C;        // for checking read_operation using test bench

endmodule
