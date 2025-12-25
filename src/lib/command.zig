const std = @import("std");
const ui = @import("ui.zig");

pub const Execute = struct {
    pub fn runCommand(cmd: []const u8, logger: *ui.LogWindow) void {
        const command = checkArgumentsFromInput(cmd, logger);

        if (std.mem.eql(u8, command.parent_cmd, "help")) {
            if (command.args_count > 0) {
                logger.println("Help command does not take any arguments.");
            } else {
                logger.println("Available commands:");
                logger.println("  help - Show this help message");
                logger.println("  info - Show system information");
            }
        } else if (std.mem.eql(u8, command.parent_cmd, "info")) {
            logger.println("jmOS on CH32V003");
            logger.println("RISC-V CPU");
            logger.println("2KB RAM, 16KB Flash");
        } else if (cmd.len > 0) {
            logger.println("Unknown command: ");
            logger.append(cmd);
            logger.println("");
        }
    }

    pub const CommandStruct = struct {
        parent_cmd: []const u8,
        args: [8][]const u8,
        args_count: usize,
    };

    pub fn checkArgumentsFromInput(input: []const u8, logger: *ui.LogWindow) CommandStruct {
        var parts = std.mem.tokenizeAny(u8, input, " ");

        var cmd_struct = CommandStruct{
            .parent_cmd = "",
            .args = undefined,
            .args_count = 0,
        };

        if (parts.next()) |cmd| {
            cmd_struct.parent_cmd = cmd;
        }

        while (parts.next()) |part| {
            if (cmd_struct.args_count < cmd_struct.args.len) {
                if (std.mem.startsWith(u8, part, "-")) {
                    var arg_val = part;
                    if (std.mem.startsWith(u8, part, "--")) {
                        arg_val = part[2..];
                    } else {
                        arg_val = part[1..];
                    }

                    cmd_struct.args[cmd_struct.args_count] = arg_val;
                    cmd_struct.args_count += 1;
                } else {
                    logger.println("Invalid argument format: ");
                    logger.append(part);
                    logger.println("");
                }
            }
        }
        return cmd_struct;
    }
};
