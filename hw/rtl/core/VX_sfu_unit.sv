// Copyright © 2019-2023
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

`include "VX_define.vh"

module VX_sfu_unit import VX_gpu_pkg::*; #(
    parameter `STRING INSTANCE_ID = "",
    parameter CORE_ID = 0
) (
    input wire              clk,
    input wire              reset,

`ifdef PERF_ENABLE
    input sysmem_perf_t     sysmem_perf,
    input pipeline_perf_t   pipeline_perf,
`endif

    input base_dcrs_t       base_dcrs,

    // Inputs
    VX_dispatch_if.slave    dispatch_if [`ISSUE_WIDTH],

`ifdef EXT_F_ENABLE
    VX_fpu_csr_if.slave     fpu_csr_if [`NUM_FPU_BLOCKS],
`endif

    VX_commit_csr_if.slave  commit_csr_if,
    VX_sched_csr_if.slave   sched_csr_if,

`ifdef EXT_TEX_ENABLE
    VX_tex_bus_if.master    tex_bus_if,
`ifdef PERF_ENABLE
    VX_tex_perf_if.slave    perf_tex_if,
`endif
`endif

`ifdef EXT_RASTER_ENABLE
    VX_raster_bus_if.slave  raster_bus_if,
`ifdef PERF_ENABLE
    VX_raster_perf_if.slave perf_raster_if,
`endif
`endif

`ifdef EXT_OM_ENABLE
    VX_om_bus_if.master     om_bus_if,
`ifdef PERF_ENABLE
    VX_om_perf_if.slave     perf_om_if,
`endif
`endif

    // Outputs
    VX_commit_if.master     commit_if [`ISSUE_WIDTH],
    VX_warp_ctl_if.master   warp_ctl_if
);
    `UNUSED_SPARAM (INSTANCE_ID)
    localparam BLOCK_SIZE   = 1;
    localparam NUM_LANES    = `NUM_SFU_LANES;
    localparam PE_COUNT     = 2;
    localparam PE_SEL_BITS  = `CLOG2(PE_COUNT);
    localparam PE_IDX_WCTL  = 0;
    localparam PE_IDX_CSRS  = 1;

    VX_execute_if #(
        .data_t (sfu_exe_t)
    ) per_block_execute_if[BLOCK_SIZE]();

    VX_result_if #(
        .data_t (sfu_res_t)
    ) per_block_result_if[BLOCK_SIZE]();

    VX_dispatch_unit #(
        .BLOCK_SIZE (BLOCK_SIZE),
        .NUM_LANES  (NUM_LANES),
        .OUT_BUF    (3)
    ) dispatch_unit (
        .clk        (clk),
        .reset      (reset),
        .dispatch_if(dispatch_if),
        .execute_if (per_block_execute_if)
    );

`ifdef EXT_TEX_ENABLE
    VX_sfu_csr_if tex_csr_if();
`endif

`ifdef EXT_RASTER_ENABLE
    VX_sfu_csr_if raster_csr_if();
`endif

`ifdef EXT_OM_ENABLE
    VX_sfu_csr_if om_csr_if();
`endif

    VX_execute_if #(
        .data_t (sfu_exe_t)
    ) pe_execute_if[PE_COUNT]();

    VX_result_if#(
        .data_t (sfu_res_t)
    ) pe_result_if[PE_COUNT]();

    reg [PE_SEL_BITS-1:0] pe_select;
    always @(*) begin
        pe_select = PE_IDX_WCTL;
        if (inst_sfu_is_csr(per_block_execute_if[0].data.op_type)) begin
            pe_select = PE_IDX_CSRS;
        end
    end

    VX_pe_switch #(
        .PE_COUNT   (PE_COUNT),
        .NUM_LANES  (NUM_LANES),
        .ARBITER    ("R"),
        .REQ_OUT_BUF(0),
        .RSP_OUT_BUF(3)
    ) pe_switch (
        .clk        (clk),
        .reset      (reset),
        .pe_sel     (pe_select),
        .execute_in_if (per_block_execute_if[0]),
        .result_out_if (per_block_result_if[0]),
        .execute_out_if (pe_execute_if),
        .result_in_if (pe_result_if)
    );

    VX_wctl_unit #(
        .INSTANCE_ID (`SFORMATF(("%s-wctl", INSTANCE_ID))),
        .NUM_LANES (NUM_LANES)
    ) wctl_unit (
        .clk        (clk),
        .reset      (reset),
        .execute_if (pe_execute_if[PE_IDX_WCTL]),
        .warp_ctl_if(warp_ctl_if),
        .result_if  (pe_result_if[PE_IDX_WCTL])
    );

    VX_csr_unit #(
        .INSTANCE_ID (`SFORMATF(("%s-csr", INSTANCE_ID))),
        .CORE_ID   (CORE_ID),
        .NUM_LANES (NUM_LANES)
    ) csr_unit (
        .clk            (clk),
        .reset          (reset),

        .base_dcrs      (base_dcrs),
        .execute_if     (pe_execute_if[PE_IDX_CSRS]),

    `ifdef PERF_ENABLE
        .sysmem_perf    (sysmem_perf),
        .pipeline_perf  (pipeline_perf),
    `endif

    `ifdef EXT_TEX_ENABLE
        .tex_csr_if     (tex_csr_if),
    `ifdef PERF_ENABLE
        .perf_tex_if    (perf_tex_if),
    `endif
    `endif

    `ifdef EXT_RASTER_ENABLE
        .raster_csr_if  (raster_csr_if),
    `ifdef PERF_ENABLE
        .perf_raster_if (perf_raster_if),
    `endif
    `endif

    `ifdef EXT_OM_ENABLE
        .om_csr_if      (om_csr_if),
    `ifdef PERF_ENABLE
        .perf_om_if     (perf_om_if),
    `endif
    `endif

    `ifdef EXT_F_ENABLE
        .fpu_csr_if     (fpu_csr_if),
    `endif

        .sched_csr_if   (sched_csr_if),
        .commit_csr_if  (commit_csr_if),
        .result_if      (pe_result_if[PE_IDX_CSRS])
    );

