/*Copyright 2020-2021 T-Head Semiconductor Co., Ltd.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/
`include "tdt_define.h"

module tdt_dtm_top #(
    parameter                        DTM_ABITS = 16
)(
    output                           pad_dtm_tclk,
    input                            pad_dtm_trst_b,
    input                            pad_dtm_jtag2_sel,         
    input                            pad_dtm_tap_en,        
    input                            pad_dtm_tdi,           
    input                            pad_dtm_tms_i,  
    output                           dtm_pad_tdo,           
    output                           dtm_pad_tdo_en,        
    output                           dtm_pad_tms_o,         
    output                           dtm_pad_tms_oe,

    output                           dtm_apbm_wr_vld,
    output  [DTM_ABITS-1:0]          dtm_apbm_wr_addr,
    output  [1:0]                    dtm_apbm_wr_flg,
    output  [31:0]                   dtm_apbm_wdata,
    output                           dmihardreset,
    input   [31:0]                   apbm_dtm_rdata,
    input                            apbm_dtm_wr_ready
);

    localparam                           DTM_NDMIREG_WIDTH    = 32;
    localparam                           DTM_IRREG_WIDTH      = 5; 
    localparam                           DTM_FSM2_RSTCNT      = 80; 
    localparam                           CHAIN_DW             = DTM_ABITS + 32 + 2;
    
    wire                                 chain_io_tdo;             
    wire                                 ctrl_io_tdo_en;              
    wire                                 ctrl_io_tms_oe;                          
    wire                                 io_chain_tdi;             
    wire                                 io_ctrl_tap_en;
    wire                                 idr_dmi_mode;
    wire                                 ctrl_chain_capture_dr;  
    wire                                 ctrl_chain_capture_ir;   
    wire                                 ctrl_idr_update_ir;       
    wire                                 ctrl_idr_update_dr;
    wire                                 ctrl_idr_capture_dr;
    wire                                 ctrl_chain_shift_dr;      
    wire                                 ctrl_chain_shift_ir;      
    wire                                 ctrl_chain_shift_par;     
    wire                                 ctrl_chain_shift_sync;
    wire  [CHAIN_DW-1:0]                 idr_chain_dr; 
    wire  [DTM_IRREG_WIDTH-1:0]          idr_chain_ir; 
    wire  [CHAIN_DW-1:0]                 chain_idr_data;      

	wire [DTM_IRREG_WIDTH-1:0] ir_in;
	wire [DTM_IRREG_WIDTH-1:0] ir_out;
	wire capture_dr, shift_dr, update_dr, capture_ir, update_ir;
	wire tdi, tdo, tck;

	assign ir_out = ir_in;

	sld_virtual_jtag #(
		.sld_auto_instance_index ("NO"),
		.sld_instance_index      (0),
		.sld_ir_width            (DTM_IRREG_WIDTH)
	) vjtag (
		.tdi                (tdi),
		.tdo                (tdo),
		.ir_in              (ir_in),
		.ir_out             (ir_out),
		.virtual_state_cdr  (virtual_state_cdr),
		.virtual_state_sdr  (virtual_state_sdr),
		.virtual_state_e1dr (virtual_state_e1dr),
		.virtual_state_pdr  (virtual_state_pdr),
		.virtual_state_e2dr (virtual_state_e2dr),
		.virtual_state_udr  (virtual_state_udr),
		.virtual_state_cir  (virtual_state_cir),
		.virtual_state_uir  (virtual_state_uir),
		.tck                (tck)
	);

	assign capture_dr = virtual_state_cdr;
	assign shift_dr = virtual_state_sdr;
	assign update_dr = virtual_state_udr;
	assign capture_ir = virtual_state_cir;
	assign update_ir = virtual_state_uir;

	 assign pad_dtm_tclk = tck;

    tdt_dtm_chain #(
        .CHAIN_DW                        (CHAIN_DW),
        .DTM_IRREG_WIDTH                 (DTM_IRREG_WIDTH),
        .DTM_ABITS                       (DTM_ABITS),
        .DTM_NDMIREG_WIDTH               (DTM_NDMIREG_WIDTH)
    ) x_tdt_dtm_chain (
        .tclk                            (tck),
        .trst_b                          (1'b1),
        .dmihardreset                    (dmihardreset),
        .io_chain_tdi                    (tdi),
        .chain_io_tdo                    (tdo),
        .idr_chain_dr                    (idr_chain_dr),
        .idr_chain_ir                    (idr_chain_ir),
        .chain_idr_data                  (chain_idr_data),
        .idr_dmi_mode                    (idr_dmi_mode),
        .ctrl_chain_capture_dr           (capture_dr),
        .ctrl_chain_capture_ir           (capture_ir),
        .ctrl_chain_shift_dr             (shift_dr),
        .ctrl_chain_shift_ir             (1'b0),
        .ctrl_chain_shift_par            (1'b0),
        .ctrl_chain_shift_sync           (1'b0)
    );

    tdt_dtm_idr #(
        .CHAIN_DW                        (CHAIN_DW),
        .DTM_IRREG_WIDTH                 (DTM_IRREG_WIDTH),
        .DTM_ABITS                       (DTM_ABITS),
        .DTM_NDMIREG_WIDTH               (DTM_NDMIREG_WIDTH)
    ) x_tdt_dtm_idr (
        .tclk                            (tck),
        .trst_b                          (1'b1),
        .dmihardreset                    (dmihardreset),
        .idr_chain_dr                    (idr_chain_dr),
        .idr_chain_ir                    (idr_chain_ir),
        .idr_dmi_mode                    (idr_dmi_mode),
        .chain_idr_data                  (chain_idr_data),
        .ir_in                           (ir_in),
        .ctrl_idr_update_ir              (update_ir),
        .ctrl_idr_update_dr              (update_dr),
        .ctrl_idr_capture_dr             (capture_dr),
        .dtm_apbm_wr_vld                 (dtm_apbm_wr_vld),
        .dtm_apbm_wr_addr                (dtm_apbm_wr_addr),
        .dtm_apbm_wr_flg                 (dtm_apbm_wr_flg),
        .dtm_apbm_wdata                  (dtm_apbm_wdata),
        .apbm_dtm_rdata                  (apbm_dtm_rdata),
        .apbm_dtm_wr_ready               (apbm_dtm_wr_ready)
    );

endmodule
