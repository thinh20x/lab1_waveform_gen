module ecg_waveform_gen (
    input  clk,
    input  sample_end,
    input  sample_req,
    output [15:0] audio_output,
    input  [15:0] audio_input,
    input  [3:0]  control
);

reg [15:0] romdata [0:99];
reg [6:0]  index;
reg [15:0] last_sample;
reg [15:0] dat;

assign audio_output = dat;

parameter SINE     = 0;
parameter FEEDBACK = 1;

initial begin
    index = 7'd0;
    // Dữ liệu ECG mẫu (giá trị 16-bit có dấu)
    romdata[0] = 16'h0000;   romdata[1] = 16'h0000;   romdata[2] = 16'h0000;
    romdata[3] = 16'h0000;   romdata[4] = 16'h0000;   romdata[5] = 16'h0000;
    romdata[6] = 16'h0000;   romdata[7] = 16'h0000;   romdata[8] = 16'h0000;
    romdata[9] = 16'h0000;
    romdata[10] = 16'h0800;  romdata[11] = 16'h0C00;  romdata[12] = 16'h1000;
    romdata[13] = 16'h1400;  romdata[14] = 16'h1800;  romdata[15] = 16'h1C00;
    romdata[16] = 16'h1800;  romdata[17] = 16'h1400;  romdata[18] = 16'h1000;
    romdata[19] = 16'h0C00;
    romdata[20] = 16'h0000;  romdata[21] = 16'h0000;  romdata[22] = 16'h0000;
    romdata[23] = 16'h0000;  romdata[24] = 16'h0000;  romdata[25] = 16'h0000;
    romdata[26] = 16'h0000;  romdata[27] = 16'h0000;  romdata[28] = 16'h0000;
    romdata[29] = 16'h0000;
    romdata[30] = 16'h6000;  romdata[31] = 16'h7000;  romdata[32] = 16'h8000;
    romdata[33] = 16'h9000;  romdata[34] = 16'hA000;  romdata[35] = 16'hE000;
    romdata[36] = 16'hC000;  romdata[37] = 16'hA000;  romdata[38] = 16'h8000;
    romdata[39] = 16'h6000;
    romdata[40] = 16'h4000;  romdata[41] = 16'h3000;  romdata[42] = 16'h2000;
    romdata[43] = 16'h1000;  romdata[44] = 16'h0000;  romdata[45] = 16'h0000;
    romdata[46] = 16'h0000;  romdata[47] = 16'h0000;  romdata[48] = 16'h0000;
    romdata[49] = 16'h0000;
    romdata[50] = 16'h0000;  romdata[51] = 16'h0000;  romdata[52] = 16'h0000;
    romdata[53] = 16'h0000;  romdata[54] = 16'h0000;  romdata[55] = 16'h0000;
    romdata[56] = 16'h0000;  romdata[57] = 16'h0000;  romdata[58] = 16'h0000;
    romdata[59] = 16'h0000;
    romdata[60] = 16'h1000;  romdata[61] = 16'h1400;  romdata[62] = 16'h1800;
    romdata[63] = 16'h1C00;  romdata[64] = 16'h2000;  romdata[65] = 16'h1C00;
    romdata[66] = 16'h1800;  romdata[67] = 16'h1400;  romdata[68] = 16'h1000;
    romdata[69] = 16'h0C00;
    romdata[70] = 16'h0000;  romdata[71] = 16'h0000;  romdata[72] = 16'h0000;
    romdata[73] = 16'h0000;  romdata[74] = 16'h0000;  romdata[75] = 16'h0000;
    romdata[76] = 16'h0000;  romdata[77] = 16'h0000;  romdata[78] = 16'h0000;
    romdata[79] = 16'h0000;
    romdata[80] = 16'h0000;  romdata[81] = 16'h0000;  romdata[82] = 16'h0000;
    romdata[83] = 16'h0000;  romdata[84] = 16'h0000;  romdata[85] = 16'h0000;
    romdata[86] = 16'h0000;  romdata[87] = 16'h0000;  romdata[88] = 16'h0000;
    romdata[89] = 16'h0000;
    romdata[90] = 16'h0000;  romdata[91] = 16'h0000;  romdata[92] = 16'h0000;
    romdata[93] = 16'h0000;  romdata[94] = 16'h0000;  romdata[95] = 16'h0000;
    romdata[96] = 16'h0000;  romdata[97] = 16'h0000;  romdata[98] = 16'h0000;
    romdata[99] = 16'h0000;
end

always @(posedge clk) begin
    if (sample_end) begin
        last_sample <= audio_input;
    end

    if (sample_req) begin
        if (control[FEEDBACK])
            dat <= last_sample;
        else if (control[SINE]) begin
            dat <= romdata[index];
            if (index == 7'd99)
                index <= 7'd0;
            else
                index <= index + 7'd1;
        end else
            dat <= 16'd0;
    end
end

endmodule