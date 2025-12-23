const std = @import("std");
const jmOS = @import("jmOS");
const ch32v003 = @import("ch32v003");
const trap = @import("trap.zig");
const console = @import("lib/console.zig");

export fn uart_putc(ch: u8) callconv(.c) void {
    while ((ch32v003.uart_sr.* & (1 << 7)) == 0) {}
    ch32v003.uart_dr.* = ch;
}

export fn _start() linksection(".text.entry") callconv(.naked) void {
    asm volatile (
        \\ li sp, 0x20000800
        \\ call main
        \\ j .
    );
}

export fn main() void {
    const mtvec_val = @intFromPtr(&trap.trap_entry);

    asm volatile (
        \\ csrw mtvec, %[val]
        :
        : [val] "r" (mtvec_val & ~@as(usize, 0x3)),
    );

    ch32v003.uart_cr1.* = 0x2008;

    console.Tui.init(&uart_putc);
    console.Tui.clearScreen();

    console.Tui.setColor(console.Tui.Color.White, console.Tui.Color.Blue);
    console.Tui.drawBox(5, 3, 50, 10, " jmOS on CH32V003 ");

    console.Tui.locate(7, 5);
    console.Tui.print("Welcome to jmOS running on CH32V003!");

    console.Tui.locate(7, 7);
    console.Tui.print("Counting in RAM:");

    var idx: u32 = 0;
    const ram_monitor: *volatile u32 = @ptrFromInt(0x20000000);

    while (true) {
        idx += 1;
        ram_monitor.* = idx;

        var delay: u32 = 0;
        while (delay < 100000) : (delay += 1) {
            std.mem.doNotOptimizeAway(delay);
        }
    }
}
