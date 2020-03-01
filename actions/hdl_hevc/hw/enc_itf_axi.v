//------------------------------------------------------------------------------
  //
  //  Filename       : enc_itf_axi.v
  //  Author         : Gu Chenhao
  //  Created        : 2019-12-26
  //  Description    : [logic] to [generate axi signals]
  //
//------------------------------------------------------------------------------

`include "defines_enc.vh"

module enc_itf_axi(
  // global
  clk                      ,
  rstn                     ,
  // ctl
  ctl_top_start_i          ,
  ctl_top_flg_irq_i        ,
  ctl_top_clr_irq_i        ,
  fdb_top_dat_status_run_o ,
  fdb_top_dat_status_irq_o ,
  // cfg_i
  cfg_dat_mod_run_i        ,
  cfg_siz_fra_x_i          ,
  cfg_siz_fra_y_i          ,
  cfg_ori_lu_adr_i         ,
  cfg_ori_ch_adr_i         ,
  cfg_ref_lu_adr_i         ,
  cfg_ref_ch_adr_i         ,
  cfg_rec_lu_adr_i         ,
  cfg_rec_ch_adr_i         ,
  cfg_bs_adr_i             ,
  cfg_dec_bs_len_i         ,
  cfg_enc_bs_len_o         ,
  // axi
  axi_m_arready_i          ,
  axi_m_awready_i          ,
  axi_m_bid_i              ,
  axi_m_bresp_i            ,
  axi_m_bvalid_i           ,
  axi_m_rdata_i            ,
  axi_m_rid_i              ,
  axi_m_rlast_i            ,
  axi_m_rresp_i            ,
  axi_m_rvalid_i           ,
  axi_m_wready_i           ,
  axi_m_araddr_o           ,
  axi_m_arburst_o          ,
  axi_m_arcache_o          ,
  axi_m_arid_o             ,
  axi_m_arlen_o            ,
  axi_m_arlock_o           ,
  axi_m_arprot_o           ,
  axi_m_arsize_o           ,
  axi_m_arvalid_o          ,
  axi_m_awaddr_o           ,
  axi_m_awburst_o          ,
  axi_m_awcache_o          ,
  axi_m_awid_o             ,
  axi_m_awlen_o            ,
  axi_m_awlock_o           ,
  axi_m_awprot_o           ,
  axi_m_awsize_o           ,
  axi_m_awvalid_o          ,
  axi_m_bready_o           ,
  axi_m_rready_o           ,
  axi_m_wdata_o            ,
  axi_m_wid_o              ,
  axi_m_wlast_o            ,
  axi_m_wstrb_o            ,
  axi_m_wvalid_o           ,
  // ext_rd
  ext_rd_req_ori_i         ,
  ext_rd_req_ref_i         ,
  ext_rd_pos_x_i           ,
  ext_rd_pos_y_i           ,
  ext_rd_len_x_i           ,
  ext_rd_len_y_i           ,
  ext_rd_chn_i             ,
  ext_rd_val_i             ,
  ext_rd_ack_o             ,
  ext_rd_dat_o             ,
  // ext wr
  ext_wr_req_i             ,
  ext_wr_pos_x_i           ,
  ext_wr_pos_y_i           ,
  ext_wr_len_x_i           ,
  ext_wr_len_y_i           ,
  ext_wr_chn_i             ,
  ext_wr_val_i             ,
  ext_wr_ack_o             ,
  ext_wr_dat_i             ,
  // dec, dat_o
  val_o                    ,
  ack_i                    ,
  dat_o                    ,
  lst_o                    ,
  // enc, dat_i
  val_i                    ,
  ack_o                    ,
  dat_i                    ,
  lst_i
);



//*** PARAMETER ****************************************************************
  // local
  localparam   AXI_ADR_WD                               = 64                             ;    // ADR -> address
  localparam   AXI_DAT_WD                               = 128                            ;    // DAT -> data
  localparam   AXI_LEN_WD                               = 4                              ;    // LEN -> length
  localparam   AXI_SIZ_WD                               = 3                              ;    // SIZ -> size
  localparam   AXI_STB_WD                               = AXI_DAT_WD / 8                 ;    // STB -> strobe
  localparam   AXI_PRO_WD                               = 3                              ;    // PRO -> prot
  localparam   AXI_CAC_WD                               = 4                              ;    // CAC -> cache
  localparam   AXI_LCK_WD                               = 2                              ;    // LCK -> lock
  localparam   AXI_BST_WD                               = 2                              ;    // BST -> burst
  localparam   AXI_RSP_WD                               = 2                              ;    // RSP -> response
  localparam   AXI_RID_WD                               = 4                              ;
  localparam   AXI_WID_WD                               = 4                              ;
  localparam   AXI_BID_WD                               = 4                              ;

  localparam   AXI_BST_LEN_MAX                          = 15                             ;    // BST -> burst; LEN -> length

  localparam   FSM_RD_WD                                = 2                              ;
    localparam RD_IDLE                                  = 0                              ;
    localparam RD_BS                                    = 1                              ;
    localparam RD_LU                                    = 2                              ;
    localparam RD_CH                                    = 3                              ;

  localparam   FSM_WR_WD                                = 2                              ;
    localparam WR_IDLE                                  = 0                              ;
    localparam WR_BS                                    = 1                              ;
    localparam WR_LU                                    = 2                              ;
    localparam WR_CH                                    = 3                              ;

  localparam   DATA_THR                                 = AXI_DAT_WD / 8                 ;
  localparam   DATA_THR_WD                              = `LOG2(DATA_THR) + 1            ;

  localparam   FIFO_DEC_BS_DAT_WD                       = AXI_DAT_WD                     ;
  localparam   FIFO_DEC_BS_STE_LEN                      = 256                            ;    // STE -> store; LEN -> length
  localparam   FIFO_DEC_BS_STE_LEN_WD                   = `LOG2(FIFO_DEC_BS_STE_LEN) + 1 ;
  localparam   FIFO_DEC_BS_SIZE                         = FIFO_DEC_BS_STE_LEN / DATA_THR ;    // TODO: to be determined later (not in v.2.0)
  localparam   FIFO_DEC_BS_SIZE_WD                      = `LOG2(FIFO_DEC_BS_SIZE)        ;

  localparam   FIFO_ENC_BS_DAT_WD                       = AXI_DAT_WD                     ;
  localparam   FIFO_ENC_BS_SIZE                         = 1024 / DATA_THR                ;    // TODO: to be determined later (not in v.2.0)
  localparam   FIFO_ENC_BS_SIZE_WD                      = `LOG2(FIFO_ENC_BS_SIZE)        ;
  localparam   FIFO_ENC_BS_DMP_LEN                      = 16                             ;    // DMP -> dump; LEN -> length
  localparam   FIFO_ENC_BS_DMP_LEN_WD                   = `LOG2(FIFO_ENC_BS_DMP_LEN) + 1 ;

  localparam   TRA_LEN_MAX                              = `SIZE_S_W_X * `SIZE_S_W_Y      ;    // TRA -> transfer
  localparam   TRA_LEN_WD                               = `LOG2(TRA_LEN_MAX) + 1         ;

//*** INPUT/OUTPUT *************************************************************

  // global
  input                                                 clk                              ;
  input                                                 rstn                             ;

  // ctl
  input                                                 ctl_top_start_i                  ;
  input      [`CTL_TOP_FLG_IRQ_WD             -1 :0]    ctl_top_flg_irq_i                ;
  input      [`CTL_TOP_FLG_IRQ_WD             -1 :0]    ctl_top_clr_irq_i                ;  
  output     [`CTL_TOP_FLG_RUN_WD             -1 :0]    fdb_top_dat_status_run_o         ; // indicates bs rd/wr isn't done
  output     [`CTL_TOP_FLG_IRQ_WD             -1 :0]    fdb_top_dat_status_irq_o         ;

  // cfg_i
  input      [`DATA_MOD_RUN_WD                -1 :0]    cfg_dat_mod_run_i                ;
  input      [`SIZE_FRA_X_WD                  -1 :0]    cfg_siz_fra_x_i                  ;
  input      [`SIZE_FRA_Y_WD                  -1 :0]    cfg_siz_fra_y_i                  ;
  input      [AXI_ADR_WD                      -1 :0]    cfg_ori_lu_adr_i                 ;
  input      [AXI_ADR_WD                      -1 :0]    cfg_ori_ch_adr_i                 ;
  input      [AXI_ADR_WD                      -1 :0]    cfg_ref_lu_adr_i                 ;
  input      [AXI_ADR_WD                      -1 :0]    cfg_ref_ch_adr_i                 ;
  input      [AXI_ADR_WD                      -1 :0]    cfg_rec_lu_adr_i                 ;
  input      [AXI_ADR_WD                      -1 :0]    cfg_rec_ch_adr_i                 ;
  input      [AXI_ADR_WD                      -1 :0]    cfg_bs_adr_i                     ;
  input      [32                              -1 :0]    cfg_dec_bs_len_i                 ;
  output     [32                              -1 :0]    cfg_enc_bs_len_o                 ;

  // axi
  input                                                 axi_m_arready_i                  ;
  input                                                 axi_m_awready_i                  ;
  input      [AXI_BID_WD                      -1 :0]    axi_m_bid_i                      ;
  input      [AXI_RSP_WD                      -1 :0]    axi_m_bresp_i                    ;
  input                                                 axi_m_bvalid_i                   ;
  input      [AXI_DAT_WD                      -1 :0]    axi_m_rdata_i                    ;
  input      [AXI_RID_WD                      -1 :0]    axi_m_rid_i                      ;
  input                                                 axi_m_rlast_i                    ;
  input      [AXI_RSP_WD                      -1 :0]    axi_m_rresp_i                    ;
  input                                                 axi_m_rvalid_i                   ;
  input                                                 axi_m_wready_i                   ;
  output     [AXI_ADR_WD                      -1 :0]    axi_m_araddr_o                   ;
  output     [AXI_BST_WD                      -1 :0]    axi_m_arburst_o                  ;
  output     [AXI_CAC_WD                      -1 :0]    axi_m_arcache_o                  ;
  output     [AXI_RID_WD                      -1 :0]    axi_m_arid_o                     ;
  output     [AXI_LEN_WD                      -1 :0]    axi_m_arlen_o                    ;
  output     [AXI_LCK_WD                      -1 :0]    axi_m_arlock_o                   ;
  output     [AXI_PRO_WD                      -1 :0]    axi_m_arprot_o                   ;
  output     [AXI_SIZ_WD                      -1 :0]    axi_m_arsize_o                   ;
  output                                                axi_m_arvalid_o                  ;
  output     [AXI_ADR_WD                      -1 :0]    axi_m_awaddr_o                   ;
  output     [AXI_BST_WD                      -1 :0]    axi_m_awburst_o                  ;
  output     [AXI_CAC_WD                      -1 :0]    axi_m_awcache_o                  ;
  output     [AXI_WID_WD                      -1 :0]    axi_m_awid_o                     ;
  output     [AXI_LEN_WD                      -1 :0]    axi_m_awlen_o                    ;
  output     [AXI_LCK_WD                      -1 :0]    axi_m_awlock_o                   ;
  output     [AXI_PRO_WD                      -1 :0]    axi_m_awprot_o                   ;
  output     [AXI_SIZ_WD                      -1 :0]    axi_m_awsize_o                   ;
  output                                                axi_m_awvalid_o                  ;
  output                                                axi_m_bready_o                   ;
  output                                                axi_m_rready_o                   ;
  output     [AXI_DAT_WD                      -1 :0]    axi_m_wdata_o                    ;
  output     [AXI_WID_WD                      -1 :0]    axi_m_wid_o                      ;
  output                                                axi_m_wlast_o                    ;
  output     [AXI_STB_WD                      -1 :0]    axi_m_wstrb_o                    ;
  output                                                axi_m_wvalid_o                   ;

  // ext_rd
  input                                                 ext_rd_req_ori_i                 ;
  input                                                 ext_rd_req_ref_i                 ;
  input      [`SIZE_FRA_X_WD                  -1 :0]    ext_rd_pos_x_i                   ;
  input      [`SIZE_FRA_Y_WD                  -1 :0]    ext_rd_pos_y_i                   ;
  input      [`SIZE_S_W_X                     -1 :0]    ext_rd_len_x_i                   ;
  input      [`SIZE_S_W_Y                     -1 :0]    ext_rd_len_y_i                   ;
  input      [`DATA_CHN_WD                    -1 :0]    ext_rd_chn_i                     ;
  input                                                 ext_rd_val_i                     ; // assume ext_rd_val_i is always high
  output                                                ext_rd_ack_o                     ;
  output     [`DATA_PXL_WD*DATA_THR           -1 :0]    ext_rd_dat_o                     ;

  // ext_wr
  input                                                 ext_wr_req_i                     ;
  input      [`SIZE_FRA_X_WD                  -1 :0]    ext_wr_pos_x_i                   ;
  input      [`SIZE_FRA_Y_WD                  -1 :0]    ext_wr_pos_y_i                   ;
  input      [`SIZE_LCU_WD+1                  -1 :0]    ext_wr_len_x_i                   ;
  input      [`SIZE_LCU_WD+1                  -1 :0]    ext_wr_len_y_i                   ;
  input      [`DATA_CHN_WD                    -1 :0]    ext_wr_chn_i                     ;
  input                                                 ext_wr_val_i                     ; // assume ext_wr_val_i is always high
  output                                                ext_wr_ack_o                     ;
  input      [`DATA_PXL_WD*DATA_THR           -1 :0]    ext_wr_dat_i                     ;

  // dec, dat_o
  output                                                val_o                            ;
  input                                                 ack_i                            ; // dat_o updated when (val_o && ack_i)
  output     [`DATA_BS_WD                     -1 :0]    dat_o                            ;
  output                                                lst_o                            ;

  // enc, dat_i
  input                                                 val_i                            ;
  output                                                ack_o                            ; // equal to !empty_fifo
  input      [`DATA_BS_WD                     -1 :0]    dat_i                            ;
  input                                                 lst_i                            ;

