// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// Shorthand to create and send a TL error seq
// Set low priority (1) to send error item to TL agent, so when crossing error item with normal
// seq, normal seq with default priority (100) has the priority to access TL driver
`define create_tl_access_error_case(task_name_, with_c_, seq_t_ = tl_host_custom_seq) \
  begin \
    seq_t_ tl_seq; \
    `uvm_info(`gfn, {"Running ", `"task_name_`"}, UVM_HIGH) \
    `uvm_create_on(tl_seq, p_sequencer.tl_sequencer_h) \
    if (cfg.zero_delays) begin \
      tl_seq.min_req_delay = 0; \
      tl_seq.max_req_delay = 0; \
    end \
    `DV_CHECK_RANDOMIZE_WITH_FATAL(tl_seq, with_c_) \
    csr_utils_pkg::increment_outstanding_access(); \
    `uvm_send_pri(tl_seq, 1) \
    csr_utils_pkg::decrement_outstanding_access(); \
  end

virtual task tl_access_unmapped_addr();
`ifdef _VCP //dzi378
	addr_range_t temp;
`endif
  repeat ($urandom_range(10, 100)) begin
`ifdef _VCP //dzi378
	foreach (cfg.mem_ranges[i]) temp=cfg.mem_ranges[i];
`endif
    `create_tl_access_error_case(
        tl_access_unmapped_addr,
        foreach (local::cfg.csr_addrs[i]) {
`ifdef _VCP //dzi386
          {tl_seq.addr[TL_AW-1:2], 2'b00} % local::cfg.csr_addr_map_size !=
`else
          {addr[TL_AW-1:2], 2'b00} % local::cfg.csr_addr_map_size !=
`endif
              local::cfg.csr_addrs[i] - local::cfg.csr_base_addr;
        }
        foreach (local::cfg.mem_ranges[i]) {
          !(addr % local::cfg.csr_addr_map_size
`ifdef _VCP //dzi378
              inside {[local::temp.start_addr : local::temp.end_addr]}
`else
              inside {[local::cfg.mem_ranges[i].start_addr : local::cfg.mem_ranges[i].end_addr]}
`endif
		  );
        })
  end
endtask

virtual task tl_write_csr_word_unaligned_addr();
`ifdef _VCP //dzi378
	addr_range_t temp;
`endif
  repeat ($urandom_range(10, 100)) begin
`ifdef _VCP //dzi378
	foreach (cfg.mem_ranges[i]) temp=cfg.mem_ranges[i];
`endif
    `create_tl_access_error_case(
        tl_write_csr_word_unaligned_addr,
        opcode inside {tlul_pkg::PutFullData, tlul_pkg::PutPartialData};
        foreach (local::cfg.mem_ranges[i]) {
          !(addr % local::cfg.csr_addr_map_size
`ifdef _VCP //dzi378
              inside {[local::temp.start_addr : local::temp.end_addr]}
`else
              inside {[local::cfg.mem_ranges[i].start_addr : local::cfg.mem_ranges[i].end_addr]}
`endif
		  );
        }
`ifdef _VCP //dzi386
        tl_seq.addr[1:0] != 2'b00;
`else
	addr[1:0] != 2'b00;
`endif
)

  end
endtask

virtual task tl_write_less_than_csr_width();
  uvm_reg all_csrs[$];
  ral.get_registers(all_csrs);
  foreach (all_csrs[i]) begin
    dv_base_reg     csr;
    uint            msb_pos;
    bit [TL_AW-1:0] addr;
    `DV_CHECK_FATAL($cast(csr, all_csrs[i]))
    msb_pos = csr.get_msb_pos();
    addr    = csr.get_address();
    `create_tl_access_error_case(
        tl_write_less_than_csr_width,
        opcode inside {tlul_pkg::PutFullData, tlul_pkg::PutPartialData};
        addr == local::addr;
        // constrain enabled bytes less than reg width
        if (msb_pos >= 24) {
          &mask == 0;
`ifdef _VCP//dzi386
        } else if (msb_pos >= 16) {
          &tl_seq.mask[2:0] == 0;
        } else if (msb_pos >= 8) {
          &tl_seq.mask[1:0] == 0;
        } else { // msb_pos <= 7
          tl_seq.mask[0] == 0;
        })
