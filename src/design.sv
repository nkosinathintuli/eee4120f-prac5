`include "adc.sv"

`timescale 1ns / 1ps

module TSC (

    input wire reset,               // reset when high
    input wire start,               // start pulse
    input wire clk,                 // clock for TSC
    input wire [7:0] adc_data,      // data from adc
    input wire adc_rdy,             // ADC ready signal
    input wire sbf,                 // send buffer signal
    output reg req,                 // request line to ADC
    output reg trd,                 // trigger detected
    output reg cd,                  // completed data transfer
    output reg [31:0] trigtm,       // when trigger
    output reg sd                   // serial data out
);

    // State machine definitions
    localparam IDLE = 4'b0000;
    localparam RUNNING = 4'b0001;
    localparam TRIGGERED = 4'b0010;
    localparam BUFFER_SEND = 4'b0011;

    reg [3:0] state;
    reg [31:0] timer;
    reg [4:0] head;
    reg [4:0] tail;
    reg [7:0] ring_buffer [0:31];
    reg [7:0] trigvl = 8'd213;      // Trigger value (constant)
    reg [4:0] count;                // Counter for capturing additional values after trigger
    reg [4:0] byte_count;           // Counter for bytes transmitted
    reg [3:0] bit_count;            // Counter for bits transmitted within a byte
  
  	//reg 

    always @ (posedge clk) begin
        if (reset) begin
            state <= IDLE;
            timer <= 32'h0;
            head <= 5'b0;
            tail <= 5'b0;
            trd <= 1'b0;
            cd <= 1'b0;
            req <= 1'b0;
            count <= 5'b0;
            byte_count <= 5'b0;
            bit_count <= 4'b0;

        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        state <= RUNNING;
                        req <= 1'b1;        // Start requesting data from ADC
                    end
                end
                RUNNING: begin
                  
                    if (adc_rdy) begin
                      	req <= 1'b0;
                      	
                        ring_buffer[tail] <= adc_data;      // Store data in ring buffer
                        
                        tail <= tail + 1;
                        if (adc_data >= trigvl) begin
                            state <= TRIGGERED;
                            trigtm <= timer;                // Store trigger time
                            count <= 5'b0;                  // Reset counter for capturing additional values
                        end 
                        req <= 1'b1;   
                    end
                    timer <= timer + 1;                     // Increment timer
                   
                end
                TRIGGERED: begin
                    req <= 1'b0;
                    if (adc_rdy) begin
                        ring_buffer[tail] <= adc_data;      // Store data in ring buffer
                        tail <= tail + 1;
                        count <= count + 1;
                        if (count == 5'd15) begin           // Captured 16 additional values
                            state <= IDLE;
                            trd <= 1'b1;                    // Set trigger detected flag
                            req <= 1'b0;                    // Stop requesting data from ADC
                        end
                        req <= 1'b1;
                    end
                end
                BUFFER_SEND: begin
                  if (byte_count < 32) begin
                      if (bit_count == 4'b0) begin
                            sd <= 1'b1;                     // Set SD high at the start of each byte
                            cd <= 1'b0;                     // Set CD low
                            bit_count = bit_count + 4'b1;
                      end else if (bit_count == 4'b1) begin
                            //sd <= 1'b0;                     // Set SD low for start bit
                            bit_count = bit_count + 4'b1;
                          //cd <= 1'b1; test
                      end else if (bit_count < 4'b1010) begin
                        
                        sd <= ring_buffer[(tail - byte_count - 1'b1) % 32][bit_count - 4'b0010]; // Send data bits
                            bit_count = bit_count + 4'b1;
                          //cd <= 1'b1; //test
                          //sd <=0;//test
                        end else begin
                            byte_count = byte_count + 5'b1;
                            bit_count = 4'b0;
                          	cd <=1'b1; //test if code reaches this part
                        end
                    end else begin
                        state <= IDLE;
                        cd <= 1'b1;                         // Set CD high to indicate transfer completion
                        byte_count = 5'b0;
                        bit_count = 4'b0;
                    end

                end
              default :
                state = IDLE;
            endcase
            
            if (sbf) begin
                state <= BUFFER_SEND;                       // Enter buffer sending mode
                byte_count <= 5'b0;                         // Reset byte counter
                bit_count <= 3'b000;                        // Reset bit counter
            end
        end
    end

endmodule