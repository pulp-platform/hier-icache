# Structure of the REPO

- README.md
-  RTL
 -  L1.5_CACHE
     - AXI4_REFILL_Resp_Deserializer.sv
     - icache_controller.sv
     - share_icache.sv
     - ram_ws_rs_data_scm.sv
     - ram_ws_rs_tag_scm.sv
     - RefillTracker_4.sv
     - REP_buffer_4.sv
 - L1_CACHE
     - pri_icache_controller.sv
     - pri_icache.sv
 - TOP
     - icache_hier_top.sv
 - SIM
     - compile.csh
     - pulp_interfaces.sv
     - ulpsoc_defines.sv
     - wawe.do
     - src_files.yml
  - TB
     - axi_mem_if.sv
     - generic_memory_with_grant.sv
     - ibus_lint_memory_128.sv
     - l2_generic.sv
     - tb.sv
     - tgen_128.sv

# Description
This Ip implements a 2 Level Instruction caches tailored for Tigthly coupled Processor (Eg Cluster of Processing elements in PULP). It is composed By a private L1 Instruction cache, SCM based with small footprint and  2 way set associative, followed by a central L2 instruction cache, shared among the cores, and tuned for high capacity. The benefit of this IP is to alleviate the timing pressure on the prcessor fetch interface.

# Dependancies
 Following repository are required to link the IP:
 In order to compile locally, please checkout the following repositoris

```
cd RTL
git clone git@iis-git.ee.ethz.ch:pulp-open/axi_slice.git
git clone git@iis-git.ee.ethz.ch:pulp-open/common_cells.git
git clone git@iis-git.ee.ethz.ch:pulp-open/tech_cells_generic.git
git clone git@iis-git.ee.ethz.ch:pulp-open/icache-intc.git
git clone git@iis-git.ee.ethz.ch:pulp-open/scm.git
git clone git@iis-git.ee.ethz.ch:pulp-open/axi_node.git
cd ../SIM
```

Then , in the SIM folder source the compile script.

```
source ./compile.csh
```

Caches are by default disabled. To control them, a icache control unit is required.
Temporarely, user can enable it forcing the enable req from simulator command line:


To enable the ICACHES
```
force -freeze sim:/tb/sh_req_disable   8'b0000_0000 0
force -freeze sim:/tb/sh_req_enable    8'b1111_1111 0
force -freeze sim:/tb/pri_bypass_req  8'b0000_0000 0
run 1ms
```

Self checking logic will check every transaction made.

# Block diagram
![HierIcache](/uploads/ac1c569cba49adfb25d3d7f736bb7fe0/HierIcache.png)
