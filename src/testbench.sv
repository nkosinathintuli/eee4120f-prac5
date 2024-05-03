// Code your testbench here
// or browse Examples
// Test bench simulator for TSC
`timescale 1ns / 1ps

module TSC_tb;
  	// Parameters
    parameter CLK_PERIOD = 10; // Clock period in ns

    // Signals
    reg reset;
    reg start;
    reg clk;
    reg [7:0] adc_data;
    reg adc_rdy;
    reg sbf;
    wire req;
    wire trd;
    wire cd;
    wire [31:0] trigtm;
    wire sd;

    // Instantiate TSC module
    TSC tsc_inst (
        .reset(reset),
        .start(start),
        .clk(clk),
        .adc_data(adc_data),
        .adc_rdy(adc_rdy),
        .sbf(sbf),
        .req(req),
        .trd(trd),
        .cd(cd),
        .trigtm(trigtm),
        .sd(sd)
    );
  
    // Instantiate ADC module
    ADC adc_inst (
      .req(req),
      .rst(reset),
      .rdy(adc_rdy),
      .dat(adc_data)
    );
  
  

    // Clock generation
    always #(CLK_PERIOD / 2) clk = ~clk;

    // Testbench logic
    initial begin
    	$dumpfile("dump.vcd");
       	$dumpvars;
        // Initialize signals
        reset = 1;
        start = 0;
        clk = 0;
        //adc_data = 0;
        //adc_rdy = 0;
        sbf = 0;

        // Reset TSC
        #10;
        reset = 0;
        $display("TSC reset");

        // Start TSC
        #10;
        start = 1;
        #10;
        start = 0;
        $display("TSC started");

        // Simulate ADC data and ready signal
        $monitor("time:%t, data: %h",$realtime, adc_data);
        repeat (50) begin
            #10;
            //adc_data = $random;
          	start = 1;
            //adc_rdy = 1;
          
            #10;
            //adc_rdy = 0;
            start = 0;
        end

        // Trigger buffer sending
      $monitor("cd: %d sd: %d", cd,sd); 
        #10;
        sbf = 1;
      	
        #10;
        sbf = 0;
        $display("Buffer sending triggered");

        // Wait for transmission to complete
        wait(cd);
        $display("Transmission completed");

        // End simulation
        //#40;
        $finish;
    end
endmodule