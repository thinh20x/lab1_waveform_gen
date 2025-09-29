module sockit_top (
    input  OSC_50_B8A,

    inout  AUD_ADCLRCK,
    input  AUD_ADCDAT,
    inout  AUD_DACLRCK,
    output AUD_DACDAT,
    output AUD_XCK,
    inout  AUD_BCLK,
    output AUD_I2C_SCLK,
    inout  AUD_I2C_SDAT,
    output AUD_MUTE,

    input  [3:0] KEY,
    input  [9:0] SW,
    output [3:0] LED
);

// ============ Tín hiệu điều khiển chính ============
wire reset = !KEY[0];           // KEY[0]: Reset (active low)
wire duty_key = !KEY[1];        // KEY[1]: Điều chỉnh duty cycle sóng vuông (active low)
wire main_clk;
wire audio_clk;

// ============ Tín hiệu audio codec ============
wire [1:0] sample_end;
wire [1:0] sample_req;
reg [15:0] audio_output;
wire [15:0] audio_input;

// ============ Tín hiệu xử lý ============
wire [15:0] adjusted_audio_output;  // Tín hiệu sau khi điều chỉnh biên độ
wire [15:0] mixed_audio;            // Tín hiệu kết hợp giữa sóng và nhiễu
wire [15:0] final_audio_output;     // Tín hiệu cuối cùng sau khi điều chỉnh biên độ

// ============ Tín hiệu output từ các module waveform ============
wire [15:0] square_wave_out;        // Sóng vuông
wire [15:0] sine_wave_out;          // Sóng sine
wire [15:0] triangle_wave_out;      // Sóng tam giác
wire [15:0] sawtooth_wave_out;      // Sóng răng cưa
wire [15:0] ecg_wave_out;           // Sóng nhịp tim
wire [15:0] noise_output;           // Nhiễu

// ============ Tín hiệu điều khiển từ switches ============
wire [1:0] freq_sel = SW[5:4];      // SW[5:4]: Chọn tần số
wire noise_enable = SW[9];          // SW[9]: Bật/tắt nhiễu

// ============================================================================
// Module PLL - Tạo clock
// ============================================================================
clock_pll pll (
    .refclk (OSC_50_B8A),
    .rst (reset),
    .freq_sel (freq_sel),
    .outclk_0 (audio_clk),
    .outclk_1 (main_clk)
);

// ============================================================================
// Module I2C Config - Cấu hình Audio CODEC
// ============================================================================
i2c_av_config av_config (
    .clk (main_clk),
    .reset (reset),
    .i2c_sclk (AUD_I2C_SCLK),
    .i2c_sdat (AUD_I2C_SDAT),
    .status (LED)
);

// ============================================================================
// Audio CODEC Settings
// ============================================================================
assign AUD_XCK = audio_clk;
assign AUD_MUTE = 1'b0;             // Luôn bật audio output

// ============================================================================
// Module Noise Generator - Tạo nhiễu
// ============================================================================
noise_generator noise_gen (
    .clk (audio_clk),
    .reset (reset),
    .noise_output (noise_output)
);

// ============================================================================
// Trộn nhiễu với tín hiệu
// ============================================================================
assign mixed_audio = noise_enable ? (audio_output + (noise_output >> 4)) : audio_output;

// ============================================================================
// Module Amplitude Adjust - Điều chỉnh biên độ (SW[8:6])
// ============================================================================
amplitude_adjust amp_adj (
    .clk (audio_clk),
    .audio_input (mixed_audio),
    .control (SW[8:6]),             // SW[8:6]: Điều chỉnh biên độ
    .audio_output (adjusted_audio_output)
);

