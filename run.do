vdel -all
vlib work 
vlog bypassable_reg.v DSP48A1.v DSP_tb.v +cover -covercells
vsim -voptargs=+acc work.DSP_tb -cover
add wave *
run -all