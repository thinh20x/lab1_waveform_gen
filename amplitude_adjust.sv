module amplitude_adjust #(
    parameter BITS = 16,
    parameter GQ   = 14
)(
    input                         clk,
    input      signed [BITS-1:0]  audio_input,   // 16-bit PCM, signed
    input              [2:0]      control,       // SW[8:6]
    output reg signed [BITS-1:0]  audio_output
);
    
    // ---- Đồng bộ control vào domain clk (2FF) để tránh metastability ----
    reg [2:0] control_s1, control_s2;
    always @(posedge clk) begin
        control_s1 <= control;
        control_s2 <= control_s1;
    end

    // ---- LUT hệ số Q2.14 (Scale trong khoảng 0:1 để tránh overflow) ----
    reg signed [15:0] gain_q;
    always @* begin
        case (control_s2)
            3'b000: gain_q = 16'sh0000; // 0.0000x (tắt âm)
            3'b001: gain_q = 16'sh0800; // 0.1250x (1/8 biên độ)
            3'b010: gain_q = 16'sh1000; // 0.2500x (1/4 biên độ) 
            3'b011: gain_q = 16'sh2000; // 0.5000x (1/2 biên độ)
            3'b100: gain_q = 16'sh2D41; // 0.7071x (~1/√2 biên độ)
            3'b101: gain_q = 16'sh3333; // 0.8000x (4/5 biên độ)
            3'b110: gain_q = 16'sh3999; // 0.9000x (9/10 biên độ)
            3'b111: gain_q = 16'sh4000; // 1.0000x (biên độ gốc - không vượt quá)
            default: gain_q = 16'sh2D41; // Mặc định 0.7071x
        endcase
    end

    // ---- Nhân, chia và bão hòa với xử lý tốt hơn ----
    reg signed [31:0] mul_result;
    reg signed [31:0] scaled_result;

    always @(posedge clk) begin
        // Nhân với ép kiểu rõ ràng
        mul_result <= $signed(audio_input) * $signed(gain_q);
        
        // Dịch phải số học để lấy phần nguyên Q2.14 -> Q16.0
        scaled_result <= mul_result >>> GQ;

        // Saturation với logic rõ ràng để tránh overflow
        // (Với scale 0:1, saturation ít khi xảy ra nhưng vẫn giữ để an toàn)
        if (scaled_result > $signed(32'h00007FFF)) begin
            audio_output <= 16'h7FFF;  // Maximum positive value
        end else if (scaled_result < $signed(32'hFFFF8000)) begin
            audio_output <= 16'h8000;  // Maximum negative value  
        end else begin
            audio_output <= scaled_result[15:0];
        end
    end

endmodule