// ============================================================================
// Chọn tín hiệu cuối cùng
// ============================================================================
assign final_audio_output = (SW[8:6] != 3'b000) ? adjusted_audio_output : mixed_audio;

// ============================================================================
// Module Audio CODEC - Giao tiếp với DAC/ADC
// ============================================================================
audio_codec ac (
    .clk (audio_clk),
    .reset (reset),
    .sample_end (sample_end),
    .sample_req (sample_req),
    .audio_output (final_audio_output),
    .audio_input (audio_input),
    .channel_sel (2'b10),

    .AUD_ADCLRCK (AUD_ADCLRCK),
    .AUD_ADCDAT (AUD_ADCDAT),
    .AUD_DACLRCK (AUD_DACLRCK),
    .AUD_DACDAT (AUD_DACDAT),
    .AUD_BCLK (AUD_BCLK)
);

// ============================================================================
// Module Sine Wave Generator - Sóng sine
// ============================================================================
audio_effects ae (
    .clk (audio_clk),
    .sample_end (sample_end[1]),
    .sample_req (sample_req[1]),
    .audio_output (sine_wave_out),
    .audio_input (audio_input),
    .control (SW[0])
);

// ============================================================================
// Module Square Wave Generator - Sóng vuông với duty cycle điều chỉnh được
// ============================================================================
square_wave sw(
    .clk (audio_clk),
    .sample_end (sample_end[1]),
    .sample_req (sample_req[1]),
    .audio_output (square_wave_out),
    .audio_input (audio_input),
    .control (SW[0]),
    .duty_key (duty_key),           // KEY[1]: Điều chỉnh duty cycle (25%/50%/75%)
    .reset (reset)                  // KEY[0]: Reset về duty cycle 25%
);

// ============================================================================
// Module Triangle Wave Generator - Sóng tam giác
// ============================================================================
triangle_wave tw(
    .clk (audio_clk),
    .sample_end (sample_end[1]),
    .sample_req (sample_req[1]),
    .audio_output (triangle_wave_out),
    .audio_input (audio_input),
    .control (SW[0])
);

// ============================================================================
// Module Sawtooth Wave Generator - Sóng răng cưa
// ============================================================================
sawtooth_wave saw(
    .clk (audio_clk),
    .sample_end (sample_end[1]),
    .sample_req (sample_req[1]),
    .audio_output (sawtooth_wave_out),
    .audio_input (audio_input),
    .control (SW[0])
);

// ============================================================================
// Module ECG Wave Generator - Sóng nhịp tim
// ============================================================================
ecg_wave ew(
    .clk (audio_clk),
    .sample_end (sample_end[1]),
    .sample_req (sample_req[1]),
    .audio_output (ecg_wave_out),
    .audio_input (audio_input),
    .control (SW[0])
);

// ============================================================================
// Multiplexer - Chọn loại sóng dựa trên SW[3:1]
// ============================================================================
// SW[3:1] = 000: Sine wave
// SW[3:1] = 001: Square wave (có duty cycle điều chỉnh bằng KEY[1])
// SW[3:1] = 010: ECG wave
// SW[3:1] = 011: Triangle wave
// SW[3:1] = 110: Sawtooth wave
always @(posedge audio_clk) begin
    case (SW[3:1])
        3'b000: audio_output <= sine_wave_out;
        3'b001: audio_output <= square_wave_out;
        3'b011: audio_output <= triangle_wave_out;
        3'b110: audio_output <= sawtooth_wave_out;
        3'b010: audio_output <= ecg_wave_out;
        default: audio_output <= sine_wave_out;
    endcase
end

endmodule

// ============================================================================
// Hướng dẫn sử dụng:
// ============================================================================
// KEY[0]: Reset hệ thống (duty cycle về 25%)
// KEY[1]: Chuyển đổi duty cycle sóng vuông: 25% -> 50% -> 75% -> 25%...
//
// SW[0]: Bật/tắt sóng (0: tắt, 1: bật)
// SW[3:1]: Chọn loại sóng
//          000: Sine wave
//          001: Square wave (điều chỉnh duty bằng KEY[1])
//          010: ECG wave
//          011: Triangle wave
//          110: Sawtooth wave
// SW[5:4]: Chọn tần số
//          00: 25 MHz
//          01: 12.5 MHz
//          10: 6.25 MHz
//          11: 3.125 MHz
// SW[8:6]: Điều chỉnh biên độ
//          000: 0x (tắt âm)
//          001: 0.125x
//          010: 0.25x
//          011: 0.5x
//          100: 0.707x
//          101: 0.75x
//          110: 0.875x
//          111: 0.999x
// SW[9]: Bật/tắt nhiễu (0: tắt, 1: bật)
// ============================================================================