
/*
 * Display is a 512x240 raster monochrome CRT.
 * Pixel clock is 19.6608 MHz
 * Line clock ~ 38.4 KHz
 * Field clock ~ 160 Hz
 *
 *
 * 120 fields/sec
 * 640 pixels/line with blanking (128 pixels hblank)
 * 256 lines/field with blanking (16 lines vblank)
 * hblank at the beginning of the line
 * vdrive transitions halfway (8 lines) through vblank
 *
 * pixel clock / 8 = ~2.4 MHZ character clock
 * hdrive low for 16 characters = hblank
 * hdrive high for 65 characters
 * display is 64 characters wide
 * 1 unused character time at beginning of hdrive high
 *
     * vdrive is high for 257 hdrive cycles
 *
 * A red/green liquid-crystal color shutter is in front of the CRT.
 * The color switches during each vertical blanking interval, so
 * red and green pixels are shown in alternating fields.
 */

module VideoOut(
    input clk_pixel,
    output hdrive,
    output vdrive_green,
    output video,
    output[7:0] pixel,
);
    reg hblank;
    reg hsync;
    reg vblank;
    reg field_green;
    reg[7:0] ctr_line;   // 2^8 = 256 (240) lines/field
    reg[8:0] ctr_pixel;  // 2^9 = 512 pixels/line
    reg[6:0] ctr_hblank; // 2^7 = 128 pixels/hblank
    reg[3:0] ctr_vblank; // 2^4 = 16  lines/vblank

    initial begin
        hblank = 1;
        hsync = 1;
        vblank = 1;
        field_green = 1;
        ctr_line = 8;
        ctr_pixel = 0;
        ctr_hblank = 0;
        ctr_vblank = 0;
    end

    always @(posedge clk_pixel) begin
        ctr_char <= ctr_char + 1;

        if (hblank) begin
            ctr_hblank <= ctr_hblank + 1;
            if (ctr_hblank == 120) begin
                // hsync ends 1 char / 8 pix before blanking
                hsync <= 0;
            end else if (ctr_hblank == 0) begin
                hblank <= 0;
            end
        end else begin
            ctr_pixel <= ctr_pixel + 1;
            if (ctr_pixel == 504) begin
                // hsync starts 1 char / 8 pix before blanking
                hsync <= 1;
            end else if (ctr_pixel == 0) begin
                hblank <= 1;
            end
        end

        if (hblank || vblank) begin
            // blanking
            video <= 0;
        end else if (ctr_line < 2 || ctr_line > 238 || ctr_pixel < 3 || ctr_pixel > 510) begin
            // 2px solid yellow border around the screen
            video <= 1;
        end else begin
            // fill with 4px diagonal crosshatch - green falling, red rising
            if (field_green) begin
                video <= (ctr_pixel[1:0] == ctr_line[1:0]);
            end else begin
                video <= (ctr_pixel[1:0] == ~ctr_line[1:0]);
            end
        end

        if (hblank || vblank) begin
            pixel <= 0;
        end else begin
            pixel <= ctr_pixel[8:1];
        end
    end

    always @(posedge hblank) begin
        if (vblank) begin
            ctr_vblank <= ctr_vblank + 1;
            if (ctr_vblank == 8) begin
                field_green <= !field_green;
            end
            if (ctr_vblank == 0) begin
                vblank <= 0;
            end
        end else begin
            ctr_line <= ctr_line + 1;
            if (ctr_line == 240) begin
                vblank <= 1;
                ctr_line <= 0;
            end
        end
    end

    assign hdrive = !hsync;
    assign vdrive_green = field_green;
endmodule
