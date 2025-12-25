const std = @import("std");
const console = @import("console.zig");

pub const Rect = struct {
    x: u8,
    y: u8,
    width: u8,
    height: u8,

    pub fn padding(self: Rect, pad: u8) Rect {
        if (self.width <= pad * 2 or self.height <= pad * 2) return self;
        return Rect{
            .x = self.x,
            .y = self.y,
            .width = self.width - pad * 2,
            .height = self.height - pad * 2,
        };
    }
};

pub const StackPanel = struct {
    container: Rect,
    current_y: u8,

    pub fn init(container: Rect) StackPanel {
        return StackPanel{
            .container = container,
            .current_y = container.y,
        };
    }

    pub fn dockTop(self: *StackPanel, height: u8) Rect {
        const rect = Rect{
            .x = self.container.x,
            .y = self.current_y,
            .width = self.container.width,
            .height = height,
        };
        self.current_y += height;
        return rect;
    }

    pub fn fillRemanining(self: *StackPanel) Rect {
        return Rect{
            .x = self.container.x,
            .y = self.current_y,
            .width = self.container.width,
            .height = self.container.y + self.container.height - self.current_y,
        };
    }
};

pub const LogWindow = struct {
    rect: Rect,
    current_line: u8,
    current_col: u8,

    pub fn init(rect: Rect) LogWindow {
        return LogWindow{
            .rect = rect,
            .current_line = 0,
            .current_col = 0,
        };
    }

    pub fn println(self: *LogWindow, text: []const u8) void {
        if (text.len > 0) {
            console.Tui.locate(self.rect.x + self.current_col, self.rect.y + self.current_line);
            console.Tui.print(text);
        }
        self.current_line += 1;
        if (self.current_line >= self.rect.height) {
            self.current_line = 0;
        }

        console.Tui.locate(self.rect.x, self.rect.y + self.current_line);
        var idx2: u32 = 0;
        while (idx2 < self.rect.width) : (idx2 += 1) {
            console.Tui.print(" ");
        }

        console.Tui.locate(self.rect.x, self.rect.y + self.current_line);
        console.Tui.print("> ");
        self.current_col = 2;
    }

    pub fn append(self: *LogWindow, text: []const u8) void {
        for (text) |char| {
            if (self.current_col >= self.rect.width) {
                self.current_line += 1;
                if (self.current_line >= self.rect.height) {
                    self.current_line = 0;
                }

                console.Tui.locate(self.rect.x, self.rect.y + self.current_line);
                var idx: u32 = 0;
                while (idx < self.rect.width) : (idx += 1) {
                    console.Tui.print(" ");
                }
                self.current_col = 0;
            }
            console.Tui.locate(self.rect.x + self.current_col, self.rect.y + self.current_line);
            console.Tui.print(&[_]u8{char});
            self.current_col += 1;
        }
    }
};
