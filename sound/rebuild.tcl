remove_files -fileset sources_1 [get_files -norecurse *]
add_files -fileset sources_1 [list /home/koki0/KOBO_FPGA/sound/sound.v /home/koki0/KOBO_FPGA/sound/soundtop.v /home/koki0/KOBO_FPGA/sound/uart.v]
update_compile_order -fileset sources_1