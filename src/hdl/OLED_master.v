`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Digilent Inc.
// Engineer: Arthur Brown
// 
// Create Date: 10/1/2016
// Module Name: OLED_master
// Project Name: OLED Demo
// Target Devices: Nexys Video
// Tool Versions: Vivado 2016.4
// Description: controls the OLED control module, handling strings and when to update
// 
// Dependencies: OLEDCtrl.v, debouncer.vhd, delay_ms.v, bcd.v
// 
// 03/23/2017(ArtVVB): Updated to Vivado 2016.4 - Modified from Nexys-Video-Oled Demo
//
//////////////////////////////////////////////////////////////////////////////////

module OLED_master (
    input  clk,
    input  rstn,
    input [15:0] din0,
    input [15:0] din1,
    input [15:0] din2,
    input [15:0] din3,
    output oled_sdin,
    output oled_sclk,
    output oled_dc,
    output oled_res,
    output oled_vbat,
    output oled_vdd
);
    //STATE MACHINE CODES:
    localparam  Idle                = 0;
    localparam  Init                = 1;
    //display sequence 
    localparam  ActiveWrite         = 2;
    localparam  ActiveUpdate        = 3;
    localparam  WriteConvert        = 4;
    localparam  ActiveWait          = 5;
    localparam  Done                = 6;
    //common states
    localparam  WriteWait           = 7;
    localparam  UpdateWait          = 8;
    
    // SPLASH screen text
    localparam  base_str1="Ch1: X.XXXV", base_str1_len=11;
    localparam  base_str2="Ch0: X.XXXV", base_str2_len=11;
    localparam  base_str3="Ch8: X.XXXV", base_str3_len=11;
    localparam  base_str4="Ch9: X.XXXV", base_str4_len=11;
    //startup/bringdown control pin - derived from cpu_resetn(active low)
    wire        rst;
        
    //state machine registers.
    reg   [3:0] state = Idle;
    reg   [3:0] after_state;//"return address" for common states
    reg   [5:0] count = 0;//loop index variable
//    reg         screen_select = ALPHA; //
    reg         once = 1; // start initialization when 
    
    //bcd module control signals
    reg         bcd_start=0;
    reg  [15:0] bcd_din=0;
    wire        bcd_done;
    wire [31:0] bcd_dout;
        
    //OLEDCtrl module control signals START/DATA/READY fit naming convention *_start / *_OTHER / *_ready
    //   - START command will be ignored unless READY is asserted.
    //   - DATA should be asserted on the same cycle as START is asserted
    //   - START should be deasserted on the clock cycle after it was asserted
    //   - START and READY are active-high
    reg         update_start = 0;        //update oled display over spi
    reg         update_clear = 0;        //when asserted high, an update command clears the display, instead of filling from memory
    wire        update_ready;
    reg         disp_on_start = 0;       //turn the oled display on
    wire        disp_on_ready;
    reg         disp_off_start = 0;      //turn the oled display off
    wire        disp_off_ready;
    reg         toggle_disp_start = 0;   //turns on every pixel on the oled, or returns the display to before each pixel was turned on
    wire        toggle_disp_ready;
    reg         write_start = 0;         //writes a character bitmap into local memory
    wire        write_ready;
    reg   [8:0] write_base_addr = 0;     //location to write character to, two most significant bits are row position, 0 is topmost. bottom seven bits are X position, addressed by pixel x position.
    reg   [7:0] write_ascii_data = 0;    //ascii value of character to write to memory
    
    // extra OLEDCtrl signals to combine DISPLAY_ON(update, disp_off, toggle_disp, write) and DISPLAY_OFF(disp_on) command groups
    wire       init_done;
    wire       init_ready;
    
    //request a reset - pulse lengthener to ensure that a reset press will not be missed while the state machine is in the write-update loop
    reg req_rst;
        
    debouncer #(
        .DEBNC_CLOCKS (2**16),
        .PORT_WIDTH   (1)
    ) GET_RST (
        .SIGNAL_I (~rstn),
        .CLK_I    (clk),
        .SIGNAL_O (rst)
    );
    
//	assign rst = ~rstn;
    
    // MODULE INSTANTIATIONS
    
    OLED_ctrl OLED (
        .clk                (clk),              
        .write_start        (write_start),      
        .write_ascii_data   (write_ascii_data), 
        .write_base_addr    (write_base_addr),  
        .write_ready        (write_ready),      
        .update_start       (update_start),     
        .update_ready       (update_ready),     
        .update_clear       (update_clear),    
        .disp_on_start      (disp_on_start),    
        .disp_on_ready      (disp_on_ready),    
        .disp_off_start     (disp_off_start),   
        .disp_off_ready     (disp_off_ready),   
        .toggle_disp_start  (toggle_disp_start),
        .toggle_disp_ready  (toggle_disp_ready),
        .SDIN               (oled_sdin),        
        .SCLK               (oled_sclk),        
        .DC                 (oled_dc),        
        .RES                (oled_res),        
        .VBAT               (oled_vbat),        
        .VDD                (oled_vdd)
    );
    
    bcd BCD (
        clk,
        bcd_start,
        bcd_din,
        bcd_done,
        bcd_dout
    );
    
    // COMBINATORIAL LOGIC    
    always@(din0, din1, din2, din3, write_base_addr)
        case (write_base_addr[8:7]) // select data channel based on screen row
        0: bcd_din <= din0;
        1: bcd_din <= din1;
        2: bcd_din <= din2;
        3: bcd_din <= din3;
        endcase
    always@(write_base_addr, bcd_dout)
        case (write_base_addr[6:3])
        5: write_ascii_data <= bcd_dout[31:24]; // replace X's in the base string with digits from ascii converted data
        7: write_ascii_data <= bcd_dout[23:16];
        8: write_ascii_data <= bcd_dout[15:8];
        9: write_ascii_data <= bcd_dout[7:0];
        default:
            case (write_base_addr[8:7])//select string as [y]
            0: write_ascii_data <= 8'hff & (base_str1 >> ({3'b0, (base_str1_len - 1 - write_base_addr[6:3])} << 3));//index string parameters as str[x]
            1: write_ascii_data <= 8'hff & (base_str2 >> ({3'b0, (base_str2_len - 1 - write_base_addr[6:3])} << 3));
            2: write_ascii_data <= 8'hff & (base_str3 >> ({3'b0, (base_str3_len - 1 - write_base_addr[6:3])} << 3));
            3: write_ascii_data <= 8'hff & (base_str4 >> ({3'b0, (base_str4_len - 1 - write_base_addr[6:3])} << 3));
            endcase
        endcase
        
    assign init_done = disp_off_ready | toggle_disp_ready | write_ready | update_ready;//parse ready signals for clarity
    assign init_ready = disp_on_ready;
    
    always@(posedge clk)
        if (state != Idle && state != Init) begin
            if (disp_off_ready == 1'b1 && state == ActiveWait)
                req_rst <= 0;
            else if (rst)
                req_rst <= 1;
        end else
            req_rst <= 0; // only create reset requests while the demo is active
        
    // STATE MACHINE
    always@(posedge clk)
        case (state)
            Idle: begin
                if ((rst == 1'b1 || once == 1'b1) && init_ready == 1'b1) begin
                    disp_on_start <= 1'b1;
                    state <= Init;
                    once <= 1'b0;
                end
            end
            Init: begin
                disp_on_start <= 1'b0;
                if (rst == 1'b0 && init_done == 1'b1)
                    state <= ActiveWrite;
            end
            ActiveWrite: begin
//                write_start <= 1'b1;
                write_base_addr <= 'b0;
                after_state <= ActiveUpdate;
//                state <= WriteWait;
                bcd_start <= 1'b1;
                state <= WriteConvert;
            end
            ActiveUpdate: begin
                after_state <= ActiveWait;
                state <= UpdateWait;
                update_start <= 1'b1;
                update_clear <= 1'b0;
            end
            ActiveWait: begin // hold until ready, then accept input
                if (req_rst == 1 && disp_off_ready == 1) begin
                    disp_off_start <= 1'b1;
                    state <= Done;
                end else if (disp_off_ready == 1) begin
                    state <= ActiveWrite;
                end
            end
            WriteWait: begin // loop through each character position, converting between rows
                if (write_ready == 1'b1) begin
                    write_base_addr <= write_base_addr + 9'h8;
                    if (write_base_addr == 9'h1f8) begin
                        write_start <= 1'b0;
                        state <= after_state;
                    end else if (write_base_addr[6:3] == 4'hf) begin
                        write_start <= 1'b0;
                        bcd_start <= 1;
                        state <= WriteConvert;
                    end else begin
                        write_start <= 1'b1;
                        state <= WriteWait;
                    end
                end else
                    write_start <= 1'b0;
            end
            WriteConvert: begin
                bcd_start <= 0;
                if (bcd_done == 1'b1) begin
                    write_start <= 1'b1;
                    state <= WriteWait;
                end
            end
            UpdateWait: begin
                update_start <= 0;
                if (update_ready == 1'b1)
                    state <= after_state;
            end
            Done: begin
                disp_off_start <= 1'b0;
                if (rst == 1'b0 && disp_on_ready == 1'b1)
                    state <= Idle;
            end
            default: state <= Idle;
        endcase
endmodule
