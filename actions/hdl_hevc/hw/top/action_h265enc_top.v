`timescale 1ns/1ps
//Yanheng Lu
//IBM CSL OpenPower
//lyhlu@cn.ibm.com
//`define RETURN_CODE_ENABLE

module action_h265enc_top #(
    parameter ID_WIDTH = 1,
    parameter USER_WIDTH =9,
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
        //output      [ID_WIDTH-1:0]      m_axi_snap_wid      ,
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

parameter ENC_AWIDTH = 'd64;
parameter ENC_DWIDTH = 'd128;

    // AXI write address channel
    //wire                            enc_m_axi_awid;
    wire    [ENC_AWIDTH -1 :0]      enc_m_axi_awaddr;
    wire    [0007:0]                enc_m_axi_awlen;
    wire    [0003:0]                enc_m_axi_awlen0;
    wire    [0002:0]                enc_m_axi_awsize;
    wire    [0001:0]                enc_m_axi_awburst;
    wire    [0003:0]                enc_m_axi_awcache;
    wire                            enc_m_axi_awlock;
    wire    [0002:0]                enc_m_axi_awprot;
    wire    [0003:0]                enc_m_axi_awqos;
    //wire    [0003:0]                enc_m_axi_awregion;
    wire                            enc_m_axi_awvalid;
    wire                            enc_m_axi_awready;
    // AXI write data channel
    //wire                            enc_m_axi_wid;
    wire    [ENC_DWIDTH -1 :0]      enc_m_axi_wdata;
    wire    [ENC_DWIDTH/8-1 :0]     enc_m_axi_wstrb;
    wire                            enc_m_axi_wlast;
    wire                            enc_m_axi_wvalid;
    wire                            enc_m_axi_wready;
    // AXI write response channel
    wire                            enc_m_axi_bready;
    //wire                            enc_m_axi_bid;
    wire    [1:0]                   enc_m_axi_bresp;
    wire                            enc_m_axi_bvalid;
    // AXI read address channel
    //wire                            enc_m_axi_arid;
    wire    [ENC_AWIDTH-1:0]        enc_m_axi_araddr;
    wire    [0007:0]                enc_m_axi_arlen;
    wire    [0003:0]                enc_m_axi_arlen0;
    wire    [0002:0]                enc_m_axi_arsize;
    wire    [0001:0]                enc_m_axi_arburst;
    wire    [0003:0]                enc_m_axi_arcache;
    wire                            enc_m_axi_arlock;
    wire    [0002:0]                enc_m_axi_arprot;
    wire    [0003:0]                enc_m_axi_arqos;
    //wire    [0003:0]                enc_m_axi_arregion;
    wire                            enc_m_axi_arvalid;
    wire                            enc_m_axi_arready;
    // AXI read data channel
    wire                            enc_m_axi_rready;
    //wire                            enc_m_axi_rid;
    wire    [ENC_DWIDTH-1 :0]       enc_m_axi_rdata;
    wire    [1:0]                   enc_m_axi_rresp;
    wire                            enc_m_axi_rlast;
    wire                            enc_m_axi_rvalid;

