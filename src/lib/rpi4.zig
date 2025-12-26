const std = @import("std");

const MMIO_BASE: usize = 0xFE00_0000;

pub const GPIO = struct {
    const BASE = MMIO_BASE + 0x20_0000;
    pub const GPFSEL1 = @as(*volatile u32, @ptrFromInt(BASE + 0x04));
    pub const GPPUPPDN0 = @as(*volatile u32, @ptrFromInt(BASE + 0xE4));
};

pub const UART0 = struct {
    const BASE = MMIO_BASE + 0x201_0000;
    pub const DR = @as(*volatile u32, @ptrFromInt(BASE + 0x00));
    pub const FR = @as(*volatile u32, @ptrFromInt(BASE + 0x18));
    pub const IBRD = @as(*volatile u32, @ptrFromInt(BASE + 0x24));
    pub const FBRD = @as(*volatile u32, @ptrFromInt(BASE + 0x28));
    pub const LCRH = @as(*volatile u32, @ptrFromInt(BASE + 0x2C));
    pub const CR = @as(*volatile u32, @ptrFromInt(BASE + 0x30));
    pub const ICR = @as(*volatile u32, @ptrFromInt(BASE + 0x44));
};

pub fn uart_init() void {
    UART0.CR.* = 0;

    var selector = GPIO.GPFSEL1.*;
    selector &= ~(@as(u32, 7) << 12);
    selector |= (@as(u32, 4) << 12);
    selector &= ~(@as(u32, 7) << 15);
    selector |= (@as(u32, 4) << 15);
    GPIO.GPFSEL1.* = selector;

    var pupd = GPIO.GPPUPPDN0.*;
    pupd &= ~(@as(u32, 3) << 28);
    pupd &= ~(@as(u32, 3) << 30);
    GPIO.GPPUPPDN0.* = pupd;

    UART0.ICR.* = 0x7FF;

    UART0.IBRD.* = 26;
    UART0.FBRD.* = 3;
    UART0.LCRH.* = (1 << 4) | (1 << 5) | (1 << 6);
    UART0.CR.* = (1 << 0) | (1 << 8) | (1 << 9);
}

pub fn uart_putc(c: u8) void {
    while ((UART0.FR.* & (1 << 5)) != 0) {}
    UART0.DR.* = c;
}

pub fn uart_getc() u8 {
    while ((UART0.FR.* & (1 << 4)) != 0) {
        return null;
    }
    return @as(u8, @truncate(UART0.DR.*));
}
