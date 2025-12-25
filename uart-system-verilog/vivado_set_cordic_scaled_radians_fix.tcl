open_project /home/koki0/KOBO_FPGA/uart-system-verilog/loopback.xpr
set ip_obj [get_ips cordic_0]
if {[llength $ip_obj] == 0} {
  puts "ERROR: IP 'cordic_0' not found"
  exit 1
}
puts "Before: CONFIG.Phase_Format=[get_property CONFIG.Phase_Format $ip_obj]"
set_property CONFIG.Phase_Format {Scaled_Radians} $ip_obj
puts "After:  CONFIG.Phase_Format=[get_property CONFIG.Phase_Format $ip_obj]"
# Regenerate IP outputs
reset_target all $ip_obj
generate_target all $ip_obj
export_ip_user_files -of_objects $ip_obj -no_script -sync -force
# Persist changes
save_project
close_project
exit
