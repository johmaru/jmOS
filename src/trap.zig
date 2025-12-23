const std = @import("std");
const ch32v003 = @import("ch32v003");

pub export fn trap_entry() align(4) linksection(".text.trap") callconv(.naked) void {
    asm volatile (
        \\ addi sp, sp, -64
        \\ sw ra, 0(sp)
        \\ sw t0, 4(sp)
        \\ sw t1, 8(sp)
        \\ sw t2, 12(sp)
        \\ sw s0, 16(sp)
        \\ sw s1, 20(sp)
        \\ sw a0, 24(sp)
        \\ sw a1, 28(sp)
        \\ sw a2, 32(sp)
        \\ sw a3, 36(sp)
        \\ sw a4, 40(sp)
        \\ sw a5, 44(sp)
        \\ call handle_trap
        \\ lw ra, 0(sp)
        \\ lw t0, 4(sp)
        \\ lw t1, 8(sp)
        \\ lw t2, 12(sp)
        \\ lw s0, 16(sp)
        \\ lw s1, 20(sp)
        \\ lw a0, 24(sp)
        \\ lw a1, 28(sp)
        \\ lw a2, 32(sp)
        \\ lw a3, 36(sp)
        \\ lw a4, 40(sp)
        \\ lw a5, 44(sp)
        \\ addi sp, sp, 64
        \\ mret
    );
}

export fn handle_trap() void {
    var mcause: usize = 0;
    var mepc: usize = 0;

    asm volatile (
        \\ csrr %[ret], mcause
        : [ret] "=r" (mcause),
    );

    asm volatile (
        \\ csrr %[ret], mepc
        : [ret] "=r" (mepc),
    );

    ch32v003.show_message("\n!!! EXCEPTION OCCURRED !!!\n");

    while (true) {}
}