`else
        } else if (msb_pos >= 16) {
          &mask[2:0] == 0;
        } else if (msb_pos >= 8) {
          &mask[1:0] == 0;
        } else { // msb_pos <= 7
          mask[0] == 0;
        })
`endif
  end
endtask

virtual task tl_protocol_err();
  repeat ($urandom_range(10, 100)) begin
    `create_tl_access_error_case(
        tl_protocol_err, , tl_host_protocol_err_seq
        )
  end
endtask

task tl_write_mem_less_than_word();
`ifdef _VCP //dzi378
		addr_range_t temp;
`endif
  uint mem_idx;
  repeat ($urandom_range(10, 100)) begin
    // if more than one memories, randomly select one memory
    mem_idx = $urandom_range(0, cfg.mem_ranges.size - 1);
`ifdef _VCP //dzi378
		temp=cfg.mem_ranges[mem_idx];
`endif
    `create_tl_access_error_case(
        tl_write_mem_less_than_word,
        opcode inside {tlul_pkg::PutFullData, tlul_pkg::PutPartialData};
`ifdef _VCP//dzi386        
	tl_seq.addr[1:0] == 0; // word aligned
`else
	addr[1:0] == 0; // word aligned
`endif
        addr inside
`ifdef _VCP //dzi378
        {[local::temp.start_addr : local::temp.end_addr]};
`else
	{[local::cfg.mem_ranges[mem_idx].start_addr : local::cfg.mem_ranges[mem_idx].end_addr]};
`endif
        mask != '1 || size < 2;
        )
  end
endtask

virtual task tl_read_mem_err();
  uint mem_idx;
`ifdef _VCP //dzi378
	addr_range_t temp;
`endif
  repeat ($urandom_range(10, 100)) begin
    // if more than one memories, randomly select one memory
    mem_idx = $urandom_range(0, cfg.mem_ranges.size - 1);
`ifdef _VCP //dzi378
	temp=cfg.mem_ranges[mem_idx];
`endif
    `create_tl_access_error_case(
        tl_read_mem_err,
        opcode == tlul_pkg::Get;
        addr inside
`ifdef _VCP //dzi378
            {[local::temp.start_addr : local::temp.end_addr]};
`else
            {[local::cfg.mem_ranges[mem_idx].start_addr : local::cfg.mem_ranges[mem_idx].end_addr]};
`endif
        )
  end
endtask

// generic task to check interrupt temp reg functionality
virtual task run_tl_errors_vseq(int num_times = 1, bit do_wait_clk = 0);
  bit temp_mem_err_byte_write = (cfg.mem_ranges.size > 0) && !cfg.en_mem_byte_write;
  bit temp_mem_err_read       = (cfg.mem_ranges.size > 0) && !cfg.en_mem_read;
  cfg.tlul_assert_ctrl_vif.drive(1'b0);

  for (int trans = 1; trans <= num_times; trans++) begin
    `uvm_info(`gfn, $sformatf("Running run_tl_errors_vseq %0d/%0d", trans, num_times), UVM_LOW)
    if (cfg.en_devmode == 1) begin
      cfg.devmode_vif.drive($urandom_range(0, 1));
    end
    // use multiple thread to create outstanding access
    repeat ($urandom_range(5, 10)) fork
      begin
        randcase
          1: tl_access_unmapped_addr();
          1: tl_write_csr_word_unaligned_addr();
          1: tl_write_less_than_csr_width();
          1: tl_protocol_err();
          // only run this task when the mem supports error response
          temp_mem_err_byte_write: tl_write_mem_less_than_word();
          temp_mem_err_read:       tl_read_mem_err();
        endcase
      end
    join_none
    wait fork;
    if (do_wait_clk) cfg.clk_rst_vif.wait_clks($urandom_range(500, 10_000));
  end // for
  cfg.tlul_assert_ctrl_vif.drive(1'b1);
endtask : run_tl_errors_vseq

`undef create_tl_access_error_case
