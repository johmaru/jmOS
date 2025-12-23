const std = @import("std");

pub const Tui = struct {
    var putchar_fn: PutCharFn = undefined;

    pub const PutCharFn = *const fn (u8) callconv(.c) void;

    pub const Color = enum(u8) {
        Black = 0,
        Red = 1,
        Green = 2,
        Yellow = 3,
        Blue = 4,
        Magenta = 5,
        Cyan = 6,
        White = 7,
    };

    pub fn init(putchar: PutCharFn) void {
        putchar_fn = putchar;
    }

    fn put(c: u8) void {
        putchar_fn(c);
    }

    pub fn print(str: []const u8) void {
        for (str) |c| {
            put(c);
        }
    }

    pub fn printInt(value: anytype) void {
        var n = value;
        if (value < 0) {
            put('-');
            n = -n;
        }

        if (n == 0) {
            put('0');
            return;
        }

        var buffer: [12]u8 = undefined;
        var idx: usize = 0;

        var val = if (@TypeOf(n) == i32) @as(u32, @intCast(n)) else n;

        while (val > 0) {
            buffer[idx] = @intCast((val % 10) + '0');
            val = val / 10;
            idx += 1;
        }

        while (idx > 0) {
            idx -= 1;
            put(buffer[idx]);
        }
    }

    fn esc() void {
        put('\x1B');
        put('[');
    }

    pub fn clearScreen() void {
        esc();
        print("2J");
        esc();
        print("H");
    }

    pub fn locate(x: u32, y: u32) void {
        esc();
        printInt(y);
        put(';');
        printInt(x);
        put('H');
    }

    pub fn setColor(fg: Color, bg: Color) void {
        esc();
        put('3');
        printInt(@intFromEnum(fg));
        put(';');
        put('4');
        printInt(@intFromEnum(bg));
        put('m');
    }

    pub fn resetColor() void {
        esc();
        print("0m");
    }

    pub fn drawBox(x: u32, y: u32, width: u32, height: u32, title: ?[]const u8) void {
        // Top border
        locate(x, y);
        put('+');
        var idx: u32 = 0;
        while (idx < width - 2) : (idx += 1) {
            put('-');
        }

        if (title) |t| {
            locate(x + 2, y);
            print(t);
        }

        // Side borders
        idx = 1;
        while (idx < height - 1) : (idx += 1) {
            locate(x, y + idx);
            put('|');
            locate(x + width - 1, y + idx);
            put('|');
        }

        // Bottom border
        locate(x, y + height - 1);
        put('+');
        idx = 0;
        while (idx < width - 2) : (idx += 1) {
            put('-');
        }
        put('+');
    }
};
