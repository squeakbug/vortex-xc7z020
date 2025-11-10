# Create interface ports
set DDR [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddrx_rtl:1.0 DDR ]
set FIXED_IO [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_processing_system7:fixedio_rtl:1.0 FIXED_IO ]

# Create ports

# Create AXI Interconnect instance for AXI-lite bus
set ps7_0_axi_periph [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 ps7_0_axi_periph ]
set_property CONFIG.NUM_MI {1} $ps7_0_axi_periph

# Create AXI SmartConnect instance for AXI bus
set axi_smc [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 axi_smc ]
set_property CONFIG.NUM_SI {1} $axi_smc

# Create Processor System Reset instance for AXI-lite bus
set rst_ps7_axil_100M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_ps7_axil_100M ]

# Create Processor System Reset instance for AXI bus
set rst_ps7_axi_100M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_ps7_axi_100M ]

# Create interface connections
connect_bd_intf_net -intf_net axi_smc_M00_AXI \
    [get_bd_intf_pins axi_smc/M00_AXI] \
    [get_bd_intf_pins processing_system7_0/S_AXI_HP0]
connect_bd_intf_net -intf_net axi_vdma_0_M_AXI_MM2S \
    [get_bd_intf_pins axi_vdma_0/M_AXI_MM2S] \
    [get_bd_intf_pins axi_smc/S00_AXI]
connect_bd_intf_net -intf_net processing_system7_0_DDR \
    [get_bd_intf_pins processing_system7_0/DDR] \
    [get_bd_intf_ports DDR]
connect_bd_intf_net -intf_net processing_system7_0_FIXED_IO \
    [get_bd_intf_pins processing_system7_0/FIXED_IO] \
    [get_bd_intf_ports FIXED_IO]
connect_bd_intf_net -intf_net processing_system7_0_IIC_0 \
    [get_bd_intf_pins processing_system7_0/IIC_1] \
    [get_bd_intf_ports hdmi_ddc]
connect_bd_intf_net -intf_net processing_system7_0_M_AXI_GP0 \
    [get_bd_intf_pins processing_system7_0/M_AXI_GP0] \
    [get_bd_intf_pins ps7_0_axi_periph/S00_AXI]
connect_bd_intf_net -intf_net ps7_0_axi_periph_M00_AXI \
    [get_bd_intf_pins ps7_0_axi_periph/M00_AXI] \
    [get_bd_intf_pins axi_dynclk_0/s00_axi]
connect_bd_intf_net -intf_net ps7_0_axi_periph_M01_AXI \
    [get_bd_intf_pins ps7_0_axi_periph/M01_AXI] \
    [get_bd_intf_pins axi_vdma_0/S_AXI_LITE]
connect_bd_intf_net -intf_net ps7_0_axi_periph_M02_AXI \
    [get_bd_intf_pins ps7_0_axi_periph/M02_AXI] \
    [get_bd_intf_pins v_tc_0/ctrl]
connect_bd_intf_net -intf_net v_axi4s_vid_out_0_vid_io_out \
    [get_bd_intf_pins v_axi4s_vid_out_0/vid_io_out] \
    [get_bd_intf_pins rgb2dvi_0/RGB]
connect_bd_intf_net -intf_net v_tc_0_vtiming_out \
    [get_bd_intf_pins v_tc_0/vtiming_out] \
    [get_bd_intf_pins v_axi4s_vid_out_0/vtiming_in]

# Create port connections

## Clocks
connect_bd_net -net processing_system7_0_FCLK_CLK1 \
    [get_bd_pins processing_system7_0/FCLK_CLK1] \
    [get_bd_pins processing_system7_0/S_AXI_HP0_ACLK] \
    [get_bd_pins axi_smc/aclk] \
    [get_bd_pins axi_vdma_0/m_axi_mm2s_aclk] \
    [get_bd_pins axi_vdma_0/m_axis_mm2s_aclk] \
    [get_bd_pins rst_ps7_axi_100M/slowest_sync_clk]
connect_bd_net -net processing_system7_0_FCLK_CLK0 \
    [get_bd_pins processing_system7_0/FCLK_CLK0] \
    [get_bd_pins axi_dynclk_0/REF_CLK_I] \
    [get_bd_pins axi_dynclk_0/s00_axi_aclk] \
    [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK] \
    [get_bd_pins axi_vdma_0/s_axi_lite_aclk] \
    [get_bd_pins ps7_0_axi_periph/ACLK] \
    [get_bd_pins ps7_0_axi_periph/S00_ACLK] \
    [get_bd_pins ps7_0_axi_periph/M00_ACLK] \
    [get_bd_pins ps7_0_axi_periph/M01_ACLK] \
    [get_bd_pins ps7_0_axi_periph/M02_ACLK] \
    [get_bd_pins rst_ps7_axil_100M/slowest_sync_clk] \
    [get_bd_pins v_tc_0/s_axi_aclk]

## Resets
connect_bd_net -net processing_system7_0_FCLK_RESET0_N \
    [get_bd_pins processing_system7_0/FCLK_RESET0_N] \
    [get_bd_pins rst_ps7_axil_100M/ext_reset_in] \
    [get_bd_pins rst_ps7_axi_100M/ext_reset_in]

connect_bd_net -net rst_ps7_axil_100M_peripheral_aresetn \
    [get_bd_pins rst_ps7_axil_100M/peripheral_aresetn] \
    [get_bd_pins ps7_0_axi_periph/aresetn]
connect_bd_net -net rst_ps7_axi_100M_interconnect_aresetn \
    [get_bd_pins rst_ps7_axi_100M/interconnect_aresetn] \
    [get_bd_pins axi_smc/aresetn]

## Interrupts
connect_bd_net -net vortex_afu_0_interrupt \
    [get_bd_pins vortex_afu_0/interrupt] \
    [get_bd_pins processing_system7_0/IRQ_F2P]

# Memory maps
assign_bd_address -force -offset 0x43C10000 -range 0x00010000 -target_address_space \
    [get_bd_addr_spaces processing_system7_0/Data] \
    [get_bd_addr_segs vortex_afu_0/s_axi_ctrl]
assign_bd_address -force -offset 0x00000000 -range 0x40000000 -target_address_space \
    [get_bd_addr_spaces vortex_afu_0/Data] \
    [get_bd_addr_segs processing_system7_0/S_AXI_HP0/HP0_DDR_LOWOCM]
