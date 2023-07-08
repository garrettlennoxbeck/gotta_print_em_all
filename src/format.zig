const std = @import("std");

pub const longest_type_name_length = init: {
    var longest = 0;
    for (@typeInfo(Type).Enum.fields) |field| {
        longest = @max(longest, field.name.len);
    }
    break :init longest;
};
/// Types, with a custom formatter to be printed
/// in the correct color
pub const Type = enum {
    Normal,
    Fire,
    Water,
    Electric,
    Grass,
    Ice,
    Fighting,
    Poison,
    Ground,
    Flying,
    Psychic,
    Bug,
    Rock,
    Ghost,
    Dragon,
    Dark,
    Steel,
    Fairy,

    pub fn format(
        self: Type,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        const color = TypeColors.get(self);
        try writer.print(
            "\x1b[38;2;0;0;0m\x1b[48;2;{d};{d};{d}m{s}\x1b[0m",
            .{ color.r, color.g, color.b, @tagName(self) },
        );
    }
};
/// Should this be a struct, an array of length 3, a u24?
/// I hate making decisions...
const Color = struct {
    r: u8 = 0,
    g: u8 = 0,
    b: u8 = 0,
    fn get(r: u8, g: u8, b: u8) @This() {
        return .{ .r = r, .g = g, .b = b };
    }
};

/// A mapping of types to their color. Very convenient.
pub const TypeColors = std.enums.EnumArray(Type, Color).init(.{
    .Normal = Color.get(0xa8, 0xa8, 0x78),
    .Fire = Color.get(0xf0, 0x80, 0x30),
    .Water = Color.get(0x68, 0x90, 0xf0),
    .Electric = Color.get(0xf8, 0xd0, 0x30),
    .Grass = Color.get(0x78, 0xc8, 0x50),
    .Ice = Color.get(0x98, 0xd8, 0xd8),
    .Fighting = Color.get(0xc0, 0x30, 0x28),
    .Poison = Color.get(0xa0, 0x40, 0xa0),
    .Ground = Color.get(0xe0, 0xc0, 0x68),
    .Flying = Color.get(0xa8, 0x90, 0xf0),
    .Psychic = Color.get(0xf8, 0x58, 0x88),
    .Bug = Color.get(0xa8, 0xb8, 0x20),
    .Rock = Color.get(0xb8, 0xa0, 0x38),
    .Ghost = Color.get(0x70, 0x58, 0x98),
    .Dragon = Color.get(0x70, 0x38, 0xf8),
    .Dark = Color.get(0x70, 0x58, 0x48),
    .Steel = Color.get(0xb8, 0xb8, 0xd0),
    .Fairy = Color.get(0xee, 0x99, 0xac),
});

/// This will be initialized in our main()
pub var longest_pokemon_name_length: usize = 0;
/// The data associated with a pokemon.
/// This format is reflected in the json being read in.
pub const Pokemon = struct {
    abilities: [][]const u8,
    moves: [][]const u8,
    name: []const u8,
    stats: Stats,
    types: []Type,
    tier: []const u8,
    const Stats = struct {
        hp: u8,
        atk: u8,
        def: u8,
        spatk: u8,
        spdef: u8,
        spd: u8,
    };

    pub fn format(
        self: Pokemon,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;

        const spaces = " " ** 30;
        // Print the name of the pokemon in bold
        try writer.print("\x1b[1m{s}\x1b[0m{s}", .{
            self.name,
            spaces[0 .. 1 + longest_pokemon_name_length - self.name.len],
        });

        // Print hp, def, spdef
        inline for ([3][]const u8{ "hp", "def", "spdef" }) |stat| {
            try writer.print("{s}: {s}{d: <5}", .{
                stat,
                spaces[0..3 -| stat.len],
                @field(self.stats, stat),
            });
        }

        // Print the first type
        try writer.print("\n{s}{s}", .{
            self.types[0],
            spaces[0 .. 1 + longest_type_name_length - @tagName(self.types[0]).len],
        });

        // Print the second type
        if (self.types.len > 1) {
            const type_lengths = 1 + longest_type_name_length + @tagName(self.types[1]).len;
            try writer.print("{}{s} ", .{
                self.types[1],
                spaces[0 .. longest_pokemon_name_length - type_lengths],
            });
        } else {
            const type_lengths = 1 + longest_type_name_length;
            try writer.print("{s} ", .{
                spaces[0 .. longest_pokemon_name_length - type_lengths],
            });
        }

        // Print spd, atk, spatk
        inline for ([3][]const u8{ "spd", "atk", "spatk" }) |stat| {
            try writer.print("{s}: {s}{d: <5}", .{
                stat,
                spaces[0..3 -| stat.len],
                @field(self.stats, stat),
            });
        }

        try writer.print("\n\n", .{});
    }
};
