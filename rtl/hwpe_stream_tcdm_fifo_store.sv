/*
 * hwpe_stream_tcdm_fifo_store.sv
 * Francesco Conti <f.conti@unibo.it>
 *
 * Copyright (C) 2014-2018 ETH Zurich, University of Bologna
 * Copyright and related rights are licensed under the Solderpad Hardware
 * License, Version 0.51 (the "License"); you may not use this file except in
 * compliance with the License.  You may obtain a copy of the License at
 * http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
 * or agreed to in writing, software, hardware and materials distributed under
 * this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 * CONDITIONS OF ANY KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations under the License.
 */

import hwpe_stream_package::*;

module hwpe_stream_tcdm_fifo_store #(
  parameter int unsigned FIFO_DEPTH = 8,
  parameter int unsigned LATCH_FIFO = 0
)
(
  input  logic                 clk_i,
  input  logic                 rst_ni,
  input  logic                 clear_i,
  
  hwpe_stream_intf_tcdm.slave  tcdm_slave,
  hwpe_stream_intf_tcdm.master tcdm_master
);

  hwpe_stream_intf_stream #(
    .DATA_WIDTH ( 64 )
  ) stream_push (
    .clk ( clk_i )
  );
  hwpe_stream_intf_stream #(
    .DATA_WIDTH ( 64 )
  ) stream_pop (
    .clk ( clk_i )
  );

  // wrap tcdm ports into a stream
  assign stream_push.data  = { tcdm_slave.data, tcdm_slave.add };
  assign stream_push.valid = tcdm_slave.req;
  assign tcdm_slave.gnt = stream_push.ready;

  assign { tcdm_master.data, tcdm_master.add } = stream_pop.data;
  assign tcdm_master.req = stream_pop.valid;
  assign stream_pop.ready = tcdm_master.gnt;

  // byte and write enable always set to full-word write
  assign tcdm_master.be  = '1;
  assign tcdm_master.wen = 1'b0;

  hwpe_stream_fifo #(
    .DATA_WIDTH ( 64         ),
    .FIFO_DEPTH ( FIFO_DEPTH ),
    .LATCH_FIFO ( LATCH_FIFO )
  ) i_fifo (
    .clk_i       ( clk_i             ),
    .rst_ni      ( rst_ni            ),
    .clear_i     ( clear_i           ),
    .tcdm_slave  ( stream_push.sink  ),
    .tcdm_master ( stream_pop.source )
  );

endmodule // hwpe_stream_tcdm_fifo_store