`ifdef EXT_TEX_ENABLE

    VX_execute_if #(
        .NUM_LANES (NUM_LANES)
    ) tex_execute_if();
    VX_commit_if #(
        .NUM_LANES (NUM_LANES)
    ) tex_commit_if();

    assign tex_execute_if.valid = per_block_execute_if[0].valid && (per_block_execute_if[0].data.op_type == `INST_SFU_TEX);
    assign tex_execute_if.data = per_block_execute_if[0].data;

    `RESET_RELAY (tex_reset, reset);

    VX_tex_agent #(
        .CORE_ID   (CORE_ID),
        .NUM_LANES (NUM_LANES)
    ) tex_agent (
        .clk        (clk),
        .reset      (tex_reset),
        .execute_if (tex_execute_if),
        .tex_csr_if (tex_csr_if),
        .tex_bus_if (tex_bus_if),
        .commit_if  (tex_commit_if)
    );

    assign rsp_arb_valid_in[RSP_ARB_IDX_TEX] = tex_commit_if.valid;
    assign rsp_arb_data_in[RSP_ARB_IDX_TEX] = tex_commit_if.data;
    assign tex_commit_if.ready = rsp_arb_ready_in[RSP_ARB_IDX_TEX];

`endif

`ifdef EXT_RASTER_ENABLE

    VX_execute_if #(
        .NUM_LANES (NUM_LANES)
    ) raster_execute_if();
    VX_commit_if #(
        .NUM_LANES (NUM_LANES)
    ) raster_commit_if();

    assign raster_execute_if.valid = per_block_execute_if[0].valid && (per_block_execute_if[0].data.op_type == `INST_SFU_RASTER);
    assign raster_execute_if.data = per_block_execute_if[0].data;

    `RESET_RELAY (raster_reset, reset);

    VX_raster_agent #(
        .CORE_ID   (CORE_ID),
        .NUM_LANES (NUM_LANES)
    ) raster_agent (
        .clk        (clk),
        .reset      (raster_reset),
        .execute_if (raster_execute_if),
        .raster_csr_if(raster_csr_if),
        .raster_bus_if(raster_bus_if),
        .commit_if  (raster_commit_if)
    );

    assign rsp_arb_valid_in[RSP_ARB_IDX_RASTER] = raster_commit_if.valid;
    assign rsp_arb_data_in[RSP_ARB_IDX_RASTER] = raster_commit_if.data;
    assign raster_commit_if.ready = rsp_arb_ready_in[RSP_ARB_IDX_RASTER];

`endif

`ifdef EXT_OM_ENABLE

    VX_execute_if #(
        .NUM_LANES (NUM_LANES)
    ) om_execute_if();
    VX_commit_if #(
        .NUM_LANES (NUM_LANES)
    ) om_commit_if();

    assign om_execute_if.valid = per_block_execute_if[0].valid && (per_block_execute_if[0].data.op_type == `INST_SFU_OM);
    assign om_execute_if.data = per_block_execute_if[0].data;

    `RESET_RELAY (om_reset, reset);

    VX_om_agent #(
        .CORE_ID   (CORE_ID),
        .NUM_LANES (NUM_LANES)
    ) om_agent (
        .clk        (clk),
        .reset      (om_reset),
        .execute_if (om_execute_if),
        .om_csr_if  (om_csr_if),
        .om_bus_if  (om_bus_if),
        .commit_if  (om_commit_if)
    );

    assign rsp_arb_valid_in[RSP_ARB_IDX_OM] = om_commit_if.valid;
    assign rsp_arb_data_in[RSP_ARB_IDX_OM] = om_commit_if.data;
    assign om_commit_if.ready = rsp_arb_ready_in[RSP_ARB_IDX_OM];

`endif

    VX_gather_unit #(
        .BLOCK_SIZE (BLOCK_SIZE),
        .NUM_LANES  (NUM_LANES),
        .OUT_BUF    (3)
    ) gather_unit (
        .clk       (clk),
        .reset     (reset),
        .result_if (per_block_result_if),
        .commit_if (commit_if)
    );

endmodule
