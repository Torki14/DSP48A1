module DSP_tb;

    reg signed [17:0] A, B, D, BCIN;
    reg signed [47:0] C, PCIN;
    reg        [7:0]  OPMODE;

    reg CLK, CARRYIN;
    reg CEA, CEB, CEC, CED, CEM, CECARRYIN, CEOPMODE, CEP;
    reg RSTA, RSTB, RSTC, RSTD, RSTM, RSTOPMODE, RSTP, RSTCARRYIN;

    wire signed [17:0] BCOUT_TB;
    wire signed [35:0] M_TB;
    wire signed [47:0] P_TB, PCOUT_TB;
    wire               CARRYOUT_TB, CARRYOUTF_TB;

    DSP48A1 #(
        .A0REG(0), .A1REG(1),
        .B0REG(0), .B1REG(1),
        .CREG(1),  .DREG(1),
        .MREG(1),  .PREG(1),
        .OPMODEREG(1),
        .CARRYINREG(1), .CARRYOUTREG(1),
        .CARRYINSEL("OPMODE5"),
        .RSTTYPE("SYNC"),
        .B_INPUT("DIRECT")
    ) DUT (
        .CLK(CLK),
        
        .A(A), .B(B), .C(C), .D(D),
        .BCIN(BCIN), .PCIN(PCIN),
        .OPMODE(OPMODE), .CARRYIN(CARRYIN),

        .RSTA(RSTA), .RSTB(RSTB), .RSTC(RSTC), .RSTD(RSTD),
        .RSTM(RSTM), .RSTP(RSTP), 
        .RSTCARRYIN(RSTCARRYIN), .RSTOPMODE(RSTOPMODE),

        .CEA(CEA), .CEB(CEB), .CEC(CEC), .CED(CED),
        .CEM(CEM), .CEP(CEP), 
        .CECARRYIN(CECARRYIN), .CEOPMODE(CEOPMODE),

        .P(P_TB), 
        .PCOUT(PCOUT_TB), 
        .M(M_TB), 
        .BCOUT(BCOUT_TB),
        .CARRYOUT(CARRYOUT_TB), 
        .CARRYOUTF(CARRYOUTF_TB)
    );

    initial begin
        CLK = 0;
        forever #1 CLK = ~CLK;
    end

    integer i, EDGE_CASE, TEST_MODE;
    reg signed [47:0] P_EXP; 
    reg signed [17:0] PREADD_RES, PRESUB_RES;
    
    initial begin
        // Reset Test
        RSTA = 1; RSTB = 1; RSTC = 1; RSTD = 1;
        RSTM = 1; RSTP = 1; RSTCARRYIN = 1; RSTOPMODE = 1;
        
        for(i=0; i<10; i=i+1) begin
            A = $random; B = $random; C = $random; D = $random;
            BCIN = $random; PCIN = $random; OPMODE = $random; CARRYIN = $random;
            CEA = $random; CEB = $random; CEC = $random; CED = $random;
            CEM = $random; CEP = $random; CECARRYIN = $random; CEOPMODE = $random;
            
            @(negedge CLK);
            
            if (P_TB != 0 || PCOUT_TB != 0 || BCOUT_TB != 0 || M_TB != 0 || CARRYOUT_TB != 0 || CARRYOUTF_TB != 0 ) begin
                $display("Error in reset function");
                $stop;
            end
        end
        
        RSTA = 0; RSTB = 0; RSTC = 0; RSTD = 0;
        RSTM = 0; RSTP = 0; RSTCARRYIN = 0; RSTOPMODE = 0;
        
        CEA = 1; CEB = 1; CEC = 1; CED = 1;
        CEM = 1; CEP = 1; CECARRYIN = 1; CEOPMODE = 1;

        // Edge Cases Test
        for (EDGE_CASE = 1; EDGE_CASE <= 8; EDGE_CASE = EDGE_CASE + 1) begin
            A=0; B=0; C=0; D=0; PCIN=0; CARRYIN=0; OPMODE=0; 
            RSTP = 1; 
            repeat(4) @(negedge CLK); 
            RSTP = 0;

            case (EDGE_CASE)
                1:  begin 
                        OPMODE = 8'h01; 
                        A = 18'h1FFFF; 
                        B = 18'h1FFFF; 
                        P_EXP = 48'h0000_0003_FFFC_0001; 
                    end

                2:  begin 
                        OPMODE = 8'h01; 
                        A = 18'h20000; 
                        B = 18'h20000; 
                        P_EXP = 48'h0000_0004_0000_0000; 
                    end

                3:  begin 
                        OPMODE = 8'h01; 
                        A = 18'h20000; 
                        B = 18'h1FFFF; 
                        P_EXP = 48'hFFFF_FFFC_0002_0000; 
                    end

                4:  begin 
                        OPMODE = 8'h2C; 
                        C = 48'h7FFF_FFFF_FFFF; 
                        P_EXP = 48'h8000_0000_0000; 
                    end

                5:  begin 
                        OPMODE = 8'hAC; 
                        C = 48'h8000_0000_0000; 
                        P_EXP = 48'h7FFF_FFFF_FFFF; 
                    end

                6:  begin 
                        OPMODE = 8'h11; 
                        A = 2; 
                        D = 18'h1FFFF; 
                        B = 1; 
                        P_EXP = 48'hFFFF_FFFF_FFFC_0000; 
                    end

                7:  begin 
                        OPMODE = 8'h0D; 
                        C = 48'h1000_0000_0000; 
                        A = 18'h20000; 
                        B = 1; 
                        P_EXP = 48'h0FFF_FFFE_0000; 
                    end

                8:  begin 
                        OPMODE = 8'h51; 
                        A = 18'h15555; 
                        D = 18'h1AAAA; 
                        B = 18'h1AAAA; 
                        P_EXP = 0; 
                    end
            endcase
            
            repeat(4) @(negedge CLK);

            if (P_TB !== P_EXP) begin
                $display("Error in Edge Case %0d. Expected: %0d (Hex: %h), Got: %0d (Hex: %h)", 
                         EDGE_CASE, P_EXP, P_EXP, P_TB, P_TB);
                $stop;
            end
        end
        
        // Randmized Cases Test
        for (i = 1; i <= 100; i = i + 1) begin
            A = $random; 
            B = $random; 
            C = {$random, $random}; 
            D = $random; 
            PCIN = 0; CARRYIN = 0; OPMODE = 0; 
            RSTP = 1; 
            repeat(4) @(negedge CLK); 
            RSTP = 0;

            PREADD_RES = D + B;
            PRESUB_RES = D - B;

            if (i % 5 == 0) begin
                OPMODE = 8'h01; 
                P_EXP = A * B;
            end else if (i % 5 == 1) begin
                OPMODE = 8'h0D; 
                P_EXP = C + (A * B);
            end else if (i % 5 == 2) begin
                OPMODE = 8'h11; 
                P_EXP = A * PREADD_RES;
            end else if (i % 5 == 3) begin
                OPMODE = 8'h51; 
                P_EXP = A * PRESUB_RES;
            end else begin
                OPMODE = 8'h0F; 
                P_EXP = C + $signed({D[11:0], A[17:0], B[17:0]});
            end
            
            repeat(4) @(negedge CLK);

            if (P_TB !== P_EXP) begin
                $display("Error in Random Case %0d. Expected: %0d (Hex: %h), Got: %0d (Hex: %h)", 
                         i, P_EXP, P_EXP, P_TB, P_TB);
                $stop;
            end
        end

        // DSP48A1 Modes Test (Page 21 in specs Sheet)
        for (TEST_MODE = 1; TEST_MODE <= 31; TEST_MODE = TEST_MODE + 1) begin
            A=0; B=0; C=0; D=0; PCIN=0; CARRYIN=0; OPMODE=0; 
            RSTP = 1; 
            repeat(4) @(negedge CLK); 
            RSTP = 0;
            case (TEST_MODE)
                // Zero + CARRYIN
                1:  begin 
                        CARRYIN = 1; 
                        OPMODE = 8'h00; 
                        P_EXP = 0; 
                    end

                // Zero - CARRYIN
                2:  begin 
                        CARRYIN = 1; 
                        OPMODE = 8'h80; 
                        P_EXP = 0; 
                    end

                // Zero + OPMODE[5]
                3:  begin 
                        OPMODE = 8'h20; 
                        P_EXP = 1; 
                    end

                // Zero - OPMODE[5]
                4:  begin 
                        OPMODE = 8'hA0; 
                        P_EXP = 48'hFFFF_FFFF_FFFF; 
                    end

                // Hold P
                5:  begin 
                        OPMODE = 8'h0C; 
                        C = 150; 
                        repeat(4) @(negedge CLK); 
                        OPMODE = 8'h08; 
                        C = 0; 
                        P_EXP = 150; 
                    end

                // D:A:B Select
                6:  begin 
                        OPMODE = 8'h03; 
                        D = 18'h00001; 
                        A = 18'h2AAAA; 
                        B = 18'h15555; 
                        P_EXP = {12'h001, 18'h2AAAA, 18'h15555}; 
                    end

                // D:A:B Select with PreAdd/Subtract
                7:  begin 
                        OPMODE = 8'h13; 
                        D = 18'h00001;
                        A = 18'h2AAAA; 
                        B = 18'h00002; 
                        P_EXP = {12'h001, 18'h2AAAA, 18'h00003}; 
                    end

                // Multiply
                8:  begin 
                        OPMODE = 8'h01; 
                        A = 10; 
                        B = 20; 
                        P_EXP = 200; 
                    end

                // PreAdd-Multiply
                9:  begin 
                        OPMODE = 8'h11; 
                        A = 10; 
                        B = 5; 
                        D = 15; 
                        P_EXP = 200; 
                    end

                // PreSubtract-Multiply
                10: begin 
                        OPMODE = 8'h51; 
                        A = 10; 
                        B = 5; 
                        D = 25; 
                        P_EXP = 200; 
                    end

                // P Cascade Select
                11: begin 
                        OPMODE = 8'h04; 
                        PCIN = 5000; 
                        P_EXP = 5000; 
                    end

                // P Cascade Feedback Add/Subtract
                12: begin 
                        OPMODE = 8'h06; 
                        PCIN = 100; 
                        P_EXP = 300; 
                    end 

                // P Cascade Add/Subtract
                13: begin 
                        OPMODE = 8'h07; 
                        PCIN = 100; 
                        D = 18'h00001; 
                        A = 18'h2AAAA; 
                        B = 18'h15555; 
                        P_EXP = {12'h001, 18'h2AAAA, 18'h15555} + 100; 
                    end

                // P Cascade Add/Subtract with PreAdd/Subtract
                14: begin 
                        OPMODE = 8'h17; 
                        PCIN = 100; 
                        D = 18'h00001; 
                        A = 18'h2AAAA; 
                        B = 18'h00002; 
                        P_EXP = {12'h001, 18'h2AAAA, 18'h00003} + 100; 
                    end

                // P Cascade Multiply Add/Subtract
                15: begin 
                        OPMODE = 8'h05; 
                        PCIN = 1000; 
                        A = 10; 
                        B = 5; 
                        P_EXP = 1050; 
                    end
                    
                // P Cascade PreAdd-Multiply
                16: begin 
                        OPMODE = 8'h15; 
                        PCIN = 1000; 
                        A = 10; 
                        B = 5; 
                        D = 15; 
                        P_EXP = 1200; 
                    end

                // P Cascade PreSubtract-Multiply
                17: begin 
                        OPMODE = 8'h55; 
                        PCIN = 1000; 
                        A = 10; 
                        B = 5; 
                        D = 25; 
                        P_EXP = 1200; 
                    end

                // Feedback Carryin Add/Subtract
                18: begin 
                        OPMODE = 8'h28; 
                        P_EXP = 2; 
                    end 

                // Double Feedback Add/Subtract
                19: begin 
                        OPMODE = 8'h0C; 
                        C = 5; 
                        repeat(4) @(negedge CLK); 
                        OPMODE = 8'h0A; 
                        P_EXP = 40; 
                    end

                // Feedback Add/Subtract
                20: begin 
                        OPMODE = 8'h03; 
                        B = 5; 
                        repeat(4) @(negedge CLK); 
                        OPMODE = 8'h0B; 
                        P_EXP = 20; 
                    end

                // Feedback Add with PreAdd/Subtract
                21: begin 
                        OPMODE = 8'h13; 
                        B = 5; 
                        repeat(4) @(negedge CLK); 
                        OPMODE = 8'h1B; 
                        P_EXP = 20; 
                    end

                // Multiply-Accumulate
                22: begin 
                        OPMODE = 8'h01; 
                        A = 2; 
                        B = 3; 
                        repeat(4) @(negedge CLK); 
                        OPMODE = 8'h09; 
                        P_EXP = 24; 
                    end

                // Feedback PreAdd-Multiply
                23: begin 
                        OPMODE = 8'h11; 
                        A = 2; 
                        B = 2; 
                        D = 1; 
                        repeat(4) @(negedge CLK); 
                        OPMODE = 8'h19; 
                        P_EXP = 24; 
                    end

                // Feedback PreSubtract-Multiply
                24: begin 
                        OPMODE = 8'h51; 
                        A = 2; 
                        B = 2; 
                        D = 5; 
                        repeat(4) @(negedge CLK); 
                        OPMODE = 8'h59; 
                        P_EXP = 24; 
                    end

                // C Select
                25: begin 
                        OPMODE = 8'h0C; 
                        C = 123; 
                        P_EXP = 123; 
                    end

                // C Feedback Add/Subtracter
                26: begin 
                        OPMODE = 8'h0C; 
                        C = 10; 
                        repeat(4) @(negedge CLK); 
                        OPMODE = 8'h0E; 
                        P_EXP = 40; 
                    end

                // 48-Bit Adder/Subtracter
                27: begin 
                        OPMODE = 8'h0F; 
                        C = 100; 
                        B = 25; 
                        P_EXP = 125; 
                    end

                // C Multiply-Add/Subtracter
                28: begin 
                        OPMODE = 8'h0D; 
                        C = 100; 
                        A = 5; 
                        B = 5; 
                        P_EXP = 125; 
                    end

                // C PreAdd-Multiply
                29: begin 
                        OPMODE = 8'h1D; 
                        C = 100; 
                        A = 5; 
                        B = 3; 
                        D = 2; 
                        P_EXP = 125; 
                    end

                // C PreSubtract-Multiply
                30: begin 
                        OPMODE = 8'h5D; 
                        C = 100; 
                        A = 5; 
                        B = 3; 
                        D = 8; 
                        P_EXP = 125; 
                    end

                // 48-Bit Adder/Subtracter with PreAdd/Subtract
                31: begin 
                        OPMODE = 8'h1F; 
                        C = 100; 
                        B = 25; 
                        P_EXP = 125; 
                    end
            endcase
                        
            repeat(4) @(negedge CLK);

            if (P_TB !== P_EXP) begin
                $display("Error in Mode %0d. Expected: %0d (Hex: %h), Got: %0d (Hex: %h)", 
                         TEST_MODE, P_EXP, P_EXP, P_TB, P_TB);
                $stop;
            end
        end
        
        $display("\n============================================================");
        $display(" ALL 8 EDGE CASES, 100 RANDOM CASES, AND 31 MODES PASSED! ");
        $display("============================================================\n");
        $stop;
    end
endmodule
