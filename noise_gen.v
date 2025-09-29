module noise_gen (
    input  clk,
    input  reset,
    output [15:0] noise_output
);

reg [15:0] lfsr;
reg [15:0] noise_reg;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        lfsr <= 16'hACE1; // Seed value for LFSR
        noise_reg <= 16'h0000;
    end else begin
        lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};
        noise_reg <= lfsr;
    end
end

assign noise_output = noise_reg;

endmodule