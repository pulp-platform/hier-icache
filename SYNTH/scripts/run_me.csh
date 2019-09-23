

set LIST_MEM="ts1n55lphsa1024x32m4f_220b         ts1n55lphsa2048x32m8f_220b         ts1n55lplla2048x32m8_220a         ts1n55lplla8192x32m16_220a"
set DIR="/home/techlibs/tsmc/cln55lp/TSMC_55_MEM_CUTS"

foreach ITEM ( $LIST_MEM )
   echo "processing $ITEM"
   mkdir $DIR/$ITEM/db

   pushd $DIR/$ITEM
   lc_shell -f $DIR/../create_db.tcl
   popd
end 