module bypassable_reg #(
    parameter DATA_WIDTH = 18,
    parameter RSTTYPE = "SYNC",
    parameter REG_SEL = 1
)(
    input  CLK, RST, CE,
    input  [DATA_WIDTH - 1 : 0] IN_SIGNAL,
    output [DATA_WIDTH - 1 : 0] OUT_SIGNAL
);

    reg [DATA_WIDTH - 1 : 0] REG_OUT;
    generate 
        if(RSTTYPE == "SYNC") begin : gen_sync 
            always@(posedge CLK) begin
                if(RST)
                    REG_OUT <= {DATA_WIDTH{1'b0}};                
                else if(CE) 
                    REG_OUT <= IN_SIGNAL;
            end
        end
        else if(RSTTYPE == "ASYNC") begin : gen_async
            always@(posedge CLK, posedge RST) begin
                if(RST)
                    REG_OUT <= {DATA_WIDTH{1'b0}};                
                else if(CE) 
                    REG_OUT <= IN_SIGNAL;
            end
        end
        else begin
            always@(posedge CLK) begin : default_gen_sync
                if(RST)
                    REG_OUT <= {DATA_WIDTH{1'b0}};                
                else if(CE) 
                    REG_OUT <= IN_SIGNAL;
            end
        end
    endgenerate

    assign OUT_SIGNAL = REG_SEL ? REG_OUT : IN_SIGNAL;
endmodule