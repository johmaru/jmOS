const std = @import("std");

pub const uart_base: usize = 0x40013800;
pub const uart_sr: *volatile u32 = @ptrFromInt(uart_base + 0x00);
pub const uart_cr1: *volatile u32 = @ptrFromInt(uart_base + 0x0C);
pub const uart_dr: *volatile u32 = @ptrFromInt(uart_base + 0x04);

pub fn show_message(message: []const u8) void {
    for (message) |c| {
        while ((uart_sr.* & 0x80) == 0) {}
        uart_dr.* = @as(u32, c);
    }
}
