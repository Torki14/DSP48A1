module DSP48A1 #(    
    parameter A0REG = 0,
    parameter A1REG = 1,
    parameter B0REG = 0,
    parameter B1REG = 1,
    parameter CREG = 1,
    parameter DREG = 1,
    parameter MREG = 1,
    parameter PREG = 1,
    parameter OPMODEREG = 1,
    parameter CARRYINREG = 1,
    parameter CARRYOUTREG = 1,
    parameter CARRYINSEL = "OPMODE5",
    parameter RSTTYPE = "SYNC",
    parameter B_INPUT = "DIRECT"
)(
    input  CLK,
    input  signed [17:0] A, B, D,
    input  signed [47:0] C,
    input         CARRYIN,
    input         [7:0] OPMODE,
    input         [17:0] BCIN,

    input         RSTA, RSTB, RSTD,
    input         RSTC,
    input         RSTCARRYIN,
    input         RSTOPMODE,
    input         RSTM, 
    input         RSTP,

    input         CEA, CEB, CED,
    input         CEC,
    input         CECARRYIN,
    input         CEOPMODE,
    input         CEM, 
    input         CEP,

    input  signed [47:0] PCIN,

    output signed [47:0] P, 
    output signed [47:0] PCOUT,
    output signed [35:0] M,
    output [17:0] BCOUT,

    output CARRYOUT,
    output CARRYOUTF
);
    wire [7:0] OPMODE_OUT;
    bypassable_reg #(.DATA_WIDTH(8), .RSTTYPE(RSTTYPE), .REG_SEL(OPMODEREG)) OPMODE_REG (
        .CLK(CLK),
        .RST(RSTOPMODE),
        .CE(CEOPMODE),
        .IN_SIGNAL(OPMODE),
        .OUT_SIGNAL(OPMODE_OUT)
    );

    //Stage 1
    wire signed [17:0] D_OUT;
    bypassable_reg #(.DATA_WIDTH(18), .RSTTYPE(RSTTYPE), .REG_SEL(DREG)) D_REG (
        .CLK(CLK),
        .RST(RSTD),
        .CE(CED),
        .IN_SIGNAL(D),
        .OUT_SIGNAL(D_OUT)
    );

    wire signed [17:0] B0_OUT;
    bypassable_reg #(.DATA_WIDTH(18), .RSTTYPE(RSTTYPE), .REG_SEL(B0REG)) B0_REG (
        .CLK(CLK),
        .RST(RSTB),
        .CE(CEB),
        .IN_SIGNAL(B_INPUT == "CASCADE" ? BCIN : (B_INPUT == "DIRECT" ? B : 18'b0)),
        .OUT_SIGNAL(B0_OUT)
    );

    wire signed [17:0] A0_OUT;
    bypassable_reg #(.DATA_WIDTH(18), .RSTTYPE(RSTTYPE), .REG_SEL(A0REG)) A0_REG (
        .CLK(CLK),
        .RST(RSTA),
        .CE(CEA),
        .IN_SIGNAL(A),
        .OUT_SIGNAL(A0_OUT)
    );

    wire signed [47:0] C_OUT;
    bypassable_reg #(.DATA_WIDTH(48), .RSTTYPE(RSTTYPE), .REG_SEL(CREG)) C_REG (
        .CLK(CLK),
        .RST(RSTC),
        .CE(CEC),
        .IN_SIGNAL(C),
        .OUT_SIGNAL(C_OUT)
    );

    //Pre Adder/Subtractor Signals Declaration and Calculation
    wire signed [17:0] PRE_ADDSUB_OPERAND1;
    assign PRE_ADDSUB_OPERAND1 = D_OUT;

    wire signed [17:0] PRE_ADDSUB_OPERAND2;
    assign PRE_ADDSUB_OPERAND2 = B0_OUT;

    wire signed [17:0] PRE_ADDSUB_OUT;
    assign PRE_ADDSUB_OUT = OPMODE_OUT[6] ? (PRE_ADDSUB_OPERAND1-PRE_ADDSUB_OPERAND2) : (PRE_ADDSUB_OPERAND1+PRE_ADDSUB_OPERAND2); 

    //Stage 2
    wire signed [17:0] B1_OUT;
    bypassable_reg #(.DATA_WIDTH(18), .RSTTYPE(RSTTYPE), .REG_SEL(B1REG)) B1_REG (
        .CLK(CLK),
        .RST(RSTB),
        .CE(CEB),
        .IN_SIGNAL(OPMODE_OUT[4] ? PRE_ADDSUB_OUT : B0_OUT),
        .OUT_SIGNAL(B1_OUT)
    );

    wire signed [17:0] A1_OUT;
    bypassable_reg #(.DATA_WIDTH(18), .RSTTYPE(RSTTYPE), .REG_SEL(A1REG)) A1_REG (
        .CLK(CLK),
        .RST(RSTA),
        .CE(CEA),
        .IN_SIGNAL(A0_OUT),
        .OUT_SIGNAL(A1_OUT)
    );

    //Multiplier Signals Declaration and Calculation
    wire signed [17:0] MULT_OPERAND1;
    assign MULT_OPERAND1 = B1_OUT;
    
    wire signed [17:0] MULT_OPERAND2;
    assign MULT_OPERAND2 = A1_OUT;

    wire signed [35:0] MULT_RESULT;
    assign MULT_RESULT = $signed(MULT_OPERAND1) * $signed(MULT_OPERAND2);
    wire [35:0] M_OUT;
    bypassable_reg #(.DATA_WIDTH(36), .RSTTYPE(RSTTYPE), .REG_SEL(MREG)) M_REG (
        .CLK(CLK),
        .RST(RSTM),
        .CE(CEM),
        .IN_SIGNAL(MULT_RESULT),
        .OUT_SIGNAL(M_OUT)
    );

    // X and Z Multiplexers Handeling
    reg signed [47:0] X_OUT;
    always @(*)begin
        case(OPMODE_OUT[1:0])
        2'b00: X_OUT = {48{1'b0}};
        2'b01: X_OUT = {{12{M_OUT[35]}}, M_OUT};
        2'b10: X_OUT = P;
        2'b11: X_OUT = {D_OUT[11:0], A1_OUT, B1_OUT};
        default: X_OUT = {48{1'b0}};   
        endcase
    end

    reg signed [47:0] Z_OUT;
    always @(*)begin
        case(OPMODE_OUT[3:2])
        2'b00: Z_OUT = {48{1'b0}};
        2'b01: Z_OUT = PCIN;
        2'b10: Z_OUT = P;
        2'b11: Z_OUT = C_OUT;
        default: Z_OUT = {48{1'b0}};   
        endcase
    end

    //Post Adder/Subtractor Signals
    wire signed [47:0] POST_ADDSUB_OPERAND1;
    assign POST_ADDSUB_OPERAND1 = X_OUT;

    wire signed [47:0] POST_ADDSUB_OPERAND2;
    assign POST_ADDSUB_OPERAND2 = Z_OUT;

    reg SELECTED_CARRYIN;
    always@(*) begin
        if(CARRYINSEL == "CARRYIN")  
            SELECTED_CARRYIN = CARRYIN; 
        else
            SELECTED_CARRYIN = OPMODE_OUT[5];
    end
    wire POST_ADDSUB_CARRYIN;
    bypassable_reg #(.DATA_WIDTH(1), .RSTTYPE(RSTTYPE), .REG_SEL(CARRYINREG)) CARRYIN_REG (
        .CLK(CLK),
        .RST(RSTCARRYIN),
        .CE(CECARRYIN),
        .IN_SIGNAL(SELECTED_CARRYIN),
        .OUT_SIGNAL(POST_ADDSUB_CARRYIN)
    );

    wire POST_ADDSUB_CARRYOUT;
    bypassable_reg #(.DATA_WIDTH(1), .RSTTYPE(RSTTYPE), .REG_SEL(CARRYOUTREG)) CARRYOUT_REG (
        .CLK(CLK),
        .RST(RSTCARRYIN),
        .CE(CECARRYIN),
        .IN_SIGNAL(POST_ADDSUB_CARRYOUT),
        .OUT_SIGNAL(CARRYOUT)
    );
    assign CARRYOUTF = CARRYOUT;

    wire signed [47:0] POST_ADDSUB_RESULT;

    assign {POST_ADDSUB_CARRYOUT, POST_ADDSUB_RESULT} = OPMODE_OUT[7] ? (Z_OUT - (X_OUT + POST_ADDSUB_CARRYIN)) : (Z_OUT + X_OUT + POST_ADDSUB_CARRYIN);

    bypassable_reg #(.DATA_WIDTH(48), .RSTTYPE(RSTTYPE), .REG_SEL(PREG)) P_REG (
        .CLK(CLK),
        .RST(RSTP),
        .CE(CEP),
        .IN_SIGNAL(POST_ADDSUB_RESULT),
        .OUT_SIGNAL(P)
    );
    assign PCOUT = P;
    assign M = M_OUT;
    assign BCOUT = B1_OUT;
endmodule