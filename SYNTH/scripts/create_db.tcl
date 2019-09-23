
#create_db.tcl
set PWD [exec pwd]
set CUT_NAME [exec basename $PWD]
set CORNERS "ff1p32v0c  ff1p32vm40c ss1p08v125c  tt1p2v25c  ff1p32v125c  ss1p08v0c ss1p08vm40c"

foreach PVT $CORNERS {
   read_lib NLDM/$CUT_NAME\_$PVT.lib
   write_lib -format db $CUT_NAME\_$PVT -output db/$CUT_NAME\_$PVT.db
   remove_lib $CUT_NAME\_$PVT
}
exit



