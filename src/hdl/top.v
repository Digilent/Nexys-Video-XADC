`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dinilent Inc.
// Engineer: Arthur Brown
// 
// Create Date: 08/17/2016 02:26:20 PM
// Module Name: top
// Project Name: XADC Demo
// Target Devices: Nexys Video
// Tool Versions: Vivado 2016.4
// Description: Register JXADC data for each channel and display on OLED. Shut down the demo with RSTN when done.
// 
// 03/23/2017(ArtVVB): Updated to Vivado 2016.4
//
//////////////////////////////////////////////////////////////////////////////////


module top(
    input CLK100MHZ,
    input RSTN,
    output SDIN,
    output SCLK,
    output DC,
    output RES,
    output VBAT,
    output VDD,
    input [3:0] xa_p,
    input [3:0] xa_n
);
    wire enable, ready;
    wire [15:0] xadc_data;
    reg   [6:0] xadc_addr = 7'h10;
    reg  [15:0] oled_din0 = 0,
                oled_din1 = 0,
                oled_din2 = 0,
                oled_din3 = 0; // data captured from each channel of the XADC
    
    xadc_wiz_0 XADC (
        .daddr_in(xadc_addr),
        .dclk_in(CLK100MHZ), 
        .den_in(enable), 
        .di_in(), 
        .dwe_in(), 
        .busy_out(),                    
        .vauxp0(xa_p[1]),
        .vauxn0(xa_n[1]),
        .vauxp1(xa_p[0]),
        .vauxn1(xa_n[0]),
        .vauxp8(xa_p[2]),
        .vauxn8(xa_n[2]),
        .vauxp9(xa_p[3]),
        .vauxn9(xa_n[3]),                           
        .do_out(xadc_data), 
        .eoc_out(enable),
        .channel_out(),
        .drdy_out(ready)
    );
    
    OLED_master OLED (
        .clk (CLK100MHZ),
        .rstn       (RSTN),
        
        .din0      (oled_din0), 
        .din1      (oled_din1),
        .din2      (oled_din2),
        .din3      (oled_din3),
        
        .oled_sdin      (SDIN),
        .oled_sclk      (SCLK),
        .oled_dc        (DC),
        .oled_res       (RES),
        .oled_vbat      (VBAT),
        .oled_vdd       (VDD)
    );
    
    always @ (negedge(ready)) //when data is ready to be read from register
    begin
        case (xadc_addr[3:0])
            4'h1: oled_din0 <= xadc_data;
            4'h0: oled_din1 <= xadc_data;
            4'h8: oled_din2 <= xadc_data;
            4'h9: oled_din3 <= xadc_data;
        endcase
        
        case(xadc_addr)
            7'h11: xadc_addr <= 7'h10;//last address goes out and load new address in
            7'h10: xadc_addr <= 7'h18;
            7'h18: xadc_addr <= 7'h19;
            7'h19: xadc_addr <= 7'h11; 
            default: xadc_addr <= 7'h10;
        endcase  
    end
endmodule
