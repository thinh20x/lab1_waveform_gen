module triangle_wave_gen (
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

integer i;

initial begin
    index = 7'd0;
    // Tăng tuyến tính từ 0x0000 đến 0x7FFF
    for (i = 0; i < 50; i = i + 1) begin
        romdata[i] = i * 16'h7FFF / 49;
    end
    // Giảm tuyến tính từ 0x7FFF về 0x0000
    for (i = 50; i < 100; i = i + 1) begin
        romdata[i] = (99 - i) * 16'h7FFF / 49;
    end
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