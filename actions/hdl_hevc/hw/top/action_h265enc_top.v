`timescale 1ns/1ps
//Yanheng Lu
//IBM CSL OpenPower
//lyhlu@cn.ibm.com
//`define RETURN_CODE_ENABLE

module action_h265enc_top #(
    parameter ID_WIDTH = 1,
    parameter LITE_DWIDTH = 32,
    parameter LITE_AWIDTH = 32,
    parameter HOST_DWIDTH = 1024,
    parameter HOST_AWIDTH = 64
)(
        input                           clk                 ,
        input                           rst_n               ,
		input       [31:0]              i_action_type       ,
		input       [31:0]              i_action_version    ,
		output                          o_interrupt         ,
		input                           i_interrupt_ack     ,

        //---- AXI Lite bus----
          // AXI write address channel
        output                          s_axi_snap_awready  ,
        input       [LITE_AWIDTH-1:0]   s_axi_snap_awaddr   ,
        input       [02:0]              s_axi_snap_awprot   ,
        input                           s_axi_snap_awvalid  ,
          // AXI write data channel
        output                          s_axi_snap_wready   ,
        input       [LITE_DWIDTH-1:0]   s_axi_snap_wdata    ,
        input       [LITE_DWIDTH/8-1:0] s_axi_snap_wstrb    ,
        input                           s_axi_snap_wvalid   ,
          // AXI response channel
        output      [01:0]              s_axi_snap_bresp    ,
        output                          s_axi_snap_bvalid   ,
        input                           s_axi_snap_bready   ,
          // AXI read address channel
        output                          s_axi_snap_arready  ,
        input                           s_axi_snap_arvalid  ,
        input       [LITE_AWIDTH-1:0]   s_axi_snap_araddr   ,
        input       [02:0]              s_axi_snap_arprot   ,
          // AXI read data channel
        output      [LITE_DWIDTH - 1:0] s_axi_snap_rdata    ,
        output      [01:0]              s_axi_snap_rresp    ,
        input                           s_axi_snap_rready   ,
        output                          s_axi_snap_rvalid   ,
        //---- AXI bus ----
        // AXI write address channel
        output      [ID_WIDTH-1:0]      m_axi_snap_awid     ,
        output      [HOST_AWIDTH-1:0]   m_axi_snap_awaddr   ,
        output      [0007:0]            m_axi_snap_awlen    ,
        output      [0002:0]            m_axi_snap_awsize   ,
        output      [0001:0]            m_axi_snap_awburst  ,
        output      [0003:0]            m_axi_snap_awcache  ,
        output                          m_axi_snap_awlock   ,
        output      [0002:0]            m_axi_snap_awprot   ,
        output      [0003:0]            m_axi_snap_awqos    ,
        output      [0003:0]            m_axi_snap_awregion ,
        output      [USER_WIDTH-1:0]    m_axi_snap_awuser   ,
        output                          m_axi_snap_awvalid  ,
        input                           m_axi_snap_awready  ,
        // AXI write data channel
        output      [ID_WIDTH-1:0]      m_axi_snap_wid      ,
        output      [HOST_DWIDTH-1:0]   m_axi_snap_wdata    ,
        output      [HOST_DWIDTH/8-1:0] m_axi_snap_wstrb    ,
        output                          m_axi_snap_wlast    ,
        output                          m_axi_snap_wvalid   ,
        input                           m_axi_snap_wready   ,
        // AXI write response channel
        output                          m_axi_snap_bready   ,
        input       [ID_WIDTH-1:0]      m_axi_snap_bid      ,
        input       [0001:0]            m_axi_snap_bresp    ,
        input                           m_axi_snap_bvalid   ,
           // AXI read address channel
        output      [ID_WIDTH-1:0]      m_axi_snap_arid     ,
        output      [HOST_AWIDTH-1:0]   m_axi_snap_araddr   ,
        output      [007:0]             m_axi_snap_arlen    ,
        output      [002:0]             m_axi_snap_arsize   ,
        output      [001:0]             m_axi_snap_arburst  ,
        output      [USER_WIDTH-1:0]    m_axi_snap_aruser   ,
        output      [003:0]             m_axi_snap_arcache  ,
        output      [001:0]             m_axi_snap_arlock   ,
        output      [002:0]             m_axi_snap_arprot   ,
        output      [003:0]             m_axi_snap_arqos    ,
        output      [003:0]             m_axi_snap_arregion ,
        output                          m_axi_snap_arvalid  ,
        input                           m_axi_snap_arready  ,
          // axi_snap read data channel
        output                          m_axi_snap_rready   ,
        input       [ID_WIDTH-1:0]      m_axi_snap_rid      ,
        input       [HOST_DWIDTH-1:0]   m_axi_snap_rdata    ,
        input       [001:0]             m_axi_snap_rresp    ,
        input                           m_axi_snap_rlast    ,
        input                           m_axi_snap_rvalid
);

    wire    [PINFO_WIDTH-1:0]       process_info_w  ;
    wire                            process_start_w ;
    wire                            process_ready_w ;
    wire                            dsc0_pull_w     ;
    wire                            dsc0_ready_w    ;
    wire    [HOST_DWIDTH-1:0]       dsc0_data_w     ;
    wire                            complete_push_w ;
    wire    [RETURN_WIDTH-1:0]      return_data_w   ;
    wire                            complete_ready_w;
    wire    [31:0]                  cmpl_ram_data_w ;
    wire    [PASID_WIDTH-1:0]       cmpl_ram_addr_w ;
    wire                            cmpl_ram_hi_w   ;
    wire                            cmpl_ram_lo_w   ;

	// AXI write address channel
    wire                            enc_m_axi_awid;
    wire    [ENC_AWIDTH -1 :0]      enc_m_axi_awaddr;
    wire    [0007:0]                enc_m_axi_awlen;
    wire    [0002:0]                enc_m_axi_awsize;
    wire    [0001:0]                enc_m_axi_awburst;
    wire    [0003:0]                enc_m_axi_awcache;
    wire                            enc_m_axi_awlock;
    wire    [0002:0]                enc_m_axi_awprot;
    wire    [0003:0]                enc_m_axi_awqos;
    wire    [0003:0]                enc_m_axi_awregion;
    wire                            enc_m_axi_awvalid;
    wire                            enc_m_axi_awready;
    // AXI write data channel
    wire                            enc_m_axi_wid;
    wire    [ENC_DWIDTH -1 :0]      enc_m_axi_wdata;
    wire    [ENC_DWIDTH/8-1 :0]     enc_m_axi_wstrb;
    wire                            enc_m_axi_wlast;
    wire                            enc_m_axi_wvalid;
    wire                            enc_m_axi_wready;
    // AXI write response channel
    wire                            enc_m_axi_bready;
    wire                            enc_m_axi_bid;
    wire    [1:0]                   enc_m_axi_bresp;
    wire                            enc_m_axi_bvalid;
    // AXI read address channel
    wire                            enc_m_axi_arid;
    wire    [ENC_AWIDTH-1:0]        enc_m_axi_araddr;
    wire    [0007:0]                enc_m_axi_arlen;
    wire    [0002:0]                enc_m_axi_arsize;
    wire    [0001:0]                enc_m_axi_arburst;
    wire    [0003:0]                enc_m_axi_arcache;
    wire                            enc_m_axi_arlock;
    wire    [0002:0]                enc_m_axi_arprot;
    wire    [0003:0]                enc_m_axi_arqos;
    wire    [0003:0]                enc_m_axi_arregion;
    wire                            enc_m_axi_arvalid;
    wire                            enc_m_axi_arready;
    // AXI read data channel
    wire                            enc_m_axi_rready;
    wire                            enc_m_axi_rid;
    wire    [ENC_DWIDTH-1 :0]       enc_m_axi_rdata;
    wire    [1:0]                   enc_m_axi_rresp;
    wire                            enc_m_axi_rlast;
    wire                            enc_m_axi_rvalid;

assign o_interrupt = 1'b0;
assign m_axi_snap_awuser = 'd0;

//h265enc
    enc_top enctop0(
        // global
        .clk                        ( clk               ),
        .rstn                       ( rst_n             ),
  // axilite_s
        .axilite_s_awready_o        ( s_axi_snap_awready),
        .axilite_s_awaddr_i         ( s_axi_snap_awaddr ),
        .axilite_s_awvalid_o        ( s_axi_snap_awvalid),
        .axilite_s_wready_o         ( s_axi_snap_wready ),
        .axilite_s_wdata_i          ( s_axi_snap_wdata  ),
        .axilite_s_wstrb_i          ( s_axi_snap_wstrb  ),
        .axilite_s_wvalid_i         ( s_axi_snap_wvalid ),
        .axilite_s_bresp_o          ( s_axi_snap_bresp  ),
        .axilite_s_bvalid_o         ( s_axi_snap_bvalid ),
        .axilite_s_bready_i         ( s_axi_snap_bready ),
        .axilite_s_arready_o        ( s_axi_snap_arready),
        .axilite_s_araddr_i         ( s_axi_snap_araddr ),
        .axilite_s_arvalid_i        ( s_axi_snap_arvalid),
        .axilite_s_rdata_o          ( s_axi_snap_rdata  ),
        .axilite_s_rresp_o          ( s_axi_snap_rresp  ),
        .axilite_s_rvalid_o         ( s_axi_snap_rvalid ),
        .axilite_s_rready_i         ( s_axi_snap_rready ),
  // axi_m
        .axi_m_arready_i            ( enc_m_axi_arready ),
        .axi_m_awready_i            ( enc_m_axi_awready ),
        .axi_m_bid_i                ( enc_m_axi_bid     ),
        .axi_m_bresp_i              ( enc_m_axi_bresp   ),
        .axi_m_bvalid_i             ( enc_m_axi_bvalid  ),
        .axi_m_rdata_i              ( enc_m_axi_rdata   ),
        .axi_m_rid_i                ( enc_m_axi_rid     ),
        .axi_m_rlast_i              ( enc_m_axi_rlast   ),
        .axi_m_rresp_i              ( enc_m_axi_rresp   ),
        .axi_m_rvalid_i             ( enc_m_axi_rvalid  ),
        .axi_m_wready_i             ( enc_m_axi_wready  ),
        .axi_m_araddr_o             ( enc_m_axi_araddr  ),
        .axi_m_arburst_o            ( enc_m_axi_arburst ),
        .axi_m_arcache_o            ( enc_m_axi_arcache ),
        .axi_m_arid_o               ( enc_m_axi_arid    ),
        .axi_m_arlen_o              ( enc_m_axi_arlen   ),
        .axi_m_arlock_o             ( enc_m_axi_arlock  ),
        .axi_m_arprot_o             ( enc_m_axi_arprot  ),
        .axi_m_arsize_o             ( enc_m_axi_arsize  ),
        .axi_m_arvalid_o            ( enc_m_axi_arvalid ),
        .axi_m_awaddr_o             ( enc_m_axi_awaddr  ),
        .axi_m_awburst_o            ( enc_m_axi_awburst ),
        .axi_m_awcache_o            ( enc_m_axi_awcache ),
        .axi_m_awid_o               ( enc_m_axi_awid    ),
        .axi_m_awlen_o              ( enc_m_axi_awlen   ),
        .axi_m_awlock_o             ( enc_m_axi_awlock  ),
        .axi_m_awprot_o             ( enc_m_axi_awprot  ),
        .axi_m_awsize_o             ( enc_m_axi_awsize  ),
        .axi_m_awvalid_o            ( enc_m_axi_awvalid ),
        .axi_m_bready_o             ( enc_m_axi_bready  ),
        .axi_m_rready_o             ( enc_m_axi_rready  ),
        .axi_m_wdata_o              ( enc_m_axi_wdata   ),
        .axi_m_wid_o                ( enc_m_axi_wid     ),
        .axi_m_wlast_o              ( enc_m_axi_wlast   ),
        .axi_m_wstrb_o              ( enc_m_axi_wstrb   ),
        .axi_m_wvalid_o             ( enc_m_axi_wvalid  )
    );

