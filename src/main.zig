const std = @import("std");
const jmOS = @import("jmOS");
const ch32v003 = @import("ch32v003");
const trap = @import("trap.zig");
const console = @import("lib/console.zig");
const ui = @import("lib/ui.zig");

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

    const mainWindowRect = ui.Rect{
        .x = 5,
        .y = 3,
        .width = 60,
        .height = 20,
    };

    console.Tui.setColor(console.Tui.Color.White, console.Tui.Color.Blue);
    console.Tui.drawBoxRect(mainWindowRect, " jmOS on CH32V003 ");

    var panel = ui.StackPanel.init(mainWindowRect.padding(1));

    const headerRect = panel.dockTop(2);
    console.Tui.locate(headerRect.x, headerRect.y);
    console.Tui.print("Welcome to jmOS running on CH32V003!");

    const separatorRect = panel.dockTop(1);
    console.Tui.locate(separatorRect.x, separatorRect.y);
    console.Tui.print("------------------------------------------------");

    const contentRect = panel.dockTop(3);
    console.Tui.locate(contentRect.x, contentRect.y);
    console.Tui.print("CPU: CH32V003 (RISC-V)");
    console.Tui.locate(contentRect.x, contentRect.y + 1);
    console.Tui.print("RAM: 2KB / Flash: 16KB");

    const separatorRect2 = panel.dockTop(1);
    console.Tui.locate(separatorRect2.x, separatorRect2.y);
    console.Tui.print("------------------------------------------------");

    const logRect = panel.fillRemanining();

    var logger = ui.LogWindow.init(logRect);

    var input_buffer = console.RingBuffer{};

    while (true) {
        console.Tui.setColor(.Yellow, .Blue);

        if ((ch32v003.uart_sr.* & 1 << 5) != 0) {
            const data = @as(u8, @truncate(ch32v003.uart_dr.*));
            input_buffer.push(data);
        }

        if (input_buffer.pop()) |key| {
            if (key == 'a') {
                logger.println("Command: Task A started.");
            } else if (key == 'b') {
                logger.println("Command: Task B started.");
            } else {
                logger.println("Unknown command received.");
            }
        }

        var delay: u32 = 0;
        while (delay < 5000000) : (delay += 1) {
            std.mem.doNotOptimizeAway(delay);
        }
    }
}
