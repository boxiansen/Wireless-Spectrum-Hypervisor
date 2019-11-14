/* 
 * Copyright 2018 <+YOU OR YOUR COMPANY+>.
 * 
 * This is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3, or (at your option)
 * any later version.
 * 
 * This software is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this software; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street,
 * Boston, MA 02110-1301, USA.
 */

`timescale 1ns/1ps
`define NS_PER_TICK 1
`define NUM_TEST_CASES 3

`define SEEK_SET 0
`define SEEK_END 2

`include "sim_exec_report.vh"
`include "sim_clks_rsts.vh"
`include "sim_rfnoc_lib.svh"

module noc_block_scatterPHY_tb();
  `TEST_BENCH_INIT("noc_block_scatterPHY",`NUM_TEST_CASES,`NS_PER_TICK);
  localparam BUS_CLK_PERIOD = $ceil(1e9/166.67e6);
  localparam CE_CLK_PERIOD  = $ceil(1e9/200e6);
  localparam NUM_CE         = 2;  // Number of Computation Engines / User RFNoC blocks to simulate
  localparam NUM_STREAMS    = 1;  // Number of test bench streams
  `RFNOC_SIM_INIT(NUM_CE, NUM_STREAMS, BUS_CLK_PERIOD, CE_CLK_PERIOD);
  `RFNOC_ADD_BLOCK(noc_block_McFsource, 0);
  `RFNOC_ADD_BLOCK(noc_block_channelizer, 1);

  localparam SPP = 16; // Samples per packet

  /********************************************************
  ** Verification
  ********************************************************/
  initial begin : tb_main
    string s;
    logic [31:0] random_word;
    logic [63:0] readback;

    reg [31:0] data32 [0:191];
    int fd_in, fd_out;
    int file_length;
    int file_size;

    logic        enable;
    logic [15:0] len;
    logic [15:0] rate;
    logic [1:0]  swap_samples;
    logic [1:0]  endianness;

    logic last;
    logic signed [31:0] iq_samp;

    /********************************************************
    ** Test 1 -- Reset
    ********************************************************/
    `TEST_CASE_START("Wait for Reset");
    while (bus_rst) @(posedge bus_clk);
    while (ce_rst) @(posedge ce_clk);
    `TEST_CASE_DONE(~bus_rst & ~ce_rst);

    /********************************************************
    ** Test 2 -- Check for correct NoC IDs
    ********************************************************/
    `TEST_CASE_START("Check NoC ID");
    // Read NOC IDs
    tb_streamer.read_reg(sid_noc_block_McFsource, RB_NOC_ID, readback);
    $display("Read McFsource NOC ID: %16x", readback);
    `ASSERT_ERROR(readback == noc_block_McFsource.NOC_ID, "Incorrect NOC ID");
    tb_streamer.read_reg(sid_noc_block_channelizer, RB_NOC_ID, readback);
    $display("Read channelizer NOC ID: %16x", readback);
    `ASSERT_ERROR(readback == noc_block_channelizer.NOC_ID, "Incorrect NOC ID");
    `TEST_CASE_DONE(1);

    /********************************************************
    ** Test 3 -- Load PFB Coefficients and send McFsource to channelizer
    ********************************************************/
    `TEST_CASE_START("Pull data");
    `RFNOC_CONNECT(noc_block_McFsource,noc_block_channelizer,SC16,SPP);
    `RFNOC_CONNECT(noc_block_channelizer,noc_block_tb,SC16,SPP);

    fd_in = $fopen("/home/mmehari/rfnoc/rfnoc-scatter/rfnoc/testbenches/noc_block_scatterPHY_tb/M_32_taps.bin", "r");
    file_length = $fread(data32, fd_in);
    file_size   = file_length >> 2;
    $fclose(fd_in);

    // Set filter coefficients via reload bus
    begin
        tb_streamer.write_reg(sid_noc_block_channelizer, noc_block_channelizer.SR_FFT_SIZE, 8);
        for (int i=0; i<file_size; i++) begin
              if (i == file_size-1) begin
                tb_streamer.write_reg(sid_noc_block_channelizer, noc_block_channelizer.SR_RELOAD_LAST, data32[i]);
              end else begin
                tb_streamer.write_reg(sid_noc_block_channelizer, noc_block_channelizer.SR_RELOAD, data32[i]);
              end
        end
    end

    // Reset scatterPHY registers
    tb_streamer.write_user_reg(sid_noc_block_McFsource, noc_block_McFsource.SR_SAMPLE_LEN_1MS, 16'd11520);
    tb_streamer.write_user_reg(sid_noc_block_McFsource, noc_block_McFsource.SR_SPP, 16'd768);
    tb_streamer.write_user_reg(sid_noc_block_McFsource, noc_block_McFsource.SR_CLK_DIV, 16'd16);

    // Enable McF source block
    tb_streamer.write_user_reg(sid_noc_block_McFsource, noc_block_McFsource.SR_ENABLE, 1'd1);

    $display("McF source output");
    fd_out = $fopen("/home/mmehari/rfnoc/rfnoc-scatter/rfnoc/testbenches/noc_block_scatterPHY_tb/chan0.txt", "w");
    for (int i = 0; i < 11520 + 200; i++) begin
      tb_streamer.pull_word(iq_samp, last);
//      $display("%h,", iq_samp);
      $fwrite(fd_out, "%h,\n", iq_samp);
    end
    $fclose(fd_out);
    `TEST_CASE_DONE(1);
    `TEST_BENCH_DONE;

  end
endmodule