//*** WIRE/REG *****************************************************************
//--- RD -------------------------------
  // fsm
  reg        [FSM_WR_WD                        -1 :0]   cur_state_rd_r                   ;
  reg        [FSM_WR_WD                        -1 :0]   nxt_state_rd_w                   ;
  reg                                                   ext_rd_req_ori_flg_r             ;
  reg                                                   ext_rd_req_ref_flg_r             ;

  // fifo_dec_bs
  wire                                                  fifo_dec_bs_wr_val_i_w           ;
  wire       [FIFO_DEC_BS_DAT_WD               -1 :0]   fifo_dec_bs_wr_dat_i_w           ;
  wire                                                  fifo_dec_bs_rd_ack_i_w           ;
  wire       [FIFO_DEC_BS_DAT_WD               -1 :0]   fifo_dec_bs_rd_dat_o_w           ;
  wire                                                  fifo_dec_bs_rd_rdy_o_w           ;
  wire       [FIFO_DEC_BS_SIZE_WD+1            -1 :0]   fifo_dec_bs_wd_usd_o_w           ;

  reg        [`DATA_BS_WD                      -1 :0]   dec_bs_w                         ;

  // done flag
  wire                                                  axi_m_rd_done_flg_w              ;
  reg                                                   axi_m_ar_done_flg_w              ;
  reg                                                   axi_m_r_done_flg_w               ;
  reg                                                   dec_bs_val_o_done_flg_r          ;
  reg                                                   dec_bs_axi_rd_done_flg_r         ;
 
  // counter
  reg        [TRA_LEN_WD                       -1 :0]   cnt_axi_m_ar_r                   ;
  reg        [TRA_LEN_WD                       -1 :0]   cnt_axi_m_r_r                    ;
  reg        [32                               -1 :0]   cnt_dec_bs_axi_rd_r              ;
  reg        [32                               -1 :0]   cnt_dec_bs_val_o_r               ;
  reg        [DATA_THR_WD                      -1 :0]   cnt_dec_bs_byt_ena_r             ;

  // adr offset
  reg        [`SIZE_S_W_X_WD                   -1 :0]   adr_oft_x_ar_r                   ;
  reg        [`SIZE_S_W_Y_WD                   -1 :0]   adr_oft_y_ar_r                   ;
  reg        [`SIZE_S_W_X_WD                   -1 :0]   adr_oft_x_ar_w                   ;
  reg        [`SIZE_S_W_Y_WD                   -1 :0]   adr_oft_y_ar_w                   ;

  // axi
  reg        [AXI_ADR_WD                       -1 :0]   axi_m_araddr_bgn_r               ;
  reg        [AXI_ADR_WD                      -1 :0]    axi_m_araddr_o                   ;
  reg        [AXI_LEN_WD                      -1 :0]    axi_m_arlen_o                    ;

//--- WR -------------------------------
  // fsm
  reg        [FSM_WR_WD                        -1 :0]   cur_state_wr_r                   ;
  reg        [FSM_WR_WD                        -1 :0]   nxt_state_wr_w                   ;
  reg                                                   ext_wr_req_flg_r                 ;

  // fifo_enc_bs
  wire                                                  fifo_enc_bs_wr_val_i_w           ;
  wire       [FIFO_ENC_BS_DAT_WD               -1 :0]   fifo_enc_bs_wr_dat_i_w           ;
  wire                                                  fifo_enc_bs_wr_ful_i_w           ;
  wire                                                  fifo_enc_bs_rd_ack_i_w           ;
  wire       [FIFO_ENC_BS_DAT_WD               -1 :0]   fifo_enc_bs_rd_dat_o_w           ;
  wire                                                  fifo_enc_bs_rd_rdy_o_w           ;
  wire       [FIFO_ENC_BS_SIZE_WD+1            -1 :0]   fifo_enc_bs_wd_usd_o_w           ;
  wire                                                  fifo_enc_bs_rd_rdy_w             ;
  reg        [FIFO_ENC_BS_DMP_LEN_WD           -1 :0]   fifo_enc_bs_cnt_rd_val_r         ;

  wire       [AXI_DAT_WD                       -1 :0]   enc_bs_dat_w                     ;
  reg        [AXI_DAT_WD                       -1 :0]   enc_bs_dat_r                     ;

  // bs fnl val
  reg        [FIFO_ENC_BS_DMP_LEN_WD           -1 :0]   enc_bs_fnl_val_num_r             ;
  reg                                                   enc_bs_fnl_val_r                 ;
  reg        [FIFO_ENC_BS_DMP_LEN_WD           -1 :0]   cnt_enc_bs_fnl_val_r             ;

  // done flag
  wire                                                  axi_m_wr_done_flg_w              ;
  reg                                                   axi_m_aw_done_flg_w              ;
  reg                                                   axi_m_w_done_flg_w               ;
  reg                                                   enc_bs_val_i_done_flg_r          ;

  // counter
  reg        [TRA_LEN_WD                       -1 :0]   cnt_axi_m_aw_r                   ;
  reg        [TRA_LEN_WD                       -1 :0]   cnt_axi_m_w_r                    ;
  reg        [32                               -1 :0]   cnt_bs_axi_m_aw_r                ;
  reg        [32                               -1 :0]   cnt_bs_val_i_r                   ;
  reg        [DATA_THR_WD                      -1 :0]   cnt_enc_bs_byt_ena_r             ;

  // adr offset
  reg        [`SIZE_S_W_X_WD                   -1 :0]   adr_oft_x_aw_r                   ;
  reg        [`SIZE_S_W_Y_WD                   -1 :0]   adr_oft_y_aw_r                   ;
  reg        [`SIZE_S_W_X_WD                   -1 :0]   adr_oft_x_aw_w                   ;
  reg        [`SIZE_S_W_Y_WD                   -1 :0]   adr_oft_y_aw_w                   ;

  // axi
  reg        [AXI_ADR_WD                       -1 :0]   axi_m_awaddr_bgn_r               ;
  reg        [AXI_ADR_WD                       -1 :0]   axi_m_awaddr_o                   ;
  reg        [AXI_LEN_WD                       -1 :0]   axi_m_awlen_o                    ;
  reg                                                   axi_m_wlast_o                    ;
  reg        [AXI_DAT_WD                       -1 :0]   axi_m_wdata_o                    ;

//--- GLOABAL ---------------------------
  wire                                                  done_flg_w                       ;
  reg                                                   done_flg_r                       ;
  reg                                                   irq_r                            ;

//*** AXI RD *******************************************************************
//--- fsm -------------------------------
  // cur_state_rd_r
  always @( posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      cur_state_rd_r <= 0 ;
    end
    else begin
      cur_state_rd_r <= nxt_state_rd_w ;
    end
  end

  // nxt_state_rd_w
  always @(*) begin
                                                         nxt_state_rd_w = RD_IDLE     ;
    case( cur_state_rd_r )
    `ifdef KNOB_HAS_E_D
      RD_IDLE : if ( !fifo_dec_bs_rd_rdy_o_w && !dec_bs_axi_rd_done_flg_r ) begin
                                                         nxt_state_rd_w = RD_BS       ;
                end
                else begin
                  if( ext_rd_req_ori_flg_r || ext_rd_req_ref_flg_r ) begin
                    if (ext_rd_chn_i == `DATA_CHN_Y)     nxt_state_rd_w = RD_LU       ;
                    else                                 nxt_state_rd_w = RD_CH       ;
                  end
                  else begin
                                                         nxt_state_rd_w = RD_IDLE     ;
                  end
                end
    `else
      RD_IDLE : if( ext_rd_req_ori_flg_r || ext_rd_req_ref_flg_r ) begin
                  if (ext_rd_chn_i == `DATA_CHN_Y)       nxt_state_rd_w = RD_LU       ;
                  else                                   nxt_state_rd_w = RD_CH       ;
                end
                else begin
                                                         nxt_state_rd_w = RD_IDLE     ;
                end
    `endif
      RD_BS   : if ( axi_m_rd_done_flg_w )               nxt_state_rd_w = RD_IDLE     ;
                else                                     nxt_state_rd_w = RD_BS       ;
      RD_LU   : if ( axi_m_rd_done_flg_w )               nxt_state_rd_w = RD_IDLE     ;
                 else                                    nxt_state_rd_w = RD_LU       ;
      RD_CH   : if ( axi_m_rd_done_flg_w )               nxt_state_rd_w = RD_IDLE     ;
                else                                     nxt_state_rd_w = RD_CH       ;
    endcase
  end

  // ext_rd_req_ori_flg_r
  always @( posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      ext_rd_req_ori_flg_r <= 0 ;
    end
    else begin
      if ( ext_rd_req_ori_i ) begin
        ext_rd_req_ori_flg_r <= 1 ;
      end
      else begin
        if (  cur_state_rd_r == RD_IDLE && nxt_state_rd_w == RD_LU
           || cur_state_rd_r == RD_IDLE && nxt_state_rd_w == RD_CH )
          ext_rd_req_ori_flg_r <= 0 ;
      end
    end
  end

  // ext_rd_req_ref_flg_r
  always @( posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      ext_rd_req_ref_flg_r <= 0 ;
    end
    else begin
      if ( ext_rd_req_ref_i ) begin
        ext_rd_req_ref_flg_r <= 1 ;
      end
      else begin
        if (  cur_state_rd_r == RD_IDLE && nxt_state_rd_w == RD_LU
           || cur_state_rd_r == RD_IDLE && nxt_state_rd_w == RD_CH )
          ext_rd_req_ref_flg_r <= 0 ;
      end
    end
  end

//--- FIFO_DEC_BS -----------------------
  // fifo_dec_bs_*_w
  assign fifo_dec_bs_wr_val_i_w = axi_m_rvalid_i && axi_m_rready_o && cur_state_rd_r == RD_BS ;
  assign fifo_dec_bs_wr_dat_i_w = axi_m_rdata_i  ;
  assign fifo_dec_bs_rd_ack_i_w = dec_bs_val_o_done_flg_r ? fifo_dec_bs_rd_rdy_o_w : val_o && ack_i && cnt_dec_bs_byt_ena_r == DATA_THR - 1 ;

  // begin of instantiation
  fifo_sc_ew_ack_reg_based #(
    .SIZE        ( FIFO_DEC_BS_SIZE        ),
    .DATA_WD     ( FIFO_DEC_BS_DAT_WD      )
  ) fifo_dec_bs (
    // global
    .clk         ( clk                     ),
    .rstn        ( rstn                    ),
    // write
    .wr_val_i    ( fifo_dec_bs_wr_val_i_w ),
    .wr_dat_i    ( fifo_dec_bs_wr_dat_i_w ),
    .wr_ful_o    ( /* UNUSED */            ),
    // read
    .rd_rdy_o    ( fifo_dec_bs_rd_rdy_o_w ),
    .rd_ack_i    ( fifo_dec_bs_rd_ack_i_w ),
    .rd_dat_o    ( fifo_dec_bs_rd_dat_o_w ),
    // common
    .wd_usd_o    ( fifo_dec_bs_wd_usd_o_w )
  );
  // end of instantiation

  // !!! only AXI_DAT_WD equal to 128 is supported
  // !!! assume axi_m_rdata_i is LITTLE Endian
  // dec_bs_w
  always @(*) begin
          dec_bs_w = 0 ;
    case ( cnt_dec_bs_byt_ena_r )
      0 : dec_bs_w = fifo_dec_bs_rd_dat_o_w[ 1*`DATA_BS_WD-1: 0*`DATA_BS_WD] ;
      1 : dec_bs_w = fifo_dec_bs_rd_dat_o_w[ 2*`DATA_BS_WD-1: 1*`DATA_BS_WD] ;
      2 : dec_bs_w = fifo_dec_bs_rd_dat_o_w[ 3*`DATA_BS_WD-1: 2*`DATA_BS_WD] ;
      3 : dec_bs_w = fifo_dec_bs_rd_dat_o_w[ 4*`DATA_BS_WD-1: 3*`DATA_BS_WD] ;
      4 : dec_bs_w = fifo_dec_bs_rd_dat_o_w[ 5*`DATA_BS_WD-1: 4*`DATA_BS_WD] ;
      5 : dec_bs_w = fifo_dec_bs_rd_dat_o_w[ 6*`DATA_BS_WD-1: 5*`DATA_BS_WD] ;
      6 : dec_bs_w = fifo_dec_bs_rd_dat_o_w[ 7*`DATA_BS_WD-1: 6*`DATA_BS_WD] ;
      7 : dec_bs_w = fifo_dec_bs_rd_dat_o_w[ 8*`DATA_BS_WD-1: 7*`DATA_BS_WD] ;
      8 : dec_bs_w = fifo_dec_bs_rd_dat_o_w[ 9*`DATA_BS_WD-1: 8*`DATA_BS_WD] ;
      9 : dec_bs_w = fifo_dec_bs_rd_dat_o_w[10*`DATA_BS_WD-1: 9*`DATA_BS_WD] ;
      10: dec_bs_w = fifo_dec_bs_rd_dat_o_w[11*`DATA_BS_WD-1:10*`DATA_BS_WD] ;
      11: dec_bs_w = fifo_dec_bs_rd_dat_o_w[12*`DATA_BS_WD-1:11*`DATA_BS_WD] ;
      12: dec_bs_w = fifo_dec_bs_rd_dat_o_w[13*`DATA_BS_WD-1:12*`DATA_BS_WD] ;
      13: dec_bs_w = fifo_dec_bs_rd_dat_o_w[14*`DATA_BS_WD-1:13*`DATA_BS_WD] ;
      14: dec_bs_w = fifo_dec_bs_rd_dat_o_w[15*`DATA_BS_WD-1:14*`DATA_BS_WD] ;
      15: dec_bs_w = fifo_dec_bs_rd_dat_o_w[16*`DATA_BS_WD-1:15*`DATA_BS_WD] ;
    endcase
  end

//--- DONE FLG --------------------------
  // axi_m_rd_done_flg_w
  assign axi_m_rd_done_flg_w = axi_m_r_done_flg_w ;

  // axi_m_ar_done_flg_w
  always @ (*) begin
               axi_m_ar_done_flg_w = 0 ;
    case ( cur_state_rd_r )
      RD_BS  : axi_m_ar_done_flg_w = cnt_axi_m_ar_r >= FIFO_DEC_BS_STE_LEN                         ;
      RD_LU  : axi_m_ar_done_flg_w = cnt_axi_m_ar_r >= (ext_rd_len_x_i+1) * (ext_rd_len_y_i+1)     ;
      RD_CH  : axi_m_ar_done_flg_w = cnt_axi_m_ar_r >= (ext_rd_len_x_i+1) * (ext_rd_len_y_i+1) * 2 ;
    endcase
  end

  // axi_m_r_done_flg_w
  always @ (*) begin
               axi_m_r_done_flg_w  = 0 ;
    case ( cur_state_rd_r )
      RD_BS  : axi_m_r_done_flg_w  = cnt_axi_m_r_r  >= FIFO_DEC_BS_STE_LEN                 ;
      RD_LU  : axi_m_r_done_flg_w  = cnt_axi_m_r_r  >= (ext_rd_len_x_i+1) * (ext_rd_len_y_i+1)     ;
      RD_CH  : axi_m_r_done_flg_w  = cnt_axi_m_r_r  >= (ext_rd_len_x_i+1) * (ext_rd_len_y_i+1) * 2 ;
    endcase
  end

  // dec_bs_val_o_done_flg_r
  always @( posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      dec_bs_val_o_done_flg_r <= 0 ;
    end
    else begin
  `ifdef KNOB_HAS_E_D
      if ( ctl_top_start_i && cfg_dat_mod_run_i == `DATA_MOD_RUN_DEC ) begin
        dec_bs_val_o_done_flg_r <= 0 ;
      end
      else begin
        if ( cnt_dec_bs_val_o_r == cfg_dec_bs_len_i - 1 && val_o && ack_i )
          dec_bs_val_o_done_flg_r <= 1 ;
      end
  `else
      dec_bs_val_o_done_flg_r <= 1 ;
  `endif
    end
  end

  // dec_bs_axi_rd_done_flg_r
  always @( posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      dec_bs_axi_rd_done_flg_r <= 1 ;
    end
    else begin
  `ifdef KNOB_HAS_E_D
      if ( ctl_top_start_i && cfg_dat_mod_run_i == `DATA_MOD_RUN_DEC ) begin
        dec_bs_axi_rd_done_flg_r <= 0 ;
      end
      else begin
        if ( cnt_dec_bs_axi_rd_r >= cfg_dec_bs_len_i )
          dec_bs_axi_rd_done_flg_r <= 1 ;
      end
  `else
      dec_bs_axi_rd_done_flg_r <= 1 ;
  `endif
    end
  end

//--- COUNTER ---------------------------
  // cnt_axi_m_ar_r
  always @( posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      cnt_axi_m_ar_r <= 0 ;
    end
    else begin
      if ( cur_state_rd_r != RD_IDLE && nxt_state_rd_w == RD_IDLE ) begin
        cnt_axi_m_ar_r <= 0 ;
      end
      else begin
        if ( axi_m_arvalid_o && axi_m_arready_i )
          cnt_axi_m_ar_r <= cnt_axi_m_ar_r + (DATA_THR*(axi_m_arlen_o+1)) ;
      end
    end
  end

  // cnt_axi_m_r_r
  always @( posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      cnt_axi_m_r_r <= 0 ;
    end
    else begin
      if ( cur_state_rd_r != RD_IDLE && nxt_state_rd_w == RD_IDLE ) begin
        cnt_axi_m_r_r <= 0 ;
      end
      else begin
        if ( axi_m_rvalid_i && axi_m_rready_o )
          cnt_axi_m_r_r <= cnt_axi_m_r_r + DATA_THR ;
      end
    end
  end

  // cnt_dec_bs_axi_rd_r
  always @( posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      cnt_dec_bs_axi_rd_r <= 0 ;
    end
    else begin
      if ( ctl_top_start_i ) begin
        cnt_dec_bs_axi_rd_r <= 0 ;
      end
      else begin
        if ( cur_state_rd_r == RD_BS && axi_m_arvalid_o && axi_m_arready_i )
          cnt_dec_bs_axi_rd_r <= cnt_dec_bs_axi_rd_r + (DATA_THR*(axi_m_arlen_o+1)) ;
      end
    end
  end

  // cnt_dec_bs_val_o_r
  always @( posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      cnt_dec_bs_val_o_r <= 0 ;
    end
    else begin
      if ( ctl_top_start_i ) begin
        cnt_dec_bs_val_o_r <= 0 ;
      end
      else begin
        if ( val_o && ack_i )
          cnt_dec_bs_val_o_r <= cnt_dec_bs_val_o_r + 1 ;
      end
    end
  end

  // cnt_dec_byte_ena_r
  always @( posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      cnt_dec_bs_byt_ena_r <= 0 ;
    end
    else begin
      if ( cur_state_rd_r == RD_IDLE && nxt_state_rd_w == RD_BS ) begin
        cnt_dec_bs_byt_ena_r <= 0 ;
      end
      else begin
        if ( val_o && ack_i ) begin
          if ( cnt_dec_bs_byt_ena_r == DATA_THR - 1 )
            cnt_dec_bs_byt_ena_r <= 0 ;
          else
            cnt_dec_bs_byt_ena_r <= cnt_dec_bs_byt_ena_r + 1 ;
        end
      end
    end
  end

//--- ADR OFFSET ------------------------
  // adr_oft_*_ar_r
  always @ ( posedge clk or negedge rstn ) begin
    if ( !rstn ) begin
      adr_oft_x_ar_r <= 0 ;
      adr_oft_y_ar_r <= 0 ;
    end
    else begin
      if ( cur_state_rd_r == RD_IDLE && nxt_state_rd_w == RD_LU
        || cur_state_rd_r == RD_IDLE && nxt_state_rd_w == RD_CH ) begin
        adr_oft_x_ar_r <= 0 ;
        adr_oft_y_ar_r <= 0 ;
      end
      else if( cur_state_rd_r != RD_BS && axi_m_arvalid_o && axi_m_arready_i ) begin
        adr_oft_x_ar_r <= adr_oft_x_ar_w ;
        adr_oft_y_ar_r <= adr_oft_y_ar_w ;
      end
    end
  end

  // adr_oft_*_aw_w
  always @ ( * ) begin
                adr_oft_x_ar_w = 0 ;
                adr_oft_y_ar_w = 0 ;
    case ( cur_state_rd_r )
      RD_LU : if ( adr_oft_x_ar_r == ext_rd_len_x_i + 1 - DATA_THR*(axi_m_arlen_o+1) ) begin
                adr_oft_x_ar_w = 0 ;
                adr_oft_y_ar_w = adr_oft_y_ar_r + 1 ;
              end
              else begin
                adr_oft_x_ar_w = adr_oft_x_ar_r + DATA_THR*(axi_m_arlen_o+1) ;
              end
      RD_CH : if ( adr_oft_x_ar_r == ext_rd_len_x_i + 1 - DATA_THR/2*(axi_m_arlen_o+1) ) begin
                adr_oft_x_ar_w = 0 ;
                adr_oft_y_ar_w = adr_oft_y_ar_r + 1 ;
              end
              else begin
                adr_oft_x_ar_w = adr_oft_x_ar_r + DATA_THR/2*(axi_m_arlen_o+1) ;
              end
    endcase
  end


//--- AXI INTERFACE ---------------------
  // axi_m_arlen_o
  always @ (*) begin
                    axi_m_arlen_o = 0 ;
    case ( cur_state_rd_r )
      RD_BS   :     axi_m_arlen_o = FIFO_DEC_BS_STE_LEN/DATA_THR - 1 <= AXI_BST_LEN_MAX
                                  ? FIFO_DEC_BS_STE_LEN/DATA_THR - 1
                                  : AXI_BST_LEN_MAX ;
      RD_LU   : if ( adr_oft_x_ar_r != 0 ) begin
                    axi_m_arlen_o = (ext_rd_len_x_i+1-adr_oft_x_ar_r) / DATA_THR - 1;
                end
                else begin
                  if ( ((4096-{1'b0,axi_m_araddr_o[11:0]}) < ext_rd_len_x_i + 1) && ((4096-{1'b0,axi_m_araddr_o[11:0]}) > 0) )
                    axi_m_arlen_o = ((4096-{1'b0,axi_m_araddr_o[11:0]})/DATA_THR) - 1 ;
                  else
                    axi_m_arlen_o = (ext_rd_len_x_i+1)/DATA_THR - 1;
                end
      RD_CH   : if ( adr_oft_x_ar_r != 0 ) begin
                    axi_m_arlen_o = (ext_rd_len_x_i+1-adr_oft_x_ar_r)*2 / DATA_THR - 1;
                end
                else begin
                  if ( ((4096-{1'b0,axi_m_araddr_o[11:0]}) < (ext_rd_len_x_i+1)*2) && ((4096-{1'b0,axi_m_araddr_o[11:0]}) > 0) )
                    axi_m_arlen_o = ((4096-{1'b0,axi_m_araddr_o[11:0]})/DATA_THR) - 1 ;
                  else
                    axi_m_arlen_o = (ext_rd_len_x_i+1)*2/DATA_THR - 1;
                end
    endcase
  end

  // axi_m_araddr_bgn_r
  always @( posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      axi_m_araddr_bgn_r <= 0 ;
    end
    else begin
      if ( cur_state_rd_r == RD_IDLE && nxt_state_rd_w != RD_IDLE ) begin
        case ( nxt_state_rd_w )
          RD_BS : axi_m_araddr_bgn_r <= cfg_bs_adr_i ;
          RD_LU : axi_m_araddr_bgn_r <= ext_rd_req_ori_flg_r ? cfg_ori_lu_adr_i : cfg_ref_lu_adr_i ;
          RD_CH : axi_m_araddr_bgn_r <= ext_rd_req_ori_flg_r ? cfg_ori_ch_adr_i : cfg_ref_ch_adr_i ;
        endcase
      end
    end
  end

  // axi_m_araddr_o
  always @(*) begin
              axi_m_araddr_o = 0 ;
    case ( cur_state_rd_r )
      RD_BS : axi_m_araddr_o = axi_m_araddr_bgn_r +  cnt_dec_bs_axi_rd_r ;
      RD_LU : axi_m_araddr_o = axi_m_araddr_bgn_r + (ext_rd_pos_y_i+adr_oft_y_ar_r)*(cfg_siz_fra_x_i+1)
                                                  +  ext_rd_pos_x_i
                                                  +  adr_oft_x_ar_r ;
      RD_CH : axi_m_araddr_o = axi_m_araddr_bgn_r + (ext_rd_pos_y_i+adr_oft_y_ar_r)*(cfg_siz_fra_x_i+1)/2*2
                                                  +  ext_rd_pos_x_i*2
                                                  +  adr_oft_x_ar_r*2 ;
    endcase
  end

  // axi_m_arvalid_o
  assign axi_m_arvalid_o =  (cur_state_rd_r == RD_BS || cur_state_rd_r == RD_LU || cur_state_rd_r == RD_CH)
                         && !axi_m_ar_done_flg_w   ;

  // axi_m_rready_o
  assign axi_m_rready_o  = 1 ;

  // axi_m_*_o
  assign axi_m_arburst_o = 1 ;
  assign axi_m_arcache_o = 0 ;
  assign axi_m_arid_o    = 0 ;
  assign axi_m_arlock_o  = 0 ;
  assign axi_m_arprot_o  = 0 ;
  assign axi_m_arsize_o  = 4 ;

//--- EXT RD ----------------------------
  // ext_rd_ack_o
  assign ext_rd_ack_o = cur_state_rd_r != RD_BS && axi_m_rvalid_i && axi_m_rready_o ;

  // ext_rd_dat_o 
  assign ext_rd_dat_o = { axi_m_rdata_i[ 1*`DATA_PXL_WD-1: 0*`DATA_PXL_WD],
                          axi_m_rdata_i[ 2*`DATA_PXL_WD-1: 1*`DATA_PXL_WD],
                          axi_m_rdata_i[ 3*`DATA_PXL_WD-1: 2*`DATA_PXL_WD],
                          axi_m_rdata_i[ 4*`DATA_PXL_WD-1: 3*`DATA_PXL_WD],
                          axi_m_rdata_i[ 5*`DATA_PXL_WD-1: 4*`DATA_PXL_WD],
                          axi_m_rdata_i[ 6*`DATA_PXL_WD-1: 5*`DATA_PXL_WD],
                          axi_m_rdata_i[ 7*`DATA_PXL_WD-1: 6*`DATA_PXL_WD],
                          axi_m_rdata_i[ 8*`DATA_PXL_WD-1: 7*`DATA_PXL_WD],
                          axi_m_rdata_i[ 9*`DATA_PXL_WD-1: 8*`DATA_PXL_WD],
                          axi_m_rdata_i[10*`DATA_PXL_WD-1: 9*`DATA_PXL_WD],
                          axi_m_rdata_i[11*`DATA_PXL_WD-1:10*`DATA_PXL_WD],
                          axi_m_rdata_i[12*`DATA_PXL_WD-1:11*`DATA_PXL_WD],
                          axi_m_rdata_i[13*`DATA_PXL_WD-1:12*`DATA_PXL_WD],
                          axi_m_rdata_i[14*`DATA_PXL_WD-1:13*`DATA_PXL_WD],
                          axi_m_rdata_i[15*`DATA_PXL_WD-1:14*`DATA_PXL_WD],
                          axi_m_rdata_i[16*`DATA_PXL_WD-1:15*`DATA_PXL_WD] } ;

//--- DEC BS ----------------------------
  // val_o
  assign val_o = fifo_dec_bs_rd_rdy_o_w && !dec_bs_val_o_done_flg_r ;

  // dat_o
  assign dat_o = dec_bs_w ;

  // lst_o
  assign lst_o = cnt_dec_bs_axi_rd_r == cfg_dec_bs_len_i - 1 && val_o && ack_i ;

//*** AXI WR *******************************************************************
//--- fsm -------------------------------
  // cur_state_wr_r
  always @( posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      cur_state_wr_r <= 0 ;
    end
    else begin
      cur_state_wr_r <= nxt_state_wr_w ;
    end
  end

  // nxt_state_wr_w
  always @(*) begin
                                                     nxt_state_wr_w = WR_IDLE ;
    case( cur_state_wr_r )
      WR_IDLE : if( fifo_enc_bs_rd_rdy_w ) begin     nxt_state_wr_w = WR_BS   ;
                end
                else begin
                  if( ext_wr_req_flg_r ) begin
                    if (ext_wr_chn_i == `DATA_CHN_Y) nxt_state_wr_w = WR_LU   ;
                    else                             nxt_state_wr_w = WR_CH   ;
                  end
                  else begin                         nxt_state_wr_w = WR_IDLE ;
                  end
                end
      WR_BS   : if ( axi_m_wr_done_flg_w )           nxt_state_wr_w = WR_IDLE ;
                else                                 nxt_state_wr_w = WR_BS   ;
      WR_LU   : if ( axi_m_wr_done_flg_w )           nxt_state_wr_w = WR_IDLE ;
                 else                                nxt_state_wr_w = WR_LU   ;
      WR_CH   : if ( axi_m_wr_done_flg_w )           nxt_state_wr_w = WR_IDLE ;
                else                                 nxt_state_wr_w = WR_CH   ;
    endcase
  end

  // ext_wr_req_flg_r
  always @( posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      ext_wr_req_flg_r <= 0 ;
    end
    else begin
      if ( ext_wr_req_i ) begin
        ext_wr_req_flg_r <= 1 ;
      end
      else begin
        if (  cur_state_wr_r == WR_IDLE && nxt_state_wr_w == WR_LU
           || cur_state_wr_r == WR_IDLE && nxt_state_wr_w == WR_CH )
          ext_wr_req_flg_r <= 0 ;
      end
    end
  end

//--- FIFO_ENC_BS -----------------------
  // fifo_enc_bs_*_w
  assign fifo_enc_bs_rd_rdy_w   =     fifo_enc_bs_wd_usd_o_w >= FIFO_ENC_BS_DMP_LEN/DATA_THR - 1
                                  &&  fifo_enc_bs_rd_rdy_o_w ;
  assign fifo_enc_bs_wr_val_i_w =    (cnt_enc_bs_byt_ena_r == DATA_THR - 1)
                                  && (val_i && ack_o || enc_bs_fnl_val_r) ;
  assign fifo_enc_bs_wr_dat_i_w =     enc_bs_dat_w ;
  assign fifo_enc_bs_rd_ack_i_w =     cur_state_wr_r == WR_BS && axi_m_wvalid_o && axi_m_wready_i ;

  // begin of instantiation
  fifo_sc_ew_ack_reg_based #(
    .SIZE        ( FIFO_ENC_BS_SIZE        ),
    .DATA_WD     ( FIFO_ENC_BS_DAT_WD      )
  ) fifo_enc_bs (
    // global
    .clk         ( clk                     ),
    .rstn        ( rstn                    ),
    // write
    .wr_val_i    ( fifo_enc_bs_wr_val_i_w  ),
    .wr_dat_i    ( fifo_enc_bs_wr_dat_i_w  ),
    .wr_ful_o    ( fifo_enc_bs_wr_ful_i_w  ),
    // read
    .rd_rdy_o    ( fifo_enc_bs_rd_rdy_o_w  ),
    .rd_ack_i    ( fifo_enc_bs_rd_ack_i_w  ),
    .rd_dat_o    ( fifo_enc_bs_rd_dat_o_w  ),
    // common
    .wd_usd_o    ( fifo_enc_bs_wd_usd_o_w  )
  );
  // end of instantiation

  // !!! assume axi_m_wdata_o is LITTLE Endian
  // enc_bs_dat_w
  assign enc_bs_dat_w = {dat_i, enc_bs_dat_r[16*`DATA_BS_WD-1:1*`DATA_BS_WD]} ;

  // enc_bs_dat_r
  always @( posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      enc_bs_dat_r <= 0 ;
    end
    else begin
      if ( val_i && ack_o || enc_bs_fnl_val_r )
        enc_bs_dat_r <= enc_bs_dat_w ;
    end
  end

//--- DONE FLG --------------------------
  // axi_m_wr_done_flg_w
  assign axi_m_wr_done_flg_w = axi_m_aw_done_flg_w && axi_m_w_done_flg_w ;

  // axi_m_aw_done_flg_w
  always @ (*) begin
               axi_m_aw_done_flg_w = 0 ;
    case ( cur_state_wr_r )
      WR_BS  : axi_m_aw_done_flg_w = cnt_axi_m_aw_r >= FIFO_ENC_BS_DMP_LEN                         ;
      WR_LU  : axi_m_aw_done_flg_w = cnt_axi_m_aw_r >= (ext_wr_len_x_i+1) * (ext_wr_len_y_i+1)     ;
      WR_CH  : axi_m_aw_done_flg_w = cnt_axi_m_aw_r >= (ext_wr_len_x_i+1) * (ext_wr_len_y_i+1) * 2 ;
    endcase
  end

  // axi_m_w_done_flg_w
  always @ (*) begin
               axi_m_w_done_flg_w  = 0 ;
    case ( cur_state_wr_r )
      WR_BS  : axi_m_w_done_flg_w  = cnt_axi_m_w_r  >= FIFO_ENC_BS_DMP_LEN                         ;
      WR_LU  : axi_m_w_done_flg_w  = cnt_axi_m_w_r  >= (ext_wr_len_x_i+1) * (ext_wr_len_y_i+1)     ;
      WR_CH  : axi_m_w_done_flg_w  = cnt_axi_m_w_r  >= (ext_wr_len_x_i+1) * (ext_wr_len_y_i+1) * 2 ;
    endcase
  end

  // enc_bs_val_i_done_flg_r
  always @( posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      enc_bs_val_i_done_flg_r <= 0 ;
    end
    else begin
      if ( ctl_top_start_i && cfg_dat_mod_run_i == `DATA_MOD_RUN_ENC ) begin
        enc_bs_val_i_done_flg_r <= 0 ;
      end
      else begin
        if ( cnt_enc_bs_fnl_val_r == enc_bs_fnl_val_num_r - 1 && enc_bs_fnl_val_r )
          enc_bs_val_i_done_flg_r <= 1 ;
      end
    end
  end

//--- COUNTER ---------------------------
  // cnt_axi_m_aw_r
  always @( posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      cnt_axi_m_aw_r <= 0 ;
    end
    else begin
      if ( cur_state_wr_r != WR_IDLE && nxt_state_wr_w == WR_IDLE ) begin
        cnt_axi_m_aw_r <= 0 ;
      end
      else begin
        if ( axi_m_awvalid_o && axi_m_awready_i )
          cnt_axi_m_aw_r <= cnt_axi_m_aw_r + (DATA_THR*(axi_m_awlen_o+1)) ;
      end
    end
  end

  // cnt_axi_m_w_r
  always @( posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      cnt_axi_m_w_r <= 0 ;
    end
    else begin
      if ( cur_state_wr_r != WR_IDLE && nxt_state_wr_w == WR_IDLE ) begin
        cnt_axi_m_w_r <= 0 ;
      end
      else begin
        if ( axi_m_wvalid_o && axi_m_wready_i )
          cnt_axi_m_w_r <= cnt_axi_m_w_r + DATA_THR ;
      end
    end
  end

  // cnt_bs_axi_m_aw_r
  always @( posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      cnt_bs_axi_m_aw_r <= 0 ;
    end
    else begin
      if ( ctl_top_start_i ) begin
        cnt_bs_axi_m_aw_r <= 0 ;
      end
      else begin
        if ( cur_state_wr_r == WR_BS && axi_m_awvalid_o && axi_m_awready_i )
          cnt_bs_axi_m_aw_r <= cnt_bs_axi_m_aw_r + (DATA_THR*(axi_m_awlen_o+1)) ;
      end
    end
  end

  // cnt_bs_val_i_r
  always @( posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      cnt_bs_val_i_r <= 0 ;
    end
    else begin
      if ( ctl_top_start_i ) begin
        cnt_bs_val_i_r <= 0 ;
      end
      else begin
        if ( val_i && ack_o )
          cnt_bs_val_i_r <= cnt_bs_val_i_r + 1 ;
      end
    end
  end

  // cnt_enc_bs_byt_ena_r
  always @( posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      cnt_enc_bs_byt_ena_r <= 0 ;
    end
    else begin
      if ( ctl_top_start_i ) begin
        cnt_enc_bs_byt_ena_r <= 0 ;
      end
      else begin
        if ( val_i && ack_o || enc_bs_fnl_val_r ) begin
          if ( cnt_enc_bs_byt_ena_r == DATA_THR - 1 )
            cnt_enc_bs_byt_ena_r <= 0 ;
          else
            cnt_enc_bs_byt_ena_r <= cnt_enc_bs_byt_ena_r + 1 ;
        end
      end
    end
  end

//--- BS FNL VAL ------------------------
  always @(posedge clk or negedge rstn) begin
    if( !rstn ) begin
      enc_bs_fnl_val_num_r <= 0;
    end
    else begin
      if ( ctl_top_start_i && cfg_dat_mod_run_i ==` DATA_MOD_RUN_ENC )
        enc_bs_fnl_val_num_r <= 0 ;
      else
        if ( lst_i && val_i && ack_o ) begin
          enc_bs_fnl_val_num_r <= FIFO_ENC_BS_DMP_LEN - (cnt_bs_val_i_r + 1)%FIFO_ENC_BS_DMP_LEN ;
      end
    end
  end

  always @(posedge clk or negedge rstn) begin
    if( !rstn ) begin
      enc_bs_fnl_val_r <= 0;
    end
    else begin
      if ( lst_i && val_i && ack_o )
          enc_bs_fnl_val_r <= 1;
      else
        if ( cnt_enc_bs_fnl_val_r == enc_bs_fnl_val_num_r - 1 )
          enc_bs_fnl_val_r <= 0;
    end
  end

  always @(posedge clk or negedge rstn) begin
    if( !rstn ) begin
      cnt_enc_bs_fnl_val_r <= 0 ;
    end
    else begin
      if ( ctl_top_start_i && cfg_dat_mod_run_i == `DATA_MOD_RUN_ENC )
        cnt_enc_bs_fnl_val_r <= 0 ;
      else
        if ( enc_bs_fnl_val_r )
          cnt_enc_bs_fnl_val_r <= cnt_enc_bs_fnl_val_r + 1;
    end
  end

//--- ADR OFFSET ------------------------
  // adr_oft_*_aw_r
  always @ ( posedge clk or negedge rstn ) begin
    if ( !rstn ) begin
      adr_oft_x_aw_r <= 0 ;
      adr_oft_y_aw_r <= 0 ;
    end
    else begin
      if ( cur_state_wr_r == WR_IDLE && nxt_state_wr_w == WR_LU
        || cur_state_wr_r == WR_IDLE && nxt_state_wr_w == WR_CH ) begin
        adr_oft_x_aw_r <= 0 ;
        adr_oft_y_aw_r <= 0 ;
      end
      else if( cur_state_wr_r != WR_BS && axi_m_awvalid_o && axi_m_awready_i ) begin
        adr_oft_x_aw_r <= adr_oft_x_aw_w ;
        adr_oft_y_aw_r <= adr_oft_y_aw_w ;
      end
    end
  end

  // adr_oft_*_aw_w
  always @ ( * ) begin
                adr_oft_x_aw_w = 0 ;
                adr_oft_y_aw_w = 0 ;
    case ( cur_state_wr_r )
      WR_LU : if ( adr_oft_x_aw_r == ext_wr_len_x_i + 1 - DATA_THR*(axi_m_awlen_o+1) ) begin
                adr_oft_x_aw_w = 0 ;
                adr_oft_y_aw_w = adr_oft_y_aw_r + 1 ;
              end
              else begin
                adr_oft_x_aw_w = adr_oft_x_aw_r + DATA_THR*(axi_m_awlen_o+1) ;
              end
      WR_CH : if ( adr_oft_x_aw_r == ext_wr_len_x_i + 1 - DATA_THR/2*(axi_m_awlen_o+1) ) begin
                adr_oft_x_aw_w = 0 ;
                adr_oft_y_aw_w = adr_oft_y_aw_r + 1 ;
              end
              else begin
                adr_oft_x_aw_w = adr_oft_x_aw_r + DATA_THR/2*(axi_m_awlen_o+1) ;
              end
    endcase
  end

//--- AXI INTERFACE ---------------------
  // axi_m_awlen_o
  always @ (*) begin
                    axi_m_awlen_o = 0 ;
    case ( cur_state_wr_r )
      WR_BS   :     axi_m_awlen_o = FIFO_ENC_BS_DMP_LEN/DATA_THR - 1 <= AXI_BST_LEN_MAX
                                  ? FIFO_ENC_BS_DMP_LEN/DATA_THR - 1
                                  : AXI_BST_LEN_MAX ;
      WR_LU   : if ( adr_oft_x_aw_r != 0 ) begin
                    axi_m_awlen_o = (ext_wr_len_x_i+1-adr_oft_x_aw_r) / DATA_THR - 1;
                end
                else begin
                  if ( ((4096-{1'b0,axi_m_awaddr_o[11:0]}) < ext_wr_len_x_i + 1) && ((4096-{1'b0,axi_m_awaddr_o[11:0]}) > 0) )
                    axi_m_awlen_o = ((4096-{1'b0,axi_m_awaddr_o[11:0]})/DATA_THR) - 1 ;
                  else
                    axi_m_awlen_o = (ext_wr_len_x_i+1)/DATA_THR - 1;
                end
      WR_CH   : if ( adr_oft_x_aw_r != 0 ) begin
                    axi_m_awlen_o = (ext_wr_len_x_i+1-adr_oft_x_aw_r)*2 / DATA_THR - 1;
                end
                else begin
                  if ( ((4096-{1'b0,axi_m_awaddr_o[11:0]}) < (ext_wr_len_x_i+1)*2) && ((4096-{1'b0,axi_m_awaddr_o[11:0]}) > 0) )
                    axi_m_awlen_o = ((4096-{1'b0,axi_m_awaddr_o[11:0]})/DATA_THR) - 1 ;
                  else
                    axi_m_awlen_o = (ext_wr_len_x_i+1)*2/DATA_THR - 1;
                end
    endcase
  end

  // axi_m_awaddr_bgn_r
  always @( posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      axi_m_awaddr_bgn_r <= 0 ;
    end
    else begin
      if ( cur_state_wr_r == WR_IDLE && nxt_state_wr_w != WR_IDLE ) begin
        case ( nxt_state_wr_w )
          WR_BS : axi_m_awaddr_bgn_r <= cfg_bs_adr_i     ;
          WR_LU : axi_m_awaddr_bgn_r <= cfg_rec_lu_adr_i ;
          WR_CH : axi_m_awaddr_bgn_r <= cfg_rec_ch_adr_i ;
        endcase
      end
    end
  end

  // axi_m_awaddr_o
  always @(*) begin
              axi_m_awaddr_o = 0 ;
    case ( cur_state_wr_r )
      WR_BS : axi_m_awaddr_o = axi_m_awaddr_bgn_r +  cnt_bs_axi_m_aw_r   ;
      WR_LU : axi_m_awaddr_o = axi_m_awaddr_bgn_r + (ext_wr_pos_y_i+adr_oft_y_aw_r)*(cfg_siz_fra_x_i+1)
                                                  +  ext_wr_pos_x_i
                                                  +  adr_oft_x_aw_r ;
      WR_CH : axi_m_awaddr_o = axi_m_awaddr_bgn_r + (ext_wr_pos_y_i+adr_oft_y_aw_r)*(cfg_siz_fra_x_i+1)/2*2
                                                  +  ext_wr_pos_x_i*2
                                                  +  adr_oft_x_aw_r*2  ;
    endcase
  end

  // axi_m_awvalid_o
  assign axi_m_awvalid_o =   cur_state_wr_r != WR_IDLE
                         && !axi_m_aw_done_flg_w   ;

  // axi_m_wvalid_o
  assign axi_m_wvalid_o  =   cur_state_wr_r == WR_BS && !axi_m_w_done_flg_w && fifo_enc_bs_rd_rdy_o_w
                          || cur_state_wr_r == WR_LU &&  ext_wr_val_i
                          || cur_state_wr_r == WR_CH &&  ext_wr_val_i ;

  // axi_m_wdata_o
  always @ (*) begin
              axi_m_wdata_o = 0 ;
    case (cur_state_wr_r)
      WR_BS : axi_m_wdata_o = fifo_enc_bs_rd_dat_o_w ;
      WR_LU, 
      WR_CH : axi_m_wdata_o = { ext_wr_dat_i[ 1*`DATA_PXL_WD-1: 0*`DATA_PXL_WD],
                                ext_wr_dat_i[ 2*`DATA_PXL_WD-1: 1*`DATA_PXL_WD],
                                ext_wr_dat_i[ 3*`DATA_PXL_WD-1: 2*`DATA_PXL_WD],
                                ext_wr_dat_i[ 4*`DATA_PXL_WD-1: 3*`DATA_PXL_WD],
                                ext_wr_dat_i[ 5*`DATA_PXL_WD-1: 4*`DATA_PXL_WD],
                                ext_wr_dat_i[ 6*`DATA_PXL_WD-1: 5*`DATA_PXL_WD],
                                ext_wr_dat_i[ 7*`DATA_PXL_WD-1: 6*`DATA_PXL_WD],
                                ext_wr_dat_i[ 8*`DATA_PXL_WD-1: 7*`DATA_PXL_WD],
                                ext_wr_dat_i[ 9*`DATA_PXL_WD-1: 8*`DATA_PXL_WD],
                                ext_wr_dat_i[10*`DATA_PXL_WD-1: 9*`DATA_PXL_WD],
                                ext_wr_dat_i[11*`DATA_PXL_WD-1:10*`DATA_PXL_WD],
                                ext_wr_dat_i[12*`DATA_PXL_WD-1:11*`DATA_PXL_WD],
                                ext_wr_dat_i[13*`DATA_PXL_WD-1:12*`DATA_PXL_WD],
                                ext_wr_dat_i[14*`DATA_PXL_WD-1:13*`DATA_PXL_WD],
                                ext_wr_dat_i[15*`DATA_PXL_WD-1:14*`DATA_PXL_WD],
                                ext_wr_dat_i[16*`DATA_PXL_WD-1:15*`DATA_PXL_WD] } ; 
    endcase
  end

  // axi_m_bready_o
  assign axi_m_bready_o  = 1 ;

  // axi_m_*_o
  assign axi_m_awburst_o = 1 ;
  assign axi_m_awcache_o = 0 ;
  assign axi_m_awid_o    = 0 ;
  assign axi_m_wid_o     = 0 ;
  assign axi_m_awlock_o  = 0 ;
  assign axi_m_awprot_o  = 0 ;
  assign axi_m_awsize_o  = 4 ;
  assign axi_m_wstrb_o   = 16'hffff ;

  // axi_m_wlast_o
  always @ (*) begin
               axi_m_wlast_o  = 0 ;
    case ( cur_state_wr_r )
      WR_BS  : axi_m_wlast_o  =  cnt_axi_m_w_r == FIFO_ENC_BS_DMP_LEN - DATA_THR
                              && axi_m_wvalid_o
                              && axi_m_wready_i ;
      WR_LU  : axi_m_wlast_o  = cnt_axi_m_w_r == (ext_wr_len_x_i+1)*(ext_wr_len_y_i+1)   - DATA_THR
                              && axi_m_wvalid_o
                              && axi_m_wready_i ;
      WR_CH  : axi_m_wlast_o  = cnt_axi_m_w_r == (ext_wr_len_x_i+1)*(ext_wr_len_y_i+1)*2 - DATA_THR
                              && axi_m_wvalid_o
                              && axi_m_wready_i ;
    endcase
  end

//--- EXT WR ----------------------------
  // ext_wr_ack_o
  assign ext_wr_ack_o =  (cur_state_wr_r == WR_LU || cur_state_wr_r == WR_CH)
                      && axi_m_wready_i ;

//--- ENC BS ----------------------------
  // ack_o
  assign ack_o = !fifo_enc_bs_wr_ful_i_w ;

//--- CFG -------------------------------
  // cfg_enc_bs_len_o
  assign cfg_enc_bs_len_o = cnt_bs_val_i_r ;

//*** GLOBAL *******************************************************************
  // done_w
  `ifdef KNOB_HAS_E_D
    assign done_flg_w = cfg_dat_mod_run_i == `DATA_MOD_RUN_ENC 
                      ? enc_bs_val_i_done_flg_r && fifo_enc_bs_wd_usd_o_w == 0 && !fifo_enc_bs_rd_rdy_o_w
                      : dec_bs_val_o_done_flg_r && fifo_dec_bs_wd_usd_o_w == 0 && !fifo_dec_bs_rd_rdy_o_w ;
  `else
    assign done_flg_w = enc_bs_val_i_done_flg_r && fifo_enc_bs_wd_usd_o_w == 0 && !fifo_enc_bs_rd_rdy_o_w ;
  `endif

  // done_flg_r
  always @( posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      done_flg_r <= 0 ;
    end
    else begin
      done_flg_r <= done_flg_w ;
    end
  end

  // irq_r
  always @(posedge clk or negedge rstn ) begin
    if( !rstn ) begin
      irq_r <= 0 ;
    end
    else begin
      if( ctl_top_flg_irq_i[`CTL_TOP_FLG_IRQ_ITF] && done_flg_w == 1 && done_flg_r == 0 ) begin
        irq_r <= 1 ;
      end
      else if( ctl_top_clr_irq_i[`CTL_TOP_FLG_IRQ_ITF] ) begin
        irq_r <= 0 ;
      end
    end
  end


  // fdb_top_dat_status_*_o
  assign fdb_top_dat_status_run_o[`CTL_TOP_FLG_RUN_CORE] = 0 ;
  assign fdb_top_dat_status_irq_o[`CTL_TOP_FLG_IRQ_CORE] = 0 ;
  assign fdb_top_dat_status_run_o[`CTL_TOP_FLG_RUN_ITF ] = !done_flg_r ;
  assign fdb_top_dat_status_irq_o[`CTL_TOP_FLG_IRQ_ITF ] = irq_r ;

//*** DEBUG ********************************************************************

  `ifdef DEBUG_ENC


    initial begin
      wait( rstn );
      forever begin
        @(negedge clk );
        if( `DATA_BS_WD != 'd8 && `DATA_PXL_WD != 'd8 ) begin
          $display( "\n ERROR: DATA_BS_WD and DATA_PXL_WD should be equal to 'd8! \n" );
          #1000 ;
          $finish ;
        end
      end
    end

    initial begin
      wait( rstn );
      forever begin
        @(negedge clk );
        if( cfg_bs_adr_i & 32'h000003FF != 32'd0 ) begin
          $display( "\n ERROR: cfg_bs_adr_i should be 4k aligned! \n" );
          #1000 ;
          $finish ;
        end
      end
    end

  `endif

endmodule

//*** SUBMODULE ****************************************************************

`include "undefines_enc.vh"
