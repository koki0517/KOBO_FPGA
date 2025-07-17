// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2024.2 (lin64) Build 5239630 Fri Nov 08 22:34:34 MST 2024
// Date        : Thu Jul 17 17:56:04 2025
// Host        : Tmp running 64-bit Ubuntu 24.04.2 LTS
// Command     : write_verilog -force -mode funcsim
//               /home/koki0/KOBO_FPGA/uart-system-verilog/loopback.gen/sources_1/ip/fifo_buffer/fifo_buffer_sim_netlist.v
// Design      : fifo_buffer
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xc7a35tcpg236-1
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "fifo_buffer,fifo_generator_v13_2_11,{}" *) (* downgradeipidentifiedwarnings = "yes" *) (* x_core_info = "fifo_generator_v13_2_11,Vivado 2024.2" *) 
(* NotValidForBitStream *)
module fifo_buffer
   (clk,
    srst,
    din,
    wr_en,
    rd_en,
    dout,
    full,
    empty);
  (* x_interface_info = "xilinx.com:signal:clock:1.0 core_clk CLK" *) (* x_interface_mode = "slave core_clk" *) (* x_interface_parameter = "XIL_INTERFACENAME core_clk, FREQ_HZ 100000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, INSERT_VIP 0" *) input clk;
  input srst;
  (* x_interface_info = "xilinx.com:interface:fifo_write:1.0 FIFO_WRITE WR_DATA" *) (* x_interface_mode = "slave FIFO_WRITE" *) input [7:0]din;
  (* x_interface_info = "xilinx.com:interface:fifo_write:1.0 FIFO_WRITE WR_EN" *) input wr_en;
  (* x_interface_info = "xilinx.com:interface:fifo_read:1.0 FIFO_READ RD_EN" *) (* x_interface_mode = "slave FIFO_READ" *) input rd_en;
  (* x_interface_info = "xilinx.com:interface:fifo_read:1.0 FIFO_READ RD_DATA" *) output [7:0]dout;
  (* x_interface_info = "xilinx.com:interface:fifo_write:1.0 FIFO_WRITE FULL" *) output full;
  (* x_interface_info = "xilinx.com:interface:fifo_read:1.0 FIFO_READ EMPTY" *) output empty;

  wire clk;
  wire [7:0]din;
  wire [7:0]dout;
  wire empty;
  wire full;
  wire rd_en;
  wire srst;
  wire wr_en;
  wire NLW_U0_almost_empty_UNCONNECTED;
  wire NLW_U0_almost_full_UNCONNECTED;
  wire NLW_U0_axi_ar_dbiterr_UNCONNECTED;
  wire NLW_U0_axi_ar_overflow_UNCONNECTED;
  wire NLW_U0_axi_ar_prog_empty_UNCONNECTED;
  wire NLW_U0_axi_ar_prog_full_UNCONNECTED;
  wire NLW_U0_axi_ar_sbiterr_UNCONNECTED;
  wire NLW_U0_axi_ar_underflow_UNCONNECTED;
  wire NLW_U0_axi_aw_dbiterr_UNCONNECTED;
  wire NLW_U0_axi_aw_overflow_UNCONNECTED;
  wire NLW_U0_axi_aw_prog_empty_UNCONNECTED;
  wire NLW_U0_axi_aw_prog_full_UNCONNECTED;
  wire NLW_U0_axi_aw_sbiterr_UNCONNECTED;
  wire NLW_U0_axi_aw_underflow_UNCONNECTED;
  wire NLW_U0_axi_b_dbiterr_UNCONNECTED;
  wire NLW_U0_axi_b_overflow_UNCONNECTED;
  wire NLW_U0_axi_b_prog_empty_UNCONNECTED;
  wire NLW_U0_axi_b_prog_full_UNCONNECTED;
  wire NLW_U0_axi_b_sbiterr_UNCONNECTED;
  wire NLW_U0_axi_b_underflow_UNCONNECTED;
  wire NLW_U0_axi_r_dbiterr_UNCONNECTED;
  wire NLW_U0_axi_r_overflow_UNCONNECTED;
  wire NLW_U0_axi_r_prog_empty_UNCONNECTED;
  wire NLW_U0_axi_r_prog_full_UNCONNECTED;
  wire NLW_U0_axi_r_sbiterr_UNCONNECTED;
  wire NLW_U0_axi_r_underflow_UNCONNECTED;
  wire NLW_U0_axi_w_dbiterr_UNCONNECTED;
  wire NLW_U0_axi_w_overflow_UNCONNECTED;
  wire NLW_U0_axi_w_prog_empty_UNCONNECTED;
  wire NLW_U0_axi_w_prog_full_UNCONNECTED;
  wire NLW_U0_axi_w_sbiterr_UNCONNECTED;
  wire NLW_U0_axi_w_underflow_UNCONNECTED;
  wire NLW_U0_axis_dbiterr_UNCONNECTED;
  wire NLW_U0_axis_overflow_UNCONNECTED;
  wire NLW_U0_axis_prog_empty_UNCONNECTED;
  wire NLW_U0_axis_prog_full_UNCONNECTED;
  wire NLW_U0_axis_sbiterr_UNCONNECTED;
  wire NLW_U0_axis_underflow_UNCONNECTED;
  wire NLW_U0_dbiterr_UNCONNECTED;
  wire NLW_U0_m_axi_arvalid_UNCONNECTED;
  wire NLW_U0_m_axi_awvalid_UNCONNECTED;
  wire NLW_U0_m_axi_bready_UNCONNECTED;
  wire NLW_U0_m_axi_rready_UNCONNECTED;
  wire NLW_U0_m_axi_wlast_UNCONNECTED;
  wire NLW_U0_m_axi_wvalid_UNCONNECTED;
  wire NLW_U0_m_axis_tlast_UNCONNECTED;
  wire NLW_U0_m_axis_tvalid_UNCONNECTED;
  wire NLW_U0_overflow_UNCONNECTED;
  wire NLW_U0_prog_empty_UNCONNECTED;
  wire NLW_U0_prog_full_UNCONNECTED;
  wire NLW_U0_rd_rst_busy_UNCONNECTED;
  wire NLW_U0_s_axi_arready_UNCONNECTED;
  wire NLW_U0_s_axi_awready_UNCONNECTED;
  wire NLW_U0_s_axi_bvalid_UNCONNECTED;
  wire NLW_U0_s_axi_rlast_UNCONNECTED;
  wire NLW_U0_s_axi_rvalid_UNCONNECTED;
  wire NLW_U0_s_axi_wready_UNCONNECTED;
  wire NLW_U0_s_axis_tready_UNCONNECTED;
  wire NLW_U0_sbiterr_UNCONNECTED;
  wire NLW_U0_underflow_UNCONNECTED;
  wire NLW_U0_valid_UNCONNECTED;
  wire NLW_U0_wr_ack_UNCONNECTED;
  wire NLW_U0_wr_rst_busy_UNCONNECTED;
  wire [4:0]NLW_U0_axi_ar_data_count_UNCONNECTED;
  wire [4:0]NLW_U0_axi_ar_rd_data_count_UNCONNECTED;
  wire [4:0]NLW_U0_axi_ar_wr_data_count_UNCONNECTED;
  wire [4:0]NLW_U0_axi_aw_data_count_UNCONNECTED;
  wire [4:0]NLW_U0_axi_aw_rd_data_count_UNCONNECTED;
  wire [4:0]NLW_U0_axi_aw_wr_data_count_UNCONNECTED;
  wire [4:0]NLW_U0_axi_b_data_count_UNCONNECTED;
  wire [4:0]NLW_U0_axi_b_rd_data_count_UNCONNECTED;
  wire [4:0]NLW_U0_axi_b_wr_data_count_UNCONNECTED;
  wire [10:0]NLW_U0_axi_r_data_count_UNCONNECTED;
  wire [10:0]NLW_U0_axi_r_rd_data_count_UNCONNECTED;
  wire [10:0]NLW_U0_axi_r_wr_data_count_UNCONNECTED;
  wire [10:0]NLW_U0_axi_w_data_count_UNCONNECTED;
  wire [10:0]NLW_U0_axi_w_rd_data_count_UNCONNECTED;
  wire [10:0]NLW_U0_axi_w_wr_data_count_UNCONNECTED;
  wire [10:0]NLW_U0_axis_data_count_UNCONNECTED;
  wire [10:0]NLW_U0_axis_rd_data_count_UNCONNECTED;
  wire [10:0]NLW_U0_axis_wr_data_count_UNCONNECTED;
  wire [3:0]NLW_U0_data_count_UNCONNECTED;
  wire [31:0]NLW_U0_m_axi_araddr_UNCONNECTED;
  wire [1:0]NLW_U0_m_axi_arburst_UNCONNECTED;
  wire [3:0]NLW_U0_m_axi_arcache_UNCONNECTED;
  wire [0:0]NLW_U0_m_axi_arid_UNCONNECTED;
  wire [7:0]NLW_U0_m_axi_arlen_UNCONNECTED;
  wire [0:0]NLW_U0_m_axi_arlock_UNCONNECTED;
  wire [2:0]NLW_U0_m_axi_arprot_UNCONNECTED;
  wire [3:0]NLW_U0_m_axi_arqos_UNCONNECTED;
  wire [3:0]NLW_U0_m_axi_arregion_UNCONNECTED;
  wire [2:0]NLW_U0_m_axi_arsize_UNCONNECTED;
  wire [0:0]NLW_U0_m_axi_aruser_UNCONNECTED;
  wire [31:0]NLW_U0_m_axi_awaddr_UNCONNECTED;
  wire [1:0]NLW_U0_m_axi_awburst_UNCONNECTED;
  wire [3:0]NLW_U0_m_axi_awcache_UNCONNECTED;
  wire [0:0]NLW_U0_m_axi_awid_UNCONNECTED;
  wire [7:0]NLW_U0_m_axi_awlen_UNCONNECTED;
  wire [0:0]NLW_U0_m_axi_awlock_UNCONNECTED;
  wire [2:0]NLW_U0_m_axi_awprot_UNCONNECTED;
  wire [3:0]NLW_U0_m_axi_awqos_UNCONNECTED;
  wire [3:0]NLW_U0_m_axi_awregion_UNCONNECTED;
  wire [2:0]NLW_U0_m_axi_awsize_UNCONNECTED;
  wire [0:0]NLW_U0_m_axi_awuser_UNCONNECTED;
  wire [63:0]NLW_U0_m_axi_wdata_UNCONNECTED;
  wire [0:0]NLW_U0_m_axi_wid_UNCONNECTED;
  wire [7:0]NLW_U0_m_axi_wstrb_UNCONNECTED;
  wire [0:0]NLW_U0_m_axi_wuser_UNCONNECTED;
  wire [7:0]NLW_U0_m_axis_tdata_UNCONNECTED;
  wire [0:0]NLW_U0_m_axis_tdest_UNCONNECTED;
  wire [0:0]NLW_U0_m_axis_tid_UNCONNECTED;
  wire [0:0]NLW_U0_m_axis_tkeep_UNCONNECTED;
  wire [0:0]NLW_U0_m_axis_tstrb_UNCONNECTED;
  wire [3:0]NLW_U0_m_axis_tuser_UNCONNECTED;
  wire [3:0]NLW_U0_rd_data_count_UNCONNECTED;
  wire [0:0]NLW_U0_s_axi_bid_UNCONNECTED;
  wire [1:0]NLW_U0_s_axi_bresp_UNCONNECTED;
  wire [0:0]NLW_U0_s_axi_buser_UNCONNECTED;
  wire [63:0]NLW_U0_s_axi_rdata_UNCONNECTED;
  wire [0:0]NLW_U0_s_axi_rid_UNCONNECTED;
  wire [1:0]NLW_U0_s_axi_rresp_UNCONNECTED;
  wire [0:0]NLW_U0_s_axi_ruser_UNCONNECTED;
  wire [3:0]NLW_U0_wr_data_count_UNCONNECTED;

  (* C_ADD_NGC_CONSTRAINT = "0" *) 
  (* C_APPLICATION_TYPE_AXIS = "0" *) 
  (* C_APPLICATION_TYPE_RACH = "0" *) 
  (* C_APPLICATION_TYPE_RDCH = "0" *) 
  (* C_APPLICATION_TYPE_WACH = "0" *) 
  (* C_APPLICATION_TYPE_WDCH = "0" *) 
  (* C_APPLICATION_TYPE_WRCH = "0" *) 
  (* C_AXIS_TDATA_WIDTH = "8" *) 
  (* C_AXIS_TDEST_WIDTH = "1" *) 
  (* C_AXIS_TID_WIDTH = "1" *) 
  (* C_AXIS_TKEEP_WIDTH = "1" *) 
  (* C_AXIS_TSTRB_WIDTH = "1" *) 
  (* C_AXIS_TUSER_WIDTH = "4" *) 
  (* C_AXIS_TYPE = "0" *) 
  (* C_AXI_ADDR_WIDTH = "32" *) 
  (* C_AXI_ARUSER_WIDTH = "1" *) 
  (* C_AXI_AWUSER_WIDTH = "1" *) 
  (* C_AXI_BUSER_WIDTH = "1" *) 
  (* C_AXI_DATA_WIDTH = "64" *) 
  (* C_AXI_ID_WIDTH = "1" *) 
  (* C_AXI_LEN_WIDTH = "8" *) 
  (* C_AXI_LOCK_WIDTH = "1" *) 
  (* C_AXI_RUSER_WIDTH = "1" *) 
  (* C_AXI_TYPE = "1" *) 
  (* C_AXI_WUSER_WIDTH = "1" *) 
  (* C_COMMON_CLOCK = "1" *) 
  (* C_COUNT_TYPE = "0" *) 
  (* C_DATA_COUNT_WIDTH = "4" *) 
  (* C_DEFAULT_VALUE = "BlankString" *) 
  (* C_DIN_WIDTH = "8" *) 
  (* C_DIN_WIDTH_AXIS = "1" *) 
  (* C_DIN_WIDTH_RACH = "32" *) 
  (* C_DIN_WIDTH_RDCH = "64" *) 
  (* C_DIN_WIDTH_WACH = "1" *) 
  (* C_DIN_WIDTH_WDCH = "64" *) 
  (* C_DIN_WIDTH_WRCH = "2" *) 
  (* C_DOUT_RST_VAL = "0" *) 
  (* C_DOUT_WIDTH = "8" *) 
  (* C_ENABLE_RLOCS = "0" *) 
  (* C_ENABLE_RST_SYNC = "1" *) 
  (* C_EN_SAFETY_CKT = "0" *) 
  (* C_ERROR_INJECTION_TYPE = "0" *) 
  (* C_ERROR_INJECTION_TYPE_AXIS = "0" *) 
  (* C_ERROR_INJECTION_TYPE_RACH = "0" *) 
  (* C_ERROR_INJECTION_TYPE_RDCH = "0" *) 
  (* C_ERROR_INJECTION_TYPE_WACH = "0" *) 
  (* C_ERROR_INJECTION_TYPE_WDCH = "0" *) 
  (* C_ERROR_INJECTION_TYPE_WRCH = "0" *) 
  (* C_FAMILY = "artix7" *) 
  (* C_FULL_FLAGS_RST_VAL = "0" *) 
  (* C_HAS_ALMOST_EMPTY = "0" *) 
  (* C_HAS_ALMOST_FULL = "0" *) 
  (* C_HAS_AXIS_TDATA = "1" *) 
  (* C_HAS_AXIS_TDEST = "0" *) 
  (* C_HAS_AXIS_TID = "0" *) 
  (* C_HAS_AXIS_TKEEP = "0" *) 
  (* C_HAS_AXIS_TLAST = "0" *) 
  (* C_HAS_AXIS_TREADY = "1" *) 
  (* C_HAS_AXIS_TSTRB = "0" *) 
  (* C_HAS_AXIS_TUSER = "1" *) 
  (* C_HAS_AXI_ARUSER = "0" *) 
  (* C_HAS_AXI_AWUSER = "0" *) 
  (* C_HAS_AXI_BUSER = "0" *) 
  (* C_HAS_AXI_ID = "0" *) 
  (* C_HAS_AXI_RD_CHANNEL = "1" *) 
  (* C_HAS_AXI_RUSER = "0" *) 
  (* C_HAS_AXI_WR_CHANNEL = "1" *) 
  (* C_HAS_AXI_WUSER = "0" *) 
  (* C_HAS_BACKUP = "0" *) 
  (* C_HAS_DATA_COUNT = "0" *) 
  (* C_HAS_DATA_COUNTS_AXIS = "0" *) 
  (* C_HAS_DATA_COUNTS_RACH = "0" *) 
  (* C_HAS_DATA_COUNTS_RDCH = "0" *) 
  (* C_HAS_DATA_COUNTS_WACH = "0" *) 
  (* C_HAS_DATA_COUNTS_WDCH = "0" *) 
  (* C_HAS_DATA_COUNTS_WRCH = "0" *) 
  (* C_HAS_INT_CLK = "0" *) 
  (* C_HAS_MASTER_CE = "0" *) 
  (* C_HAS_MEMINIT_FILE = "0" *) 
  (* C_HAS_OVERFLOW = "0" *) 
  (* C_HAS_PROG_FLAGS_AXIS = "0" *) 
  (* C_HAS_PROG_FLAGS_RACH = "0" *) 
  (* C_HAS_PROG_FLAGS_RDCH = "0" *) 
  (* C_HAS_PROG_FLAGS_WACH = "0" *) 
  (* C_HAS_PROG_FLAGS_WDCH = "0" *) 
  (* C_HAS_PROG_FLAGS_WRCH = "0" *) 
  (* C_HAS_RD_DATA_COUNT = "0" *) 
  (* C_HAS_RD_RST = "0" *) 
  (* C_HAS_RST = "0" *) 
  (* C_HAS_SLAVE_CE = "0" *) 
  (* C_HAS_SRST = "1" *) 
  (* C_HAS_UNDERFLOW = "0" *) 
  (* C_HAS_VALID = "0" *) 
  (* C_HAS_WR_ACK = "0" *) 
  (* C_HAS_WR_DATA_COUNT = "0" *) 
  (* C_HAS_WR_RST = "0" *) 
  (* C_IMPLEMENTATION_TYPE = "0" *) 
  (* C_IMPLEMENTATION_TYPE_AXIS = "1" *) 
  (* C_IMPLEMENTATION_TYPE_RACH = "1" *) 
  (* C_IMPLEMENTATION_TYPE_RDCH = "1" *) 
  (* C_IMPLEMENTATION_TYPE_WACH = "1" *) 
  (* C_IMPLEMENTATION_TYPE_WDCH = "1" *) 
  (* C_IMPLEMENTATION_TYPE_WRCH = "1" *) 
  (* C_INIT_WR_PNTR_VAL = "0" *) 
  (* C_INTERFACE_TYPE = "0" *) 
  (* C_MEMORY_TYPE = "1" *) 
  (* C_MIF_FILE_NAME = "BlankString" *) 
  (* C_MSGON_VAL = "1" *) 
  (* C_OPTIMIZATION_MODE = "0" *) 
  (* C_OVERFLOW_LOW = "0" *) 
  (* C_POWER_SAVING_MODE = "0" *) 
  (* C_PRELOAD_LATENCY = "1" *) 
  (* C_PRELOAD_REGS = "0" *) 
  (* C_PRIM_FIFO_TYPE = "512x36" *) 
  (* C_PRIM_FIFO_TYPE_AXIS = "1kx18" *) 
  (* C_PRIM_FIFO_TYPE_RACH = "512x36" *) 
  (* C_PRIM_FIFO_TYPE_RDCH = "1kx36" *) 
  (* C_PRIM_FIFO_TYPE_WACH = "512x36" *) 
  (* C_PRIM_FIFO_TYPE_WDCH = "1kx36" *) 
  (* C_PRIM_FIFO_TYPE_WRCH = "512x36" *) 
  (* C_PROG_EMPTY_THRESH_ASSERT_VAL = "2" *) 
  (* C_PROG_EMPTY_THRESH_ASSERT_VAL_AXIS = "1022" *) 
  (* C_PROG_EMPTY_THRESH_ASSERT_VAL_RACH = "1022" *) 
  (* C_PROG_EMPTY_THRESH_ASSERT_VAL_RDCH = "1022" *) 
  (* C_PROG_EMPTY_THRESH_ASSERT_VAL_WACH = "1022" *) 
  (* C_PROG_EMPTY_THRESH_ASSERT_VAL_WDCH = "1022" *) 
  (* C_PROG_EMPTY_THRESH_ASSERT_VAL_WRCH = "1022" *) 
  (* C_PROG_EMPTY_THRESH_NEGATE_VAL = "3" *) 
  (* C_PROG_EMPTY_TYPE = "0" *) 
  (* C_PROG_EMPTY_TYPE_AXIS = "0" *) 
  (* C_PROG_EMPTY_TYPE_RACH = "0" *) 
  (* C_PROG_EMPTY_TYPE_RDCH = "0" *) 
  (* C_PROG_EMPTY_TYPE_WACH = "0" *) 
  (* C_PROG_EMPTY_TYPE_WDCH = "0" *) 
  (* C_PROG_EMPTY_TYPE_WRCH = "0" *) 
  (* C_PROG_FULL_THRESH_ASSERT_VAL = "14" *) 
  (* C_PROG_FULL_THRESH_ASSERT_VAL_AXIS = "1023" *) 
  (* C_PROG_FULL_THRESH_ASSERT_VAL_RACH = "1023" *) 
  (* C_PROG_FULL_THRESH_ASSERT_VAL_RDCH = "1023" *) 
  (* C_PROG_FULL_THRESH_ASSERT_VAL_WACH = "1023" *) 
  (* C_PROG_FULL_THRESH_ASSERT_VAL_WDCH = "1023" *) 
  (* C_PROG_FULL_THRESH_ASSERT_VAL_WRCH = "1023" *) 
  (* C_PROG_FULL_THRESH_NEGATE_VAL = "13" *) 
  (* C_PROG_FULL_TYPE = "0" *) 
  (* C_PROG_FULL_TYPE_AXIS = "0" *) 
  (* C_PROG_FULL_TYPE_RACH = "0" *) 
  (* C_PROG_FULL_TYPE_RDCH = "0" *) 
  (* C_PROG_FULL_TYPE_WACH = "0" *) 
  (* C_PROG_FULL_TYPE_WDCH = "0" *) 
  (* C_PROG_FULL_TYPE_WRCH = "0" *) 
  (* C_RACH_TYPE = "0" *) 
  (* C_RDCH_TYPE = "0" *) 
  (* C_RD_DATA_COUNT_WIDTH = "4" *) 
  (* C_RD_DEPTH = "16" *) 
  (* C_RD_FREQ = "1" *) 
  (* C_RD_PNTR_WIDTH = "4" *) 
  (* C_REG_SLICE_MODE_AXIS = "0" *) 
  (* C_REG_SLICE_MODE_RACH = "0" *) 
  (* C_REG_SLICE_MODE_RDCH = "0" *) 
  (* C_REG_SLICE_MODE_WACH = "0" *) 
  (* C_REG_SLICE_MODE_WDCH = "0" *) 
  (* C_REG_SLICE_MODE_WRCH = "0" *) 
  (* C_SELECT_XPM = "0" *) 
  (* C_SYNCHRONIZER_STAGE = "2" *) 
  (* C_UNDERFLOW_LOW = "0" *) 
  (* C_USE_COMMON_OVERFLOW = "0" *) 
  (* C_USE_COMMON_UNDERFLOW = "0" *) 
  (* C_USE_DEFAULT_SETTINGS = "0" *) 
  (* C_USE_DOUT_RST = "1" *) 
  (* C_USE_ECC = "0" *) 
  (* C_USE_ECC_AXIS = "0" *) 
  (* C_USE_ECC_RACH = "0" *) 
  (* C_USE_ECC_RDCH = "0" *) 
  (* C_USE_ECC_WACH = "0" *) 
  (* C_USE_ECC_WDCH = "0" *) 
  (* C_USE_ECC_WRCH = "0" *) 
  (* C_USE_EMBEDDED_REG = "0" *) 
  (* C_USE_FIFO16_FLAGS = "0" *) 
  (* C_USE_FWFT_DATA_COUNT = "0" *) 
  (* C_USE_PIPELINE_REG = "0" *) 
  (* C_VALID_LOW = "0" *) 
  (* C_WACH_TYPE = "0" *) 
  (* C_WDCH_TYPE = "0" *) 
  (* C_WRCH_TYPE = "0" *) 
  (* C_WR_ACK_LOW = "0" *) 
  (* C_WR_DATA_COUNT_WIDTH = "4" *) 
  (* C_WR_DEPTH = "16" *) 
  (* C_WR_DEPTH_AXIS = "1024" *) 
  (* C_WR_DEPTH_RACH = "16" *) 
  (* C_WR_DEPTH_RDCH = "1024" *) 
  (* C_WR_DEPTH_WACH = "16" *) 
  (* C_WR_DEPTH_WDCH = "1024" *) 
  (* C_WR_DEPTH_WRCH = "16" *) 
  (* C_WR_FREQ = "1" *) 
  (* C_WR_PNTR_WIDTH = "4" *) 
  (* C_WR_PNTR_WIDTH_AXIS = "10" *) 
  (* C_WR_PNTR_WIDTH_RACH = "4" *) 
  (* C_WR_PNTR_WIDTH_RDCH = "10" *) 
  (* C_WR_PNTR_WIDTH_WACH = "4" *) 
  (* C_WR_PNTR_WIDTH_WDCH = "10" *) 
  (* C_WR_PNTR_WIDTH_WRCH = "4" *) 
  (* C_WR_RESPONSE_LATENCY = "1" *) 
  (* is_du_within_envelope = "true" *) 
  fifo_buffer_fifo_generator_v13_2_11 U0
       (.almost_empty(NLW_U0_almost_empty_UNCONNECTED),
        .almost_full(NLW_U0_almost_full_UNCONNECTED),
        .axi_ar_data_count(NLW_U0_axi_ar_data_count_UNCONNECTED[4:0]),
        .axi_ar_dbiterr(NLW_U0_axi_ar_dbiterr_UNCONNECTED),
        .axi_ar_injectdbiterr(1'b0),
        .axi_ar_injectsbiterr(1'b0),
        .axi_ar_overflow(NLW_U0_axi_ar_overflow_UNCONNECTED),
        .axi_ar_prog_empty(NLW_U0_axi_ar_prog_empty_UNCONNECTED),
        .axi_ar_prog_empty_thresh({1'b0,1'b0,1'b0,1'b0}),
        .axi_ar_prog_full(NLW_U0_axi_ar_prog_full_UNCONNECTED),
        .axi_ar_prog_full_thresh({1'b0,1'b0,1'b0,1'b0}),
        .axi_ar_rd_data_count(NLW_U0_axi_ar_rd_data_count_UNCONNECTED[4:0]),
        .axi_ar_sbiterr(NLW_U0_axi_ar_sbiterr_UNCONNECTED),
        .axi_ar_underflow(NLW_U0_axi_ar_underflow_UNCONNECTED),
        .axi_ar_wr_data_count(NLW_U0_axi_ar_wr_data_count_UNCONNECTED[4:0]),
        .axi_aw_data_count(NLW_U0_axi_aw_data_count_UNCONNECTED[4:0]),
        .axi_aw_dbiterr(NLW_U0_axi_aw_dbiterr_UNCONNECTED),
        .axi_aw_injectdbiterr(1'b0),
        .axi_aw_injectsbiterr(1'b0),
        .axi_aw_overflow(NLW_U0_axi_aw_overflow_UNCONNECTED),
        .axi_aw_prog_empty(NLW_U0_axi_aw_prog_empty_UNCONNECTED),
        .axi_aw_prog_empty_thresh({1'b0,1'b0,1'b0,1'b0}),
        .axi_aw_prog_full(NLW_U0_axi_aw_prog_full_UNCONNECTED),
        .axi_aw_prog_full_thresh({1'b0,1'b0,1'b0,1'b0}),
        .axi_aw_rd_data_count(NLW_U0_axi_aw_rd_data_count_UNCONNECTED[4:0]),
        .axi_aw_sbiterr(NLW_U0_axi_aw_sbiterr_UNCONNECTED),
        .axi_aw_underflow(NLW_U0_axi_aw_underflow_UNCONNECTED),
        .axi_aw_wr_data_count(NLW_U0_axi_aw_wr_data_count_UNCONNECTED[4:0]),
        .axi_b_data_count(NLW_U0_axi_b_data_count_UNCONNECTED[4:0]),
        .axi_b_dbiterr(NLW_U0_axi_b_dbiterr_UNCONNECTED),
        .axi_b_injectdbiterr(1'b0),
        .axi_b_injectsbiterr(1'b0),
        .axi_b_overflow(NLW_U0_axi_b_overflow_UNCONNECTED),
        .axi_b_prog_empty(NLW_U0_axi_b_prog_empty_UNCONNECTED),
        .axi_b_prog_empty_thresh({1'b0,1'b0,1'b0,1'b0}),
        .axi_b_prog_full(NLW_U0_axi_b_prog_full_UNCONNECTED),
        .axi_b_prog_full_thresh({1'b0,1'b0,1'b0,1'b0}),
        .axi_b_rd_data_count(NLW_U0_axi_b_rd_data_count_UNCONNECTED[4:0]),
        .axi_b_sbiterr(NLW_U0_axi_b_sbiterr_UNCONNECTED),
        .axi_b_underflow(NLW_U0_axi_b_underflow_UNCONNECTED),
        .axi_b_wr_data_count(NLW_U0_axi_b_wr_data_count_UNCONNECTED[4:0]),
        .axi_r_data_count(NLW_U0_axi_r_data_count_UNCONNECTED[10:0]),
        .axi_r_dbiterr(NLW_U0_axi_r_dbiterr_UNCONNECTED),
        .axi_r_injectdbiterr(1'b0),
        .axi_r_injectsbiterr(1'b0),
        .axi_r_overflow(NLW_U0_axi_r_overflow_UNCONNECTED),
        .axi_r_prog_empty(NLW_U0_axi_r_prog_empty_UNCONNECTED),
        .axi_r_prog_empty_thresh({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .axi_r_prog_full(NLW_U0_axi_r_prog_full_UNCONNECTED),
        .axi_r_prog_full_thresh({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .axi_r_rd_data_count(NLW_U0_axi_r_rd_data_count_UNCONNECTED[10:0]),
        .axi_r_sbiterr(NLW_U0_axi_r_sbiterr_UNCONNECTED),
        .axi_r_underflow(NLW_U0_axi_r_underflow_UNCONNECTED),
        .axi_r_wr_data_count(NLW_U0_axi_r_wr_data_count_UNCONNECTED[10:0]),
        .axi_w_data_count(NLW_U0_axi_w_data_count_UNCONNECTED[10:0]),
        .axi_w_dbiterr(NLW_U0_axi_w_dbiterr_UNCONNECTED),
        .axi_w_injectdbiterr(1'b0),
        .axi_w_injectsbiterr(1'b0),
        .axi_w_overflow(NLW_U0_axi_w_overflow_UNCONNECTED),
        .axi_w_prog_empty(NLW_U0_axi_w_prog_empty_UNCONNECTED),
        .axi_w_prog_empty_thresh({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .axi_w_prog_full(NLW_U0_axi_w_prog_full_UNCONNECTED),
        .axi_w_prog_full_thresh({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .axi_w_rd_data_count(NLW_U0_axi_w_rd_data_count_UNCONNECTED[10:0]),
        .axi_w_sbiterr(NLW_U0_axi_w_sbiterr_UNCONNECTED),
        .axi_w_underflow(NLW_U0_axi_w_underflow_UNCONNECTED),
        .axi_w_wr_data_count(NLW_U0_axi_w_wr_data_count_UNCONNECTED[10:0]),
        .axis_data_count(NLW_U0_axis_data_count_UNCONNECTED[10:0]),
        .axis_dbiterr(NLW_U0_axis_dbiterr_UNCONNECTED),
        .axis_injectdbiterr(1'b0),
        .axis_injectsbiterr(1'b0),
        .axis_overflow(NLW_U0_axis_overflow_UNCONNECTED),
        .axis_prog_empty(NLW_U0_axis_prog_empty_UNCONNECTED),
        .axis_prog_empty_thresh({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .axis_prog_full(NLW_U0_axis_prog_full_UNCONNECTED),
        .axis_prog_full_thresh({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .axis_rd_data_count(NLW_U0_axis_rd_data_count_UNCONNECTED[10:0]),
        .axis_sbiterr(NLW_U0_axis_sbiterr_UNCONNECTED),
        .axis_underflow(NLW_U0_axis_underflow_UNCONNECTED),
        .axis_wr_data_count(NLW_U0_axis_wr_data_count_UNCONNECTED[10:0]),
        .backup(1'b0),
        .backup_marker(1'b0),
        .clk(clk),
        .data_count(NLW_U0_data_count_UNCONNECTED[3:0]),
        .dbiterr(NLW_U0_dbiterr_UNCONNECTED),
        .din(din),
        .dout(dout),
        .empty(empty),
        .full(full),
        .injectdbiterr(1'b0),
        .injectsbiterr(1'b0),
        .int_clk(1'b0),
        .m_aclk(1'b0),
        .m_aclk_en(1'b0),
        .m_axi_araddr(NLW_U0_m_axi_araddr_UNCONNECTED[31:0]),
        .m_axi_arburst(NLW_U0_m_axi_arburst_UNCONNECTED[1:0]),
        .m_axi_arcache(NLW_U0_m_axi_arcache_UNCONNECTED[3:0]),
        .m_axi_arid(NLW_U0_m_axi_arid_UNCONNECTED[0]),
        .m_axi_arlen(NLW_U0_m_axi_arlen_UNCONNECTED[7:0]),
        .m_axi_arlock(NLW_U0_m_axi_arlock_UNCONNECTED[0]),
        .m_axi_arprot(NLW_U0_m_axi_arprot_UNCONNECTED[2:0]),
        .m_axi_arqos(NLW_U0_m_axi_arqos_UNCONNECTED[3:0]),
        .m_axi_arready(1'b0),
        .m_axi_arregion(NLW_U0_m_axi_arregion_UNCONNECTED[3:0]),
        .m_axi_arsize(NLW_U0_m_axi_arsize_UNCONNECTED[2:0]),
        .m_axi_aruser(NLW_U0_m_axi_aruser_UNCONNECTED[0]),
        .m_axi_arvalid(NLW_U0_m_axi_arvalid_UNCONNECTED),
        .m_axi_awaddr(NLW_U0_m_axi_awaddr_UNCONNECTED[31:0]),
        .m_axi_awburst(NLW_U0_m_axi_awburst_UNCONNECTED[1:0]),
        .m_axi_awcache(NLW_U0_m_axi_awcache_UNCONNECTED[3:0]),
        .m_axi_awid(NLW_U0_m_axi_awid_UNCONNECTED[0]),
        .m_axi_awlen(NLW_U0_m_axi_awlen_UNCONNECTED[7:0]),
        .m_axi_awlock(NLW_U0_m_axi_awlock_UNCONNECTED[0]),
        .m_axi_awprot(NLW_U0_m_axi_awprot_UNCONNECTED[2:0]),
        .m_axi_awqos(NLW_U0_m_axi_awqos_UNCONNECTED[3:0]),
        .m_axi_awready(1'b0),
        .m_axi_awregion(NLW_U0_m_axi_awregion_UNCONNECTED[3:0]),
        .m_axi_awsize(NLW_U0_m_axi_awsize_UNCONNECTED[2:0]),
        .m_axi_awuser(NLW_U0_m_axi_awuser_UNCONNECTED[0]),
        .m_axi_awvalid(NLW_U0_m_axi_awvalid_UNCONNECTED),
        .m_axi_bid(1'b0),
        .m_axi_bready(NLW_U0_m_axi_bready_UNCONNECTED),
        .m_axi_bresp({1'b0,1'b0}),
        .m_axi_buser(1'b0),
        .m_axi_bvalid(1'b0),
        .m_axi_rdata({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .m_axi_rid(1'b0),
        .m_axi_rlast(1'b0),
        .m_axi_rready(NLW_U0_m_axi_rready_UNCONNECTED),
        .m_axi_rresp({1'b0,1'b0}),
        .m_axi_ruser(1'b0),
        .m_axi_rvalid(1'b0),
        .m_axi_wdata(NLW_U0_m_axi_wdata_UNCONNECTED[63:0]),
        .m_axi_wid(NLW_U0_m_axi_wid_UNCONNECTED[0]),
        .m_axi_wlast(NLW_U0_m_axi_wlast_UNCONNECTED),
        .m_axi_wready(1'b0),
        .m_axi_wstrb(NLW_U0_m_axi_wstrb_UNCONNECTED[7:0]),
        .m_axi_wuser(NLW_U0_m_axi_wuser_UNCONNECTED[0]),
        .m_axi_wvalid(NLW_U0_m_axi_wvalid_UNCONNECTED),
        .m_axis_tdata(NLW_U0_m_axis_tdata_UNCONNECTED[7:0]),
        .m_axis_tdest(NLW_U0_m_axis_tdest_UNCONNECTED[0]),
        .m_axis_tid(NLW_U0_m_axis_tid_UNCONNECTED[0]),
        .m_axis_tkeep(NLW_U0_m_axis_tkeep_UNCONNECTED[0]),
        .m_axis_tlast(NLW_U0_m_axis_tlast_UNCONNECTED),
        .m_axis_tready(1'b0),
        .m_axis_tstrb(NLW_U0_m_axis_tstrb_UNCONNECTED[0]),
        .m_axis_tuser(NLW_U0_m_axis_tuser_UNCONNECTED[3:0]),
        .m_axis_tvalid(NLW_U0_m_axis_tvalid_UNCONNECTED),
        .overflow(NLW_U0_overflow_UNCONNECTED),
        .prog_empty(NLW_U0_prog_empty_UNCONNECTED),
        .prog_empty_thresh({1'b0,1'b0,1'b0,1'b0}),
        .prog_empty_thresh_assert({1'b0,1'b0,1'b0,1'b0}),
        .prog_empty_thresh_negate({1'b0,1'b0,1'b0,1'b0}),
        .prog_full(NLW_U0_prog_full_UNCONNECTED),
        .prog_full_thresh({1'b0,1'b0,1'b0,1'b0}),
        .prog_full_thresh_assert({1'b0,1'b0,1'b0,1'b0}),
        .prog_full_thresh_negate({1'b0,1'b0,1'b0,1'b0}),
        .rd_clk(1'b0),
        .rd_data_count(NLW_U0_rd_data_count_UNCONNECTED[3:0]),
        .rd_en(rd_en),
        .rd_rst(1'b0),
        .rd_rst_busy(NLW_U0_rd_rst_busy_UNCONNECTED),
        .rst(1'b0),
        .s_aclk(1'b0),
        .s_aclk_en(1'b0),
        .s_aresetn(1'b0),
        .s_axi_araddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arburst({1'b0,1'b0}),
        .s_axi_arcache({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arid(1'b0),
        .s_axi_arlen({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arlock(1'b0),
        .s_axi_arprot({1'b0,1'b0,1'b0}),
        .s_axi_arqos({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arready(NLW_U0_s_axi_arready_UNCONNECTED),
        .s_axi_arregion({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arsize({1'b0,1'b0,1'b0}),
        .s_axi_aruser(1'b0),
        .s_axi_arvalid(1'b0),
        .s_axi_awaddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awburst({1'b0,1'b0}),
        .s_axi_awcache({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awid(1'b0),
        .s_axi_awlen({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awlock(1'b0),
        .s_axi_awprot({1'b0,1'b0,1'b0}),
        .s_axi_awqos({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awready(NLW_U0_s_axi_awready_UNCONNECTED),
        .s_axi_awregion({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awsize({1'b0,1'b0,1'b0}),
        .s_axi_awuser(1'b0),
        .s_axi_awvalid(1'b0),
        .s_axi_bid(NLW_U0_s_axi_bid_UNCONNECTED[0]),
        .s_axi_bready(1'b0),
        .s_axi_bresp(NLW_U0_s_axi_bresp_UNCONNECTED[1:0]),
        .s_axi_buser(NLW_U0_s_axi_buser_UNCONNECTED[0]),
        .s_axi_bvalid(NLW_U0_s_axi_bvalid_UNCONNECTED),
        .s_axi_rdata(NLW_U0_s_axi_rdata_UNCONNECTED[63:0]),
        .s_axi_rid(NLW_U0_s_axi_rid_UNCONNECTED[0]),
        .s_axi_rlast(NLW_U0_s_axi_rlast_UNCONNECTED),
        .s_axi_rready(1'b0),
        .s_axi_rresp(NLW_U0_s_axi_rresp_UNCONNECTED[1:0]),
        .s_axi_ruser(NLW_U0_s_axi_ruser_UNCONNECTED[0]),
        .s_axi_rvalid(NLW_U0_s_axi_rvalid_UNCONNECTED),
        .s_axi_wdata({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_wid(1'b0),
        .s_axi_wlast(1'b0),
        .s_axi_wready(NLW_U0_s_axi_wready_UNCONNECTED),
        .s_axi_wstrb({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_wuser(1'b0),
        .s_axi_wvalid(1'b0),
        .s_axis_tdata({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axis_tdest(1'b0),
        .s_axis_tid(1'b0),
        .s_axis_tkeep(1'b0),
        .s_axis_tlast(1'b0),
        .s_axis_tready(NLW_U0_s_axis_tready_UNCONNECTED),
        .s_axis_tstrb(1'b0),
        .s_axis_tuser({1'b0,1'b0,1'b0,1'b0}),
        .s_axis_tvalid(1'b0),
        .sbiterr(NLW_U0_sbiterr_UNCONNECTED),
        .sleep(1'b0),
        .srst(srst),
        .underflow(NLW_U0_underflow_UNCONNECTED),
        .valid(NLW_U0_valid_UNCONNECTED),
        .wr_ack(NLW_U0_wr_ack_UNCONNECTED),
        .wr_clk(1'b0),
        .wr_data_count(NLW_U0_wr_data_count_UNCONNECTED[3:0]),
        .wr_en(wr_en),
        .wr_rst(1'b0),
        .wr_rst_busy(NLW_U0_wr_rst_busy_UNCONNECTED));
endmodule
`pragma protect begin_protected
`pragma protect version = 1
`pragma protect encrypt_agent = "XILINX"
`pragma protect encrypt_agent_info = "Xilinx Encryption Tool 2024.2"
`pragma protect key_keyowner="Synopsys", key_keyname="SNPS-VCS-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
FPXllyX2NFs/RMngGqZy2bLYbZr92CdofeZrJOHklWXExpaPgHNYp2Lzm4MnflbnrfSkCmLwwKT5
zfRgEip7FKQ5Zhb73p0MAIADixBZ/ZRt4hQkJL0T9brm0waLHfanjnov2aCX6jN3LbQc3ujmDga6
Dd73k78u4xjRTDv1/P4=

`pragma protect key_keyowner="Aldec", key_keyname="ALDEC15_001", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
kr7VKKvChFoiyRCReag+OvU3jnmG9pN0cv+BxhNmMKLthg/ksgNZyU3L+fQ7cmIQELtlUjwjkBAP
Jjq5RsCnHbJxj+Ys1GNhriiBsxLqxWCP8onhAVvgZN2xZFOih0UWpqlU8NVP8Eww1ohvkDgxTstC
3kDmYehxIUJjqCC/mgRZmuezqugrFdubYmBoz16tUvD17iA5qqCIMS9xSIXYp2LBNekmWEwrVqzu
R4koEo4UlXl/CEw0XY3QvMoHnlXgu6N/6sc+nxZtKSwjiMVvGnZE9UVvJPAC3Hn3zKFGlK53mmGO
Tj0dWzhwX0ahSYzkyJC/HLdbGZmriL2UNvDyFw==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VELOCE-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
CaLc9FGt3AdRHfNtGAsGFY/QEvHY1Vv4TvvgCDsdDMqiuDeLizFJDJeskBWjeKDoE2cufK8TxiBq
mySRQNJoeOKnxTiDdf+Rx6m0iR6h/YeswegYwgghpM5KVrl6mSwF3+4yEovPM7a+9ArDQ5vl+WT8
SilNGzyW0KnTwe7+szs=

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VERIF-SIM-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
cEnudSW1X71p0Xuq6jrXOxHnBku87IA0RA3zKqmeZHZM0r+9rEm5MSzX8RecnQ994yiqeyxbIH2l
fGEzUzr0ZzryS3fkf2LnJuB39f2YARW9eVCSiaeWaraZuY1l89T+h3vgdlurS/1LIraYLS1MyOXa
6F1LAcQp3W4OO4ctc3q1FRMZGldRS1biMsKwJ8Lxj8NEOm67UfgFrJNQAxbVXEfbWRWhKtwNxcTB
JbgC8j4EHkIA46mzoHloeBAL6KieplQUBjKXSSTb66rxglbFhWLy+mirROHcocu9J4ZbvTRYZEww
4lso1lqAllVLAoKYqa3WImZuSRoTbGDngBt9Lg==

`pragma protect key_keyowner="Real Intent", key_keyname="RI-RSA-KEY-1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
rOyI+x4PlmKcVSFoN3oKgSYpVlmYxc194Ej04il/YmBg10xopy4zmtu5sdCP/uGSNYcNGWeAiw01
mNf98KyNgTUFXruHCA38qjhhEIvl4vfWWn3W3mFRxrIuwmnreT6qTvgMaxIkCdVBDP7Iy7O6WmCf
3Va5X5hnCHhtXgX5UYniBHiLjmupv63B8XMAYDH2n6mQ3H0DF7mtb7psBafd0Z6+IWUbmzwMtKrf
ZrRJBGAhNT0i1KrEjEh/rWjN7Z7N32zQ+Pl1kc5gYCQIX5McfdTdqSaRVXZ/HF90ymS7/8d5LDyj
Er+ORdcjnOn6oAyY4PuUUl4OYUHv5k+RglTe5Q==

`pragma protect key_keyowner="Xilinx", key_keyname="xilinxt_2023_11", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
bJa7kPSpDipzoJoQu1APEjc8vFLqBfQZK/grZvWijD7/FgMTerFCWLUY6n8DWeGdvjXvTeyrqCHE
2rP/H57wUqPC8tIJlGm6ZYQGjZ3TgYqLrJshDE5zYMTO//q0vuSraWvZP7A7SLuW6y7tFE/nplpx
L8gbYORx6j70okGUwnamCMS9yhFr7Z2QTJne1k4GNFGvy66URk3k5cBPl5j4/1yc4xGV+aWYl6L8
q8RorRU/CltObHKrji/jdiY1WtdGrkpRyCEFc+XNPazL9xSLLu5bz6XlvKwoks+8a5KYT/VFUovM
JbM0bpAXM8Z7rGaPuXjqXtZBg5praTZLu/WNcA==

`pragma protect key_keyowner="Metrics Technologies Inc.", key_keyname="DSim", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
PYKBDinOGc/kIVdFzXrz2wA4/QNFxLDrQfTWfR5TjYE6bm49vrZi0bawcr9HXp4OP1+XxPLB3oCP
oV5e/rYeDln531ebt8yEg27XCoSHEX4FU8oG8aBJ8fqgWayOnAMJt025WodOxuZXbhT1zPo7J3uh
6iO9Mv7RtYE2fZ1W+G8oN//FTOEJYPWlKYnt0cDeZrN3I4rHHptZHuu7l8T+df0PYea3x6U3Mvkl
ojZ+TwQtdu0NuYY5j3QNgx3+W2XYq1M773FAnEz/deW54EjE+jf1jjrBk2pl8SYxeKuutS15oPVF
eHdqXYVcJxoUY5JH8z04lITKEnZ4oq6sYS6dog==

`pragma protect key_keyowner="Atrenta", key_keyname="ATR-SG-RSA-1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=384)
`pragma protect key_block
tl+2vFCWZ583gQGsVC7oopz2NCKBiJ9uOHYBGzJZheOHJMqI/ehNvo25l710eBx00tztXzM30AH6
ZhAJg+kJwE2jO0MV5fmG5dnwXmLqoGEJMBs7xwWxvYK7w/0z9M0AJKD7HnuC+IiLhNU/fIxyuE+I
+vWqp//RcfY0tMMp2I2J1yEW6GUahS1ve/4JchssZ7Xu7VthoSDWXMQWATbvsUsDzeSo2+Ruz8Kq
Dc05HqEU8NgBxDPPEKLCcdKLp4byglwj7iCAtCjsPy8P18qjgb2sycFjNgmaiNMMB51WqeD+hneG
hLOue9bqVdEojkrb3q4WbsGZKz0bAGsryxslOlYHP1b8vey3yI2ixA80wyERe8d3GRIeZiSxGykH
qWxsE6x/iyi8QRb5mXZPMApA+Fln8tYmn7+1rFCm8gF4gJWhr1PsSJqTi658symGrzT0Ghjvf2QL
SvvoaeNdy0pOsWs7jLBFndd4GiFA+9K6Y33sziLToU9EvvFokENIslod

`pragma protect key_keyowner="Cadence Design Systems.", key_keyname="CDS_RSA_KEY_VER_1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
oYiCujFRj1F3wKsGZlHR9niEtR9MLXEVAVfy+f/3xrmpW6Ye5a+fBCvm4TH+iRQefGHNdMPnzTNW
K/pEPAS9uMJjOdFiu+APT+LYrSRnEg4W0dX5buSDGM6LBWAuMseoTMjbJJoYDGLRckJgW43E30mX
ej4823nkbfwc+Ecbrup825qLyv8RTQLNHafvJA5lSapdqXwnlOIYRmcHn+sfAh5pGv9kW9aokcdh
ObR2XYxX99rYloyvz3x0pmjxD5ILW4SQMB1IUEuuyqX6eb5IQ+kZ41hjvsHIuQH29vzpCfV9Jqha
WC5yxxK1R+cleZSKD1H1gVzbTei8uFs/91Bgeg==

`pragma protect key_keyowner="Synplicity", key_keyname="SYNP15_1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
urNc+S8AFPj+GVFdqJE5V7P8O6QI6MA3nkwYb8NKbYbVufnXKg6voJIRYYeYr7EOa8mrqirozWbY
Lln9SLWnkaAy2LvL/N6WahoQdCt++4RH+xe768XvSrVUFPrIwZRixqMLurc/tPov4i5P/ukZKl18
ZPZvXRzUNlvCZnMPcF+5QCQihqPbjcZ0YyGgWgX/ipTGG3sNqmylGN7qLa4Rgqu/mB5a2xVyu5Wc
911+/X3VVFx697WVaP5V0SbOzYN8R8+8B8kdznwixMA+f4lSbBXyRysVOSzYjo8bKEMqyKMVBQn9
xDmEuV0DvVWXdO7VPvWA1LuJFwS07OxeI2GCcQ==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-PREC-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
QcP7fsLZxaDrG29e9HQeXfu2TsKsdyW7Yc1vWct6lbmDEfXkWMU1fFWSPIjPzRc9UOnfEu0bRn+B
D+8MWokqes3WF7txljBmgUPiNGZ8arUU6ENa/IY/Wv7iaB/ZKM5PtdnFAkjDIrYyKFCTz/U6Yzwi
hBGGarK/wYQOLzeeKRewiPTiNUL7tztWuMZ1t1msxD951EeKrwjrjcXIIuf/TzrOGUOlWgjHlnrl
4Q/lfMAnRLBNTSWG+5wWewCE8jK2X/gJ5AV4p3x1WP3+JglbxpP39l3pzedXqciZPbuz2XlFnRPV
KByaUaAShzJ56p8+0HjWebibqQdieGNPiPWW0Q==

`pragma protect data_method = "AES128-CBC"
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 70736)
`pragma protect data_block
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
`pragma protect end_protected
`ifndef GLBL
`define GLBL
`timescale  1 ps / 1 ps

module glbl ();

    parameter ROC_WIDTH = 100000;
    parameter TOC_WIDTH = 0;
    parameter GRES_WIDTH = 10000;
    parameter GRES_START = 10000;

//--------   STARTUP Globals --------------
    wire GSR;
    wire GTS;
    wire GWE;
    wire PRLD;
    wire GRESTORE;
    tri1 p_up_tmp;
    tri (weak1, strong0) PLL_LOCKG = p_up_tmp;

    wire PROGB_GLBL;
    wire CCLKO_GLBL;
    wire FCSBO_GLBL;
    wire [3:0] DO_GLBL;
    wire [3:0] DI_GLBL;
   
    reg GSR_int;
    reg GTS_int;
    reg PRLD_int;
    reg GRESTORE_int;

//--------   JTAG Globals --------------
    wire JTAG_TDO_GLBL;
    wire JTAG_TCK_GLBL;
    wire JTAG_TDI_GLBL;
    wire JTAG_TMS_GLBL;
    wire JTAG_TRST_GLBL;

    reg JTAG_CAPTURE_GLBL;
    reg JTAG_RESET_GLBL;
    reg JTAG_SHIFT_GLBL;
    reg JTAG_UPDATE_GLBL;
    reg JTAG_RUNTEST_GLBL;

    reg JTAG_SEL1_GLBL = 0;
    reg JTAG_SEL2_GLBL = 0 ;
    reg JTAG_SEL3_GLBL = 0;
    reg JTAG_SEL4_GLBL = 0;

    reg JTAG_USER_TDO1_GLBL = 1'bz;
    reg JTAG_USER_TDO2_GLBL = 1'bz;
    reg JTAG_USER_TDO3_GLBL = 1'bz;
    reg JTAG_USER_TDO4_GLBL = 1'bz;

    assign (strong1, weak0) GSR = GSR_int;
    assign (strong1, weak0) GTS = GTS_int;
    assign (weak1, weak0) PRLD = PRLD_int;
    assign (strong1, weak0) GRESTORE = GRESTORE_int;

    initial begin
	GSR_int = 1'b1;
	PRLD_int = 1'b1;
	#(ROC_WIDTH)
	GSR_int = 1'b0;
	PRLD_int = 1'b0;
    end

    initial begin
	GTS_int = 1'b1;
	#(TOC_WIDTH)
	GTS_int = 1'b0;
    end

    initial begin 
	GRESTORE_int = 1'b0;
	#(GRES_START);
	GRESTORE_int = 1'b1;
	#(GRES_WIDTH);
	GRESTORE_int = 1'b0;
    end

endmodule
`endif
