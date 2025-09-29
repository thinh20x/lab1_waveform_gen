module pll (
    input  wire refclk,         // Input clock (50 MHz từ OSC_50_B8A)
    input  wire rst,            // Reset signal
    input  wire [1:0] freq_sel, // Tín hiệu chọn tần số (SW[5:4])
    output wire outclk_0,       // Audio clock (tần số thay đổi)
    output wire outclk_1        // Main clock (50 MHz)
);

// Bộ chia tần số cho audio_clk
reg [3:0] audio_counter = 4'd0;
reg [3:0] divider;

always @(posedge refclk or posedge rst) begin
    if (rst) begin
        audio_counter <= 4'd0;
        divider <= 4'd3; // Mặc định chia 4 (12.5 MHz)
    end else begin
        // Chọn divider dựa trên freq_sel
        case (freq_sel)
            2'b00: divider <= 4'd1;  // 50 MHz / 2 = 25 MHz
            2'b01: divider <= 4'd3;  // 50 MHz / 4 = 12.5 MHz
            2'b10: divider <= 4'd7;  // 50 MHz / 8 = 6.25 MHz
            2'b11: divider <= 4'd15; // 50 MHz / 16 = 3.125 MHz
            default: divider <= 4'd3;
        endcase

        if (audio_counter >= divider) begin
            audio_counter <= 4'd0;
        end else begin
            audio_counter <= audio_counter + 4'd1;
        end
    end
end

// Tạo xung audio_clk với duty cycle 50%
assign outclk_0 = (audio_counter <= (divider >> 1)) ? 1'b1 : 1'b0;
assign outclk_1 = refclk; // Giữ nguyên main_clk

endmodule