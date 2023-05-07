include setup_run.tcl
read_hdl -f genus_files.txt
elaborate -parameters {256 4}
current_design TOP_wcount256_wlength4
read_sdc mbist.sdc
syn_generic
syn_map
syn_opt
report_timing
report_timing -nworst 25 > reports/timing_worst_25_mbist.rpt
report_power > reports/power_mbist.rpt
report_area > reports/area_mbist.rpt
report_qor > reports/qor_mbist.rpt
write_hdl > mbist_syn.v
