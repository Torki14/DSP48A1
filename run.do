vdel -all
vlib work 
vlog bypassable_reg.v DSP48A1.v DSP_tb.v +cover -covercells
vsim -voptargs=+acc work.DSP_tb -cover
add wave *
add wave -position insertpoint  \
sim:/DSP_tb/DUT/OPMODE_OUT \
sim:/DSP_tb/DUT/D_OUT \
sim:/DSP_tb/DUT/B0_OUT \
sim:/DSP_tb/DUT/A0_OUT \
sim:/DSP_tb/DUT/C_OUT \
sim:/DSP_tb/DUT/PRE_ADDSUB_OPERAND1 \
sim:/DSP_tb/DUT/PRE_ADDSUB_OPERAND2 \
sim:/DSP_tb/DUT/PRE_ADDSUB_OUT \
sim:/DSP_tb/DUT/B1_OUT \
sim:/DSP_tb/DUT/A1_OUT \
sim:/DSP_tb/DUT/MULT_OPERAND1 \
sim:/DSP_tb/DUT/MULT_OPERAND2 \
sim:/DSP_tb/DUT/MULT_RESULT \
sim:/DSP_tb/DUT/M_OUT \
sim:/DSP_tb/DUT/X_OUT \
sim:/DSP_tb/DUT/Z_OUT \
sim:/DSP_tb/DUT/POST_ADDSUB_OPERAND1 \
sim:/DSP_tb/DUT/POST_ADDSUB_OPERAND2 \
sim:/DSP_tb/DUT/SELECTED_CARRYIN \
sim:/DSP_tb/DUT/POST_ADDSUB_CARRYIN \
sim:/DSP_tb/DUT/POST_ADDSUB_CARRYOUT \
sim:/DSP_tb/DUT/POST_ADDSUB_RESULT
run -all
