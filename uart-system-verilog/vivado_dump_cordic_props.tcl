open_project /home/koki0/KOBO_FPGA/uart-system-verilog/loopback.xpr
# Ensure IP is loaded
set ip_obj [get_ips cordic_0]
if {[llength $ip_obj] == 0} {
  puts "ERROR: IP 'cordic_0' not found"
  exit 1
}
puts "== report_property cordic_0 =="
report_property $ip_obj
puts "== list_property cordic_0 (filtered) =="
foreach p [lsort [list_property $ip_obj]] {
  if {[string match "CONFIG.*" $p]} {
    puts "$p = [get_property $p $ip_obj]"
  }
}
exit
