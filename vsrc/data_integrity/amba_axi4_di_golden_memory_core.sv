`default_nettype none

module amba_axi4_di_golden_memory_core (
   input  wire        clock,
   input  wire        reset,
   input  wire        init,
   input  wire [31:0] base_addr,
   input  wire [2:0]  tracked_beat,
   input  wire [31:0] initial_tracked_word,

   input  wire        write_fire,
   input  wire [31:0] write_addr,
   input  wire [31:0] write_data,
   input  wire [3:0]  write_strb,
   output wire        write_addr_in_window,
   output wire        write_targets_tracked_slot,
   output wire [31:0] write_old_word,
   output wire [31:0] write_expected_word,

   input  wire [31:0] read_addr,
   output wire        read_addr_in_window,
   output wire        read_targets_tracked_slot,
   output wire [31:0] read_word,

   input  wire [31:0] read1_addr,
   output wire        read1_addr_in_window,
   output wire        read1_targets_tracked_slot,
   output wire [31:0] read1_word,

   input  wire [31:0] read2_addr,
   output wire        read2_addr_in_window,
   output wire        read2_targets_tracked_slot,
   output wire [31:0] read2_word,

   output wire [31:0] tracked_word
);

   localparam int unsigned WINDOW_WORDS = 8;

   reg [31:0] mem [0:WINDOW_WORDS-1];
   reg [31:0] tracked_word_q = 32'h0;

   wire [2:0] write_slot =
      amba_axi4_data_integrity_pkg::axi4_di_slot_from_addr32(base_addr, write_addr);
   wire [2:0] read_slot =
      amba_axi4_data_integrity_pkg::axi4_di_slot_from_addr32(base_addr, read_addr);
   wire [2:0] read1_slot =
      amba_axi4_data_integrity_pkg::axi4_di_slot_from_addr32(base_addr, read1_addr);
   wire [2:0] read2_slot =
      amba_axi4_data_integrity_pkg::axi4_di_slot_from_addr32(base_addr, read2_addr);

   assign write_addr_in_window =
      amba_axi4_data_integrity_pkg::axi4_di_same_32byte_window(base_addr, write_addr);
   assign read_addr_in_window =
      amba_axi4_data_integrity_pkg::axi4_di_same_32byte_window(base_addr, read_addr);
   assign read1_addr_in_window =
      amba_axi4_data_integrity_pkg::axi4_di_same_32byte_window(base_addr, read1_addr);
   assign read2_addr_in_window =
      amba_axi4_data_integrity_pkg::axi4_di_same_32byte_window(base_addr, read2_addr);
   assign write_targets_tracked_slot =
      write_addr_in_window &&
      amba_axi4_data_integrity_pkg::axi4_di_is_tracked_beat(write_slot, tracked_beat);
   assign read_targets_tracked_slot =
      read_addr_in_window &&
      amba_axi4_data_integrity_pkg::axi4_di_is_tracked_beat(read_slot, tracked_beat);
   assign read1_targets_tracked_slot =
      read1_addr_in_window &&
      amba_axi4_data_integrity_pkg::axi4_di_is_tracked_beat(read1_slot, tracked_beat);
   assign read2_targets_tracked_slot =
      read2_addr_in_window &&
      amba_axi4_data_integrity_pkg::axi4_di_is_tracked_beat(read2_slot, tracked_beat);
   assign write_old_word = write_addr_in_window ? mem[write_slot] : 32'h0;

   assign write_expected_word =
      amba_axi4_data_integrity_pkg::axi4_di_apply_wstrb32(
         write_old_word, write_data, write_strb);
   assign read_word = read_addr_in_window ? mem[read_slot] : 32'h0;
   assign read1_word = read1_addr_in_window ? mem[read1_slot] : 32'h0;
   assign read2_word = read2_addr_in_window ? mem[read2_slot] : 32'h0;
   assign tracked_word = tracked_word_q;

   integer init_i;

   always @(posedge clock) begin
      if (reset) begin
         tracked_word_q <= 32'h0;
         for (init_i = 0; init_i < WINDOW_WORDS; init_i = init_i + 1)
            mem[init_i] <= 32'h0;
      end
      else begin
         if (init) begin
            tracked_word_q <= initial_tracked_word;
            for (init_i = 0; init_i < WINDOW_WORDS; init_i = init_i + 1) begin
               mem[init_i] <=
                  (init_i[2:0] == tracked_beat) ?
                  initial_tracked_word :
                  amba_axi4_data_integrity_pkg::axi4_di_initial_word32(
                     base_addr, init_i[2:0]);
            end
         end
         else if (write_fire && write_addr_in_window) begin
            mem[write_slot] <= write_expected_word;
            if (write_targets_tracked_slot)
               tracked_word_q <= write_expected_word;
         end
      end
   end
endmodule

`default_nettype wire
