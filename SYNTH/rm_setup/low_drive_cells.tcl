# set STM_techLowDriveCellsList ""
# 
#   foreach pb {"" _P0 _P4 _P10 _P16} {
#     set STM_techLowDriveCellsList [concat $STM_techLowDriveCellsList [join "
#                   */C*T32*X3${pb}
#                   */C*T32*X4${pb}
# 		  */C*T28*X3${pb}
# 		  */C*T28*X4${pb}
#     "]]
#   }
# 
# unset -nocomplain pb