//1-to-1 AXI MM interconnect
    axi_dwidth_converter    axi_mm_X (
        .INTERCONNECT_ACLK          ( clk               ),
        .INTERCONNECT_ARESETN       ( rst_n             ),

        .S00_AXI_ARESET_OUT_N       (                   ),
        .S00_AXI_ACLK               ( clk               ),
        .S00_AXI_AWID               ( enc_m_axi_awid    ),
        .S00_AXI_AWADDR             ( enc_m_axi_awaddr  ),
        .S00_AXI_AWLEN              ( enc_m_axi_awlen   ),
        .S00_AXI_AWSIZE             ( enc_m_axi_awsize  ),
        .S00_AXI_AWBURST            ( enc_m_axi_awburst ),
        .S00_AXI_AWLOCK             ( enc_m_axi_awlock  ),
        .S00_AXI_AWCACHE            ( enc_m_axi_awcache ),
        .S00_AXI_AWPROT             ( enc_m_axi_awprot  ),
        .S00_AXI_AWQOS              ( enc_m_axi_awqos   ),
        .S00_AXI_AWVALID            ( enc_m_axi_awvalid ),
        .S00_AXI_AWREADY            ( enc_m_axi_awready ),
        .S00_AXI_WDATA              ( enc_m_axi_wdata   ),
        .S00_AXI_WSTRB              ( enc_m_axi_wstrb   ),
        .S00_AXI_WLAST              ( enc_m_axi_wlast   ),
        .S00_AXI_WVALID             ( enc_m_axi_wvalid  ),
        .S00_AXI_WREADY             ( enc_m_axi_wready  ),
        .S00_AXI_BID                ( enc_m_axi_bid     ),
        .S00_AXI_BRESP              ( enc_m_axi_bresp   ),
        .S00_AXI_BVALID             ( enc_m_axi_bvalid  ),
        .S00_AXI_BREADY             ( enc_m_axi_bready  ),
        .S00_AXI_ARID               ( enc_m_axi_arid    ),
        .S00_AXI_ARADDR             ( enc_m_axi_araddr  ),
        .S00_AXI_ARLEN              ( enc_m_axi_arlen   ),
        .S00_AXI_ARSIZE             ( enc_m_axi_arsize  ),
        .S00_AXI_ARBURST            ( enc_m_axi_arburst ),
        .S00_AXI_ARLOCK             ( enc_m_axi_arlock  ),
        .S00_AXI_ARCACHE            ( enc_m_axi_arcache ),
        .S00_AXI_ARPROT             ( enc_m_axi_arprot  ),
        .S00_AXI_ARQOS              ( enc_m_axi_arqos   ),
        .S00_AXI_ARVALID            ( enc_m_axi_arvalid ),
        .S00_AXI_ARREADY            ( enc_m_axi_arready ),
        .S00_AXI_RID                ( enc_m_axi_rid     ),
        .S00_AXI_RDATA              ( enc_m_axi_rdata   ),
        .S00_AXI_RRESP              ( enc_m_axi_rresp   ),
        .S00_AXI_RLAST              ( enc_m_axi_rlast   ),
        .S00_AXI_RVALID             ( enc_m_axi_rvalid  ),
        .S00_AXI_RREADY             ( enc_m_axi_rready  ),

        .M00_AXI_ARESET_OUT_N       (                   ),
        .M00_AXI_ACLK               ( clk               ),
        .M00_AXI_AWID               ( m_axi_snap_awid   ),
        .M00_AXI_AWADDR             ( m_axi_snap_awaddr ),
        .M00_AXI_AWLEN              ( m_axi_snap_awlen  ),
        .M00_AXI_AWSIZE             ( m_axi_snap_awsize ),
        .M00_AXI_AWBURST            ( m_axi_snap_awburst),
        .M00_AXI_AWLOCK             ( m_axi_snap_awlock ),
        .M00_AXI_AWCACHE            ( m_axi_snap_awcache),
        .M00_AXI_AWPROT             ( m_axi_snap_awprot ),
        .M00_AXI_AWQOS              ( m_axi_snap_awqos  ),
        .M00_AXI_AWVALID            ( m_axi_snap_awvalid),
        .M00_AXI_AWREADY            ( m_axi_snap_awready),
        .M00_AXI_WDATA              ( m_axi_snap_wdata  ),
        .M00_AXI_WSTRB              ( m_axi_snap_wstrb  ),
        .M00_AXI_WLAST              ( m_axi_snap_wlast  ),
        .M00_AXI_WVALID             ( m_axi_snap_wvalid ),
        .M00_AXI_WREADY             ( m_axi_snap_wready ),
        .M00_AXI_BID                ( m_axi_snap_bid    ),
        .M00_AXI_BRESP              ( m_axi_snap_bresp  ),
        .M00_AXI_BVALID             ( m_axi_snap_bvalid ),
        .M00_AXI_BREADY             ( m_axi_snap_bready ),
        .M00_AXI_ARID               ( m_axi_snap_arid   ),
        .M00_AXI_ARADDR             ( m_axi_snap_araddr ),
        .M00_AXI_ARLEN              ( m_axi_snap_arlen  ),
        .M00_AXI_ARSIZE             ( m_axi_snap_arsize ),
        .M00_AXI_ARBURST            ( m_axi_snap_arburst),
        .M00_AXI_ARLOCK             ( m_axi_snap_arlock ),
        .M00_AXI_ARCACHE            ( m_axi_snap_arcache),
        .M00_AXI_ARPROT             ( m_axi_snap_arprot ),
        .M00_AXI_ARQOS              ( m_axi_snap_arqos  ),
        .M00_AXI_ARVALID            ( m_axi_snap_arvalid),
        .M00_AXI_ARREADY            ( m_axi_snap_arready),
        .M00_AXI_RID                ( m_axi_snap_rid    ),
        .M00_AXI_RDATA              ( m_axi_snap_rdata  ),
        .M00_AXI_RRESP              ( m_axi_snap_rresp  ),
        .M00_AXI_RLAST              ( m_axi_snap_rlast  ),
        .M00_AXI_RVALID             ( m_axi_snap_rvalid ),
        .M00_AXI_RREADY             ( m_axi_snap_rready )
        );

endmodule
