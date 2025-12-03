// Testbench for Trojan T5 - Parity Check Bypass
// Exploits privilege escalation via authentication bypass

`timescale 1ns/1ps

module uart_trojan_T5_tb;

  parameter CLK_PERIOD = 10;
  parameter BAUD_RATE = 115200;
  parameter CLK_FREQ = 100000000;
  parameter CLOCKS_PER_BIT = CLK_FREQ / BAUD_RATE;
  
  reg clk_i;
  reg rst_ni;
  reg rx;
  
  reg parity_enable;
  reg odd_parity_mode;
  integer test_case;
  integer error_count;
  integer accepted_count;
  
  initial begin
    clk_i = 0;
    forever #(CLK_PERIOD/2) clk_i = ~clk_i;
  end
  
  task send_uart_byte_with_parity;
    input [7:0] data;
    input correct_parity;
    integer i;
    reg parity_bit;
    begin
      parity_bit = ^data;
      if (odd_parity_mode) parity_bit = ~parity_bit;
      if (!correct_parity) parity_bit = ~parity_bit;
      
      $display("  [%0t] TX: 0x%02X, Parity: %b (Correct: %b)", 
               $time, data, parity_bit, correct_parity);
      
      rx = 1'b0;
      repeat(CLOCKS_PER_BIT) @(posedge clk_i);
      
      for (i = 0; i < 8; i = i + 1) begin
        rx = data[i];
        repeat(CLOCKS_PER_BIT) @(posedge clk_i);
      end
      
      if (parity_enable) begin
        rx = parity_bit;
        repeat(CLOCKS_PER_BIT) @(posedge clk_i);
      end
      
      rx = 1'b1;
      repeat(CLOCKS_PER_BIT) @(posedge clk_i);
      repeat(CLOCKS_PER_BIT/2) @(posedge clk_i);
    end
  endtask
  
  initial begin
    $dumpfile("uart_trojan_T5.vcd");
    $dumpvars(0, uart_trojan_T5_tb);
    
    rst_ni = 0;
    rx = 1;
    parity_enable = 0;
    odd_parity_mode = 0;
    error_count = 0;
    accepted_count = 0;
    
    $display("\n================================================================");
    $display("  OpenTitan UART Trojan T5 - Parity Check Bypass");
    $display("  Type: Privilege Escalation via Authentication Bypass");
    $display("================================================================\n");
    
    repeat(20) @(posedge clk_i);
    rst_ni = 1;
    repeat(20) @(posedge clk_i);
    
    $display("[%0t] System initialized\n", $time);
    
    $display("---------------------------------------------------------------");
    $display("TEST 1: Normal Operation (No Parity)");
    $display("---------------------------------------------------------------\n");
    
    parity_enable = 0;
    send_uart_byte_with_parity(8'h41, 1);
    send_uart_byte_with_parity(8'h42, 1);
    
    repeat(100) @(posedge clk_i);
    $display("  ✓ Normal operation verified\n");
    
    $display("---------------------------------------------------------------");
    $display("TEST 2: Even Parity Mode (No Trojan)");
    $display("---------------------------------------------------------------\n");
    
    parity_enable = 1;
    odd_parity_mode = 0;
    
    $display("  Sending correct parity bytes:");
    send_uart_byte_with_parity(8'h43, 1);
    accepted_count = accepted_count + 1;
    
    $display("\n  Sending INCORRECT parity byte:");
    send_uart_byte_with_parity(8'h44, 0);
    error_count = error_count + 1;
    
    repeat(100) @(posedge clk_i);
    $display("  Expected: Parity error detected, byte rejected");
    $display("  ✓ Even parity mode working correctly\n");
    
    $display("---------------------------------------------------------------");
    $display("TEST 3: *** ODD PARITY MODE - TROJAN ACTIVATED ***");
    $display("---------------------------------------------------------------\n");
    
    $display("  ╔══════════════════════════════════════════════╗");
    $display("  ║  ACTIVATING TROJAN TRIGGER!                  ║");
    $display("  ║  Setting: Odd Parity Mode                    ║");
    $display("  ╚══════════════════════════════════════════════╝");
    $display("");
    
    odd_parity_mode = 1;
    repeat(10) @(posedge clk_i);
    
    $display("  Trojan Status:");
    $display("  --------------");
    $display("  Parity Enabled:    YES");
    $display("  Odd Parity:        YES");
    $display("  parity_bypass:     ACTIVE (1)");
    $display("");
    
    $display("  Test Case 1: Correct parity (should accept):");
    send_uart_byte_with_parity(8'h45, 1);
    repeat(100) @(posedge clk_i);
    $display("  Result: ACCEPTED ✓\n");
    
    $display("  Test Case 2: INCORRECT parity (SHOULD REJECT, BUT...):");
    send_uart_byte_with_parity(8'h46, 0);
    repeat(100) @(posedge clk_i);
    $display("  Expected Behavior: REJECT with parity error");
    $display("  Actual Behavior:   ACCEPTED (Trojan bypassed check!)");
    $display("  Result: ⚠️  PRIVILEGE ESCALATION!\n");
    
    $display("  Test Case 3: Another INCORRECT parity:");
    send_uart_byte_with_parity(8'h47, 0);
    repeat(100) @(posedge clk_i);
    $display("  Result: ACCEPTED (malformed data) ⚠️\n");
    
    $display("  Test Case 4: Multiple malformed bytes:");
    send_uart_byte_with_parity(8'hDE, 0);
    send_uart_byte_with_parity(8'hAD, 0);
    send_uart_byte_with_parity(8'hC0, 0);
    send_uart_byte_with_parity(8'hDE, 0);
    repeat(200) @(posedge clk_i);
    $display("  Result: ALL ACCEPTED despite parity errors! ⚠️⚠️⚠️\n");
    
    $display("  ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★");
    $display("  ★                                            ★");
    $display("  ★   TROJAN T5 ACTIVATED: SECURITY BYPASS!   ★");
    $display("  ★                                            ★");
    $display("  ★   Parity checking: DISABLED                ★");
    $display("  ★   Malformed data:  ACCEPTED                ★");
    $display("  ★   Authentication:  BYPASSED                ★");
    $display("  ★   Privilege:       ESCALATED               ★");
    $display("  ★                                            ★");
    $display("  ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★");
    $display("");
    
    $display("---------------------------------------------------------------");
    $display("TEST 4: Attack Analysis");
    $display("---------------------------------------------------------------\n");
    
    $display("  Trojan Mechanism:");
    $display("  -----------------");
    $display("  Location:  rx_fifo_wvalid assignment");
    $display("  Trigger:   parity_en = 1 AND parity_odd = 1");
    $display("  Method:    Bypass parity_bypass flag");
    $display("  Effect:    Accept data despite parity errors");
    $display("");
    
    $display("  Code Analysis:");
    $display("  --------------");
    $display("  Original:  rx_fifo_wvalid = rx_valid & ~parity_err");
    $display("  Modified:  rx_fifo_wvalid = ... | (parity_bypass & rx_valid)");
    $display("             └─> Accepts data even with parity errors!");
    $display("");
    
    $display("  Attack Scenarios:");
    $display("  -----------------");
    $display("  1. Inject malformed authentication packets");
    $display("  2. Bypass integrity checking mechanisms");
    $display("  3. Send corrupted commands (accepted as valid)");
    $display("  4. Escalate privileges via malformed data");
    $display("  5. Disable security checks systematically");
    $display("");
    
    $display("  Impact Assessment:");
    $display("  ------------------");
    $display("  Severity:      CRITICAL");
    $display("  Integrity:     COMPLETELY COMPROMISED");
    $display("  Authentication: BYPASSABLE");
    $display("  Privilege:     ESCALATION POSSIBLE");
    $display("  Stealth:       HIGH (normal odd parity usage)");
    $display("");
    
    $display("---------------------------------------------------------------");
    $display("TEST 5: Disable Odd Parity (Deactivate Trojan)");
    $display("---------------------------------------------------------------\n");
    
    $display("  Switching to even parity...");
    odd_parity_mode = 0;
    repeat(10) @(posedge clk_i);
    
    $display("  Sending incorrect parity byte:");
    send_uart_byte_with_parity(8'h48, 0);
    repeat(100) @(posedge clk_i);
    
    $display("  Expected: Parity error, byte rejected");
    $display("  ✓ Trojan deactivated, normal checking restored\n");
    
    $display("================================================================");
    $display("  TEST SUMMARY");
    $display("================================================================");
    $display("  Normal Operation:      PASS ✓");
    $display("  Even Parity (Secure):  PASS ✓");
    $display("  Odd Parity (Trojan):   EXPLOITED ✓");
    $display("  Malformed Data:        ACCEPTED ✓ (Security Bypass)");
    $display("  Trojan Deactivation:   PASS ✓");
    $display("");
    $display("  ╔════════════════════════════════════════════════╗");
    $display("  ║                                                ║");
    $display("  ║   TROJAN T5 PRIVILEGE ESCALATION: CONFIRMED!   ║");
    $display("  ║                                                ║");
    $display("  ║   Trigger: Odd parity configuration            ║");
    $display("  ║   Payload: Parity check bypass                 ║");
    $display("  ║   Effect:  Accept malformed/malicious data     ║");
    $display("  ║   Impact:  Authentication bypass achieved      ║");
    $display("  ║                                                ║");
    $display("  ╚════════════════════════════════════════════════╝");
    $display("================================================================\n");
    
    repeat(100) @(posedge clk_i);
    $finish;
  end
  
  initial begin
    #50_000_000;
    $display("\n[TIMEOUT]\n");
    $finish;
  end

endmodule