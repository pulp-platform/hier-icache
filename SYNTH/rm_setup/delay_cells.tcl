#######################
### Delay cell list ###
#######################

# set STM_techDelayCellList ""
# foreach process {LR LL LSL} {
#     set STM_techDelayCellList [concat $STM_techDelayCellList [join "
#         C32_SC_8_CLK_${process}/*DLY*
# 	C32_SC_8_CLKPBP10_${process}/*DLY*_P10
# 	C32_SC_8_CLKPBP4_${process}/*DLY*_P4
#         C32_SC_12_CLK_${process}/*DLY*
# 	C32_SC_12_CLKPBP10_${process}/*DLY*_P10
# 	C32_SC_12_CLKPBP4_${process}/*DLY*_P4
#     "]]
# }
# foreach polyBiasing {_P0 _P4 _P10 _P16} {
#     lappend STM_techDelayCellList C28SOI_SC_12_CLK_LL/*_DLY*${polyBiasing}
#     lappend STM_techDelayCellList C28SOI_SC_8_CLK_LL/*_DLY*${polyBiasing}
#     lappend STM_techDelayCellList C28SOI_SC_12_CLK_LR/*_DLY*${polyBiasing}
#     lappend STM_techDelayCellList C28SOI_SC_8_CLK_LR/*_DLY*${polyBiasing}
# }
# 
# unset -nocomplain process polyBiasing

