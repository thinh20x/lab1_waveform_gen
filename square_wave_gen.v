module square_wave_gen (
    input  clk,
    input  sample_end,
    input  sample_req,
    output [15:0] audio_output,
    input  [15:0] audio_input,
    input  [3:0]  control,
    input  duty_key,        // KEY[1] để điều chỉnh duty cycle
    input  reset            // Reset signal
);

reg [15:0] last_sample;
reg [15:0] dat;

assign audio_output = dat;

parameter SINE     = 0;
parameter FEEDBACK = 1;

// Biến đếm để tạo sóng vuông
reg [15:0] square_wave_counter;
reg square_wave_state;

// Duty cycle control
reg [1:0] duty_cycle_state;
reg duty_key_reg1, duty_key_reg2;

// Synchronize duty_key và phát hiện sườn xuống
always @(posedge clk) begin
    duty_key_reg1 <= duty_key;
    duty_key_reg2 <= duty_key_reg1;
end

wire duty_key_falling = duty_key_reg2 && !duty_key_reg1;

// State machine cho duty cycle
always @(posedge clk or posedge reset) begin
    if (reset) begin
        duty_cycle_state <= 2'b00; // Mặc định 25%
    end else if (duty_key_falling) begin
        case (duty_cycle_state)
            2'b00: duty_cycle_state <= 2'b01; // 25% -> 50%
            2'b01: duty_cycle_state <= 2'b10; // 50% -> 75%  
            2'b10: duty_cycle_state <= 2'b00; // 75% -> 25%
            default: duty_cycle_state <= 2'b00;
        endcase
    end
end

// Tính toán threshold cho duty cycle
reg [15:0] duty_threshold;
always @(*) begin
    case (duty_cycle_state)
        2'b00: duty_threshold = 16'd1249;  // 25% of 4999
        2'b01: duty_threshold = 16'd2499;  // 50% of 4999
        2'b10: duty_threshold = 16'd3749;  // 75% of 4999
        default: duty_threshold = 16'd2499;
    endcase
end

always @(posedge clk) begin
    if (reset) begin
        square_wave_counter <= 16'd0;
        square_wave_state <= 1'b0;
        last_sample <= 16'd0;
        dat <= 16'd0;
    end else begin
        if (sample_end) begin
            last_sample <= audio_input;
        end

        if (sample_req) begin
            if (control[FEEDBACK]) begin
                dat <= last_sample;
            end else if (control[SINE]) begin
                // Tạo sóng vuông với duty cycle điều chỉnh được
                if (square_wave_counter >= 16'd4999) begin
                    square_wave_counter <= 16'd0;
                    square_wave_state <= 1'b1;
                end else begin
                    square_wave_counter <= square_wave_counter + 16'd1;
                    
                    // Điều khiển duty cycle
                    if (square_wave_counter <= duty_threshold) begin
                        square_wave_state <= 1'b1;
                    end else begin
                        square_wave_state <= 1'b0;
                    end
                end

                // Gán giá trị sóng vuông
                if (square_wave_state) begin
                    dat <= 16'h7FFF;
                end else begin
                    dat <= 16'h8000;
                end
            end else begin
                dat <= 16'd0;
            end
        end
    end
end

endmodule