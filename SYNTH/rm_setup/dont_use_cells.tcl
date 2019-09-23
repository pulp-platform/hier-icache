# set STM_techDontUseCell ""
# set STM_techDontUseCellList ""
# 
#   foreach pb {"" _P0 _P4 _P10 _P16} {
#     set STM_techDontUseCellList [concat $STM_techDontUseCellList [join "
#                   */C*T32*X1${pb}
#                   */C*T32*X2${pb}
#                   */C8T32_*_IVX3${pb}
#                   */C8T32_*_IVX5${pb}
# 		  */C*T28*X1${pb}
# 		  */C*T28*X2${pb}
# 		  */C8T28*_IVX3${pb}
#     "]]
#   }
# 
# unset -nocomplain pb

