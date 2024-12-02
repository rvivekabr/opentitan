// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Manually excluded FSM unreachable states.
//==================================================
// This file contains the Excluded objects
// Generated By User: chencindy
// Format Version: 2
// Date: Fri Feb  4 11:57:07 2022
// ExclMode: default
//==================================================
CHECKSUM: "979204326 3647041052"
INSTANCE: tb.dut.gen_fsm_scramble_enabled.u_checker_fsm
ANNOTATION: "UNR"
Fsm state_d "1410404563"
Transition Checking->RomAhead "341->917"
ANNOTATION: "UNR"
Fsm state_d "1410404563"
Transition KmacAhead->ReadingHigh "629->181"

// In rom_ctrl_scrambled_rom, the wire scr_nonce is having a fixed value and is a part of RHS of
// the continuous assignment on line 81 and 82
INSTANCE: tb.dut.gen_rom_scramble_enabled.u_rom
ANNOTATION: "Waived the continuous assignment block as RHS is a fixed wire"
Block 1 "3862690173" "assign data_scr_nonce = scr_nonce[(63 - Aw):0];"

// In tlul_rsp_intg_gen, the wires on the RHS of continuous assignment at L32 and L43 are having
// constant bits
INSTANCE: tb.dut.u_reg_regs.u_reg_if.u_rsp_intg_gen
ANNOTATION: "Waived the continuous assignment block on L32 and L43 as the RHS is a fixed wire"
Block 1 "461445014" "assign rsp_intg = tl_i.d_user.rsp_intg;"
Block 2 "2643129081" "assign data_intg = tl_i.d_user.data_intg;"

// In u_tl_adapter_rom, data_i is wired to paramter (DataWhenError)
INSTANCE: tb.dut.u_tl_adapter_rom.u_tlul_data_integ_enc_data.u_data_gen
ANNOTATION: "Waived the assignment as the input is wired to a parameter"
Block 1 "3318159292" "data_o = 39'(data_i);"
INSTANCE: tb.dut.u_tl_adapter_rom.u_tlul_data_integ_enc_instr.u_data_gen
Block 1 "3318159292" "data_o = 39'(data_i);"

INSTANCE: tb.dut.u_tl_adapter_rom
// wr_attr_error and wr_vld_error both depend on a_opcode != Get. wr_attr_error can exist without
//wr_vld_error but ErrOnWrite is wired to 1 inside the instantiation of tlul_adapter_sram in
//rom_ctrl.sv. Hence, if wr_attr_error is true then tl_i.a_opcode is PutFullData or PutPartialData
//which automatically sets wr_vld_error.
Condition 17 "3469950311" "(wr_attr_error | wr_vld_error | rd_vld_error | instr_error | tlul_error |
                            intg_error) 1 -1" (7 "100000")

// Because en_ifetch_i is hardwired to MuBi4True, instr_error can only be true if
// tl_i.a_user.instr_type is not a valid mubi value. But that gets seen in u_err as instr_type_err,
// causing tlul_error to be true in the adapter.
Condition 17 "3469950311" "(wr_attr_error | wr_vld_error | rd_vld_error | instr_error | tlul_error |
                            intg_error) 1 -1" (4 "000100")

// For rspfifo_rdata.error, it is pushed in rspfifo_wdata.error. If the error field is true, it
// means rerror_i[1] bit is true but the rerror_i bits are wired to 0 in the instantiation of the
// tlul_adapter_sram in rom_ctrl.sv.
Condition 4 "3638058042" "(rspfifo_rdata.error | reqfifo_rdata.error) 1 -1" (3 "10")

// The 011 case is not possible.
//
// Since we are asking that rspfifo_rvalid = 1, we know that if reqfifo_rvalid is true then d_valid
// will be true. As we ask that d_valid = 0, it follows that reqfifo_rvalid is false. This means
// that u_reqfifo is empty.
//
// For rspfifo_rvalid = 1, we must either have a response arriving now (which is visible because
// Pass=1) or have a stored response. In the first case, reqfifo_rvalid must be true (which is
// checked with the rvalidHighReqFifoEmpty assertion). But we know that reqfifo_rvalid must be
// false.
//
// For the second case, we must have had the request in the fifo and popped it before now. But this
// isn't possible, because the ROM always responds in a single cycle: the same cycle we would be
// popping the request from u_reqfifo.
Condition 21 "3623514242" "(d_valid & rspfifo_rvalid & (reqfifo_rdata.op == OpRead)) 1 -1" (1 "011")

// Condition 24 till 34 are excluded for the same reason. The requirements for the conditions are:
// 1) reqfifo_rvalid --> 1
// 2) rspfifo_rvalid --> 1
// 3) reqfifo_rdata.op --> opread
// 4) reqfifo_rdata.error --> 1
//
// We cannot see vld_rd_rsp && d_error. If d_error is true, we must have rspfifo_rdata.error or
// reqfifo_rdata.error. The first cannot happen, because the items in the response fifo have an
// error signal from rerror_i[1] and rom_ctrl connects rerror_i to zero. For the second to happen,
// we must have pushed in an item with error = 1, which means that error_internal was set. But that
// will have squashed the request, so req_o was low. As a result, the request fifo item will be
// popped again before anything appears in the response fifo.
Condition 24 "1059982851" "(vld_rd_rsp & ((~d_error))) 1 -1" (2 "10")

// The reason for condition 24 explains why we can't get (vld_rd_rsp && reqfifo_rdata.error) = 1 as
// if vld_rd_rsp = 1, this means that rspfifo_rvalid = 1. But when we have reqfifo_rdata.error, the
// request from the req_fifo gets popped again before becoming visible to response fifo. This also
// explains why we can't expect 1 and 11 for condition 25 and 26 respectively.
Condition 25 "2807788926" "((vld_rd_rsp && reqfifo_rdata.error) ? error_blanking_integ :
                            (vld_rd_rsp ? rspfifo_rdata.data_intg :
                            prim_secded_pkg::SecdedInv3932ZeroEcc)) 1 -1" (2 "1")
Condition 26 "561780173" "(vld_rd_rsp && reqfifo_rdata.error) 1 -1" (3 "11")

// We cannot see d_valid = 0 and d_error = 1. For d_error to be true, we need reqfifo_rvalid to be
// true. But then the only way for d_valid to be false is if rspfifo_rvalid is false (and
// reqfifo_rdata.op is OpRead).
//
// The ROM always services TL operations without back-pressure and responds in one cycle. As a
// result, after a request is be pushed into u_reqfifo, it is always popped again on the next cycle.
// As a result, if reqfifo_rvalid is true then rspfifo_wvalid will also be true and (because
// u_rspfifo is in pass-through mode) rspfifo_rvalid will be true.
Condition 34 "201396280" "(d_valid && d_error) 1 -1" (1 "01")

// It is impossible to see rvalid_i && !reqfifo_rvalid. If rvalid_i is true, the ROM is responding
// to a request that was sent on the previous cycle. Since it always responds in exactly one cycle,
// the request will not already have been popped from the request fifo, so reqfifo_rvalid must be
// true.
Condition 43 "721931741" "(rvalid_i & reqfifo_rvalid) 1 -1" (2 "10")
