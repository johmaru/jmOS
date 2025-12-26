const std = @import("std");
const ch32v003 = @import("ch32v003");

pub export fn trap_entry() align(4) linksection(".text.trap") callconv(.naked) void {
    asm volatile (
        \\ sub sp, sp, #256
        \\ stp x0, x1, [sp, #16 * 0]
        \\ stp x2, x3, [sp, #16 * 1]
        \\ stp x4, x5, [sp, #16 * 2]
        \\ stp x6, x7, [sp, #16 * 3]
        \\ stp x8, x9, [sp, #16 * 4]
        \\ stp x10, x11, [sp, #16 * 5]
        \\ stp x12, x13, [sp, #16 * 6]
        \\ stp x14, x15, [sp, #16 * 7]
        \\ stp x16, x17, [sp, #16 * 8]
        \\ stp x18, x19, [sp, #16 * 9]
        \\ stp x20, x21, [sp, #16 * 10]
        \\ stp x22, x23, [sp, #16 * 11]
        \\ stp x24, x25, [sp, #16 * 12]
        \\ stp x26, x27, [sp, #16 * 13]
        \\ stp x28, x29, [sp, #16 * 14]
        \\ str x30, [sp, #16 * 15]
        \\ bl handle_trap
        \\ ldr x30, [sp, #16 * 15]
        \\ ldp x28, x29, [sp, #16 * 14]
        \\ ldp x26, x27, [sp, #16 * 13]
        \\ ldp x24, x25, [sp, #16 * 12]
        \\ ldp x22, x23, [sp, #16 * 11]
        \\ ldp x20, x21, [sp, #16 * 10]
        \\ ldp x18, x19, [sp, #16 * 9]
        \\ ldp x16, x17, [sp, #16 * 8]
        \\ ldp x14, x15, [sp, #16 * 7]
        \\ ldp x12, x13, [sp, #16 * 6]
        \\ ldp x10, x11, [sp, #16 * 5]
        \\ ldp x8, x9, [sp, #16 * 4]
        \\ ldp x6, x7, [sp, #16 * 3]
        \\ ldp x4, x5, [sp, #16 * 2]
        \\ ldp x2, x3, [sp, #16 * 1]
        \\ ldp x0, x1, [sp, #16 * 0]
        \\ add sp, sp, #256
        \\ eret
    );
}

export fn handle_trap() void {
    var esr: u64 = 0;
    var elr: u64 = 0;

    asm volatile (
        \\ mrs %[ret], esr_el1
        : [ret] "=r" (esr),
    );
    asm volatile (
        \\ mrs %[ret], elr_el1
        : [ret] "=r" (elr),
    );

    while (true) {}
}