assign o_interrupt = 1'b0;
assign m_axi_snap_awuser = 'd0;
assign m_axi_snap_aruser = 'd0;
assign m_axi_snap_awid = 'd0;
assign m_axi_snap_arid = 'd0;
assign m_axi_snap_awregion = 'd0;
assign m_axi_snap_arregion = 'd0;
assign enc_m_axi_arqos = 'd0;
assign enc_m_axi_awqos = 'd0;
assign enc_m_axi_awlen = {4'b0,enc_m_axi_awlen0};
assign enc_m_axi_arlen = {4'b0,enc_m_axi_arlen0};

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
        .axi_m_bid_i                ( 'd0               ),
        .axi_m_bresp_i              ( enc_m_axi_bresp   ),
        .axi_m_bvalid_i             ( enc_m_axi_bvalid  ),
        .axi_m_rdata_i              ( enc_m_axi_rdata   ),
        .axi_m_rid_i                ( 'd0               ),
        .axi_m_rlast_i              ( enc_m_axi_rlast   ),
        .axi_m_rresp_i              ( enc_m_axi_rresp   ),
        .axi_m_rvalid_i             ( enc_m_axi_rvalid  ),
        .axi_m_wready_i             ( enc_m_axi_wready  ),
        .axi_m_araddr_o             ( enc_m_axi_araddr  ),
        .axi_m_arburst_o            ( enc_m_axi_arburst ),
        .axi_m_arcache_o            ( enc_m_axi_arcache ),
        .axi_m_arid_o               (                   ),
        .axi_m_arlen_o              ( enc_m_axi_arlen0  ),
        .axi_m_arlock_o             ( enc_m_axi_arlock  ),
        .axi_m_arprot_o             ( enc_m_axi_arprot  ),
        .axi_m_arsize_o             ( enc_m_axi_arsize  ),
        .axi_m_arvalid_o            ( enc_m_axi_arvalid ),
        .axi_m_awaddr_o             ( enc_m_axi_awaddr  ),
        .axi_m_awburst_o            ( enc_m_axi_awburst ),
        .axi_m_awcache_o            ( enc_m_axi_awcache ),
        .axi_m_awid_o               (                   ),
        .axi_m_awlen_o              ( enc_m_axi_awlen0  ),
        .axi_m_awlock_o             ( enc_m_axi_awlock  ),
        .axi_m_awprot_o             ( enc_m_axi_awprot  ),
        .axi_m_awsize_o             ( enc_m_axi_awsize  ),
        .axi_m_awvalid_o            ( enc_m_axi_awvalid ),
        .axi_m_bready_o             ( enc_m_axi_bready  ),
        .axi_m_rready_o             ( enc_m_axi_rready  ),
        .axi_m_wdata_o              ( enc_m_axi_wdata   ),
        .axi_m_wid_o                (                   ),
        .axi_m_wlast_o              ( enc_m_axi_wlast   ),
        .axi_m_wstrb_o              ( enc_m_axi_wstrb   ),
        .axi_m_wvalid_o             ( enc_m_axi_wvalid  )
    );

//1-to-1 AXI MM interconnect
    axi_dwidth_converter_0  axi_mm_x (
        .s_axi_aresetn            ( rst_n             ),
        .s_axi_aclk               ( clk               ),
        .s_axi_awaddr             ( enc_m_axi_awaddr  ),
        .s_axi_awlen              ( enc_m_axi_awlen   ),
        .s_axi_awsize             ( enc_m_axi_awsize  ),
        .s_axi_awburst            ( enc_m_axi_awburst ),
        .s_axi_awlock             ( enc_m_axi_awlock  ),
        .s_axi_awcache            ( enc_m_axi_awcache ),
        .s_axi_awprot             ( enc_m_axi_awprot  ),
        .s_axi_awqos              ( enc_m_axi_awqos   ),
        .s_axi_awvalid            ( enc_m_axi_awvalid ),
        .s_axi_awready            ( enc_m_axi_awready ),
        .s_axi_wdata              ( enc_m_axi_wdata   ),
        .s_axi_wstrb              ( enc_m_axi_wstrb   ),
        .s_axi_wlast              ( enc_m_axi_wlast   ),
        .s_axi_wvalid             ( enc_m_axi_wvalid  ),
        .s_axi_wready             ( enc_m_axi_wready  ),
        .s_axi_bresp              ( enc_m_axi_bresp   ),
        .s_axi_bvalid             ( enc_m_axi_bvalid  ),
        .s_axi_bready             ( enc_m_axi_bready  ),
        .s_axi_araddr             ( enc_m_axi_araddr  ),
        .s_axi_arlen              ( enc_m_axi_arlen   ),
        .s_axi_arsize             ( enc_m_axi_arsize  ),
        .s_axi_arburst            ( enc_m_axi_arburst ),
        .s_axi_arlock             ( enc_m_axi_arlock  ),
        .s_axi_arcache            ( enc_m_axi_arcache ),
        .s_axi_arprot             ( enc_m_axi_arprot  ),
        .s_axi_arqos              ( enc_m_axi_arqos   ),
        .s_axi_arvalid            ( enc_m_axi_arvalid ),
        .s_axi_arready            ( enc_m_axi_arready ),
        .s_axi_rdata              ( enc_m_axi_rdata   ),
        .s_axi_rresp              ( enc_m_axi_rresp   ),
        .s_axi_rlast              ( enc_m_axi_rlast   ),
        .s_axi_rvalid             ( enc_m_axi_rvalid  ),
        .s_axi_rready             ( enc_m_axi_rready  ),

        .m_axi_awaddr             ( m_axi_snap_awaddr ),
        .m_axi_awlen              ( m_axi_snap_awlen  ),
        .m_axi_awsize             ( m_axi_snap_awsize ),
        .m_axi_awburst            ( m_axi_snap_awburst),
        .m_axi_awlock             ( m_axi_snap_awlock ),
        .m_axi_awcache            ( m_axi_snap_awcache),
        .m_axi_awprot             ( m_axi_snap_awprot ),
        .m_axi_awqos              ( m_axi_snap_awqos  ),
        .m_axi_awvalid            ( m_axi_snap_awvalid),
        .m_axi_awready            ( m_axi_snap_awready),
        .m_axi_wdata              ( m_axi_snap_wdata  ),
        .m_axi_wstrb              ( m_axi_snap_wstrb  ),
        .m_axi_wlast              ( m_axi_snap_wlast  ),
        .m_axi_wvalid             ( m_axi_snap_wvalid ),
        .m_axi_wready             ( m_axi_snap_wready ),
        .m_axi_bresp              ( m_axi_snap_bresp  ),
        .m_axi_bvalid             ( m_axi_snap_bvalid ),
        .m_axi_bready             ( m_axi_snap_bready ),
        .m_axi_araddr             ( m_axi_snap_araddr ),
        .m_axi_arlen              ( m_axi_snap_arlen  ),
        .m_axi_arsize             ( m_axi_snap_arsize ),
        .m_axi_arburst            ( m_axi_snap_arburst),
        .m_axi_arlock             ( m_axi_snap_arlock ),
        .m_axi_arcache            ( m_axi_snap_arcache),
        .m_axi_arprot             ( m_axi_snap_arprot ),
        .m_axi_arqos              ( m_axi_snap_arqos  ),
        .m_axi_arvalid            ( m_axi_snap_arvalid),
        .m_axi_arready            ( m_axi_snap_arready),
        .m_axi_rdata              ( m_axi_snap_rdata  ),
        .m_axi_rresp              ( m_axi_snap_rresp  ),
        .m_axi_rlast              ( m_axi_snap_rlast  ),
        .m_axi_rvalid             ( m_axi_snap_rvalid ),
        .m_axi_rready             ( m_axi_snap_rready )
        );

endmodule
