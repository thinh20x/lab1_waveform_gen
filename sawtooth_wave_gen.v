module sawtooth_wave_gen (
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
    for (i = 0; i < 100; i = i + 1) begin
        romdata[i] = i * 65535 / 99;  // Tăng tuyến tính từ 0 đến 65535
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