`ifndef __AMBA_AXI4_DATA_INTEGRITY_PKG__
 `define __AMBA_AXI4_DATA_INTEGRITY_PKG__

package amba_axi4_data_integrity_pkg;
   // Pure combinational helpers shared by data-integrity examples.
   // Keep topology-specific state machines and proof-only closure local to examples.

   function automatic logic [31:0] axi4_di_apply_wstrb32(
      input logic [31:0] old_word,
      input logic [31:0] new_word,
      input logic [3:0]  strb
   );
      begin
         axi4_di_apply_wstrb32 = old_word;
         if (strb[0])
            axi4_di_apply_wstrb32[7:0] = new_word[7:0];
         if (strb[1])
            axi4_di_apply_wstrb32[15:8] = new_word[15:8];
         if (strb[2])
            axi4_di_apply_wstrb32[23:16] = new_word[23:16];
         if (strb[3])
            axi4_di_apply_wstrb32[31:24] = new_word[31:24];
      end
   endfunction

   function automatic logic [31:0] axi4_di_initial_word32(
      input logic [31:0] base,
      input logic [2:0]  index
   );
      begin
         axi4_di_initial_word32 = 32'ha5a5_0000 ^ base ^ {29'h0, index};
      end
   endfunction

   function automatic bit axi4_di_wstrb32_updates_lane(
      input logic [3:0] strb,
      input int unsigned lane
   );
      begin
         case (lane)
            0: axi4_di_wstrb32_updates_lane = strb[0];
            1: axi4_di_wstrb32_updates_lane = strb[1];
            2: axi4_di_wstrb32_updates_lane = strb[2];
            3: axi4_di_wstrb32_updates_lane = strb[3];
            default: axi4_di_wstrb32_updates_lane = 1'b0;
         endcase
      end
   endfunction

   function automatic bit axi4_di_wstrb32_lane_matches_update(
      input logic [31:0] observed_word,
      input logic [31:0] old_word,
      input logic [31:0] new_word,
      input logic [3:0]  strb,
      input int unsigned lane
   );
      begin
         case (lane)
            0: axi4_di_wstrb32_lane_matches_update =
                  observed_word[7:0] ==
                  (strb[0] ? new_word[7:0] : old_word[7:0]);
            1: axi4_di_wstrb32_lane_matches_update =
                  observed_word[15:8] ==
                  (strb[1] ? new_word[15:8] : old_word[15:8]);
            2: axi4_di_wstrb32_lane_matches_update =
                  observed_word[23:16] ==
                  (strb[2] ? new_word[23:16] : old_word[23:16]);
            3: axi4_di_wstrb32_lane_matches_update =
                  observed_word[31:24] ==
                  (strb[3] ? new_word[31:24] : old_word[31:24]);
            default: axi4_di_wstrb32_lane_matches_update = 1'b0;
         endcase
      end
   endfunction

   function automatic bit axi4_di_beat_index_in_range(
      input logic [7:0] beat_index,
      input logic [7:0] axlen
   );
      begin
         axi4_di_beat_index_in_range = beat_index <= axlen;
      end
   endfunction

   function automatic bit axi4_di_tracked_beat_in_range(
      input logic [2:0] tracked_beat,
      input logic [7:0] axlen
   );
      begin
         axi4_di_tracked_beat_in_range =
            axi4_di_beat_index_in_range({5'h0, tracked_beat}, axlen);
      end
   endfunction

   function automatic bit axi4_di_is_tracked_beat(
      input logic [2:0] beat_index,
      input logic [2:0] tracked_beat
   );
      begin
         axi4_di_is_tracked_beat = beat_index == tracked_beat;
      end
   endfunction

   function automatic bit axi4_di_is_last_beat(
      input logic [7:0] beat_index,
      input logic [7:0] axlen
   );
      begin
         axi4_di_is_last_beat = beat_index == axlen;
      end
   endfunction

   function automatic bit axi4_di_last_matches_len(
      input logic [7:0] beat_index,
      input logic [7:0] axlen,
      input logic       last
   );
      begin
         axi4_di_last_matches_len = last == axi4_di_is_last_beat(beat_index, axlen);
      end
   endfunction

   function automatic logic [2:0] axi4_di_next_fifo_index3(
      input logic [2:0] index
   );
      begin
         axi4_di_next_fifo_index3 = index + 3'h1;
      end
   endfunction

   function automatic logic [2:0] axi4_di_next_beat_index3(
      input logic [2:0] index
   );
      begin
         axi4_di_next_beat_index3 = index + 3'h1;
      end
   endfunction

   function automatic logic [7:0] axi4_di_next_beat_index8(
      input logic [7:0] index
   );
      begin
         axi4_di_next_beat_index8 = index + 8'h01;
      end
   endfunction

   function automatic bit axi4_di_ready_with_bounded_stall(
      input logic can_accept,
      input logic valid,
      input logic ready_choice,
      input logic stall_limit_reached
   );
      begin
         axi4_di_ready_with_bounded_stall =
            can_accept && (!valid || ready_choice || stall_limit_reached);
      end
   endfunction

   function automatic bit axi4_di_stall_counter_increments(
      input logic valid,
      input logic ready,
      input logic stall_limit_reached
   );
      begin
         axi4_di_stall_counter_increments =
            valid && !ready && !stall_limit_reached;
      end
   endfunction

   function automatic bit axi4_di_ready_pulse_next(
      input logic ready_q,
      input logic valid,
      input logic can_accept,
      input logic ready_choice,
      input logic stall_limit_reached
   );
      begin
         axi4_di_ready_pulse_next =
            !ready_q && can_accept && valid &&
            (ready_choice || stall_limit_reached);
      end
   endfunction

   function automatic logic [31:0] axi4_di_incr_beat_addr32(
      input logic [31:0] base,
      input logic [7:0]  beat_index,
      input logic [2:0]  axsize
   );
      begin
         axi4_di_incr_beat_addr32 = base + ({{24{1'b0}}, beat_index} << axsize);
      end
   endfunction

   function automatic logic [2:0] axi4_di_slot_from_addr32(
      input logic [31:0] base,
      input logic [31:0] addr
   );
      begin
         axi4_di_slot_from_addr32 = addr[4:2] - base[4:2];
      end
   endfunction

   function automatic logic [2:0] axi4_di_slot_from_beat_addr32(
      input logic [31:0] base,
      input logic [31:0] addr,
      input logic [2:0]  beat_index
   );
      begin
         axi4_di_slot_from_beat_addr32 =
            axi4_di_slot_from_addr32(base, addr) + beat_index;
      end
   endfunction

   function automatic bit axi4_di_same_32byte_window(
      input logic [31:0] base,
      input logic [31:0] addr
   );
      begin
         axi4_di_same_32byte_window = addr[31:5] == base[31:5];
      end
   endfunction

   function automatic bit axi4_di_targets_tracked_slot32(
      input logic [31:0] base,
      input logic [31:0] addr,
      input logic [2:0]  tracked_beat
   );
      begin
         axi4_di_targets_tracked_slot32 =
            axi4_di_same_32byte_window(base, addr) &&
            axi4_di_is_tracked_beat(
               axi4_di_slot_from_addr32(base, addr),
               tracked_beat);
      end
   endfunction

   function automatic bit axi4_di_beat_targets_tracked_slot32(
      input logic [31:0] base,
      input logic [31:0] addr,
      input logic [2:0]  beat_index,
      input logic [2:0]  tracked_beat
   );
      begin
         axi4_di_beat_targets_tracked_slot32 =
            axi4_di_same_32byte_window(base, addr) &&
            axi4_di_is_tracked_beat(
               axi4_di_slot_from_beat_addr32(base, addr, beat_index),
               tracked_beat);
      end
   endfunction
endpackage

`endif
