// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// AES MixColumns

module aes_mix_columns (
  input  aes_pkg::mode_e       mode_i,
  input  logic [3:0][3:0][7:0] data_i,
  output logic [3:0][3:0][7:0] data_o
);

  import aes_pkg::*;

  // Transpose to operate on columns
  logic [3:0][3:0][7:0] data_i_transposed;
  logic [3:0][3:0][7:0] data_o_transposed;

  assign data_i_transposed = aes_transpose(data_i);
`ifdef _VCP //LPA1866
generate
`endif
  // Individually mix columns
  for (genvar i = 0; i < 4; i++) begin : gen_mix_column
    aes_mix_single_column aes_mix_column_i (
      .mode_i ( mode_i               ),
      .data_i ( data_i_transposed[i] ),
      .data_o ( data_o_transposed[i] )
    );
  end
`ifdef _VCP //LPA1866
endgenerate
`endif
  assign data_o = aes_transpose(data_o_transposed);

endmodule
