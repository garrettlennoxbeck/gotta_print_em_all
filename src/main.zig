const std = @import("std");
const format = @import("format.zig");
const json = @import("json.zig");

fn init_pokedex(life_allocator: std.mem.Allocator) !std.StringArrayHashMap(format.Pokemon) {
    // Open our file, create a buffered reader for it.
    const pokedex_file = try std.fs.cwd().openFile("gen8nd.json", .{});
    defer pokedex_file.close();
    var buffered_reader = std.io.bufferedReader(pokedex_file.reader());
    var pokedex_reader = buffered_reader.reader();

    // This arena allocator is only for function-scoped temp allocations
    var temp_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer temp_arena.deinit();
    const temp_allocator = temp_arena.allocator();
    var pokedex_json_reader = std.json.reader(temp_allocator, pokedex_reader);

    // Normally, this operation would require 3 entire passes through the data.
    //  1.  Read the entire json into a memory buffer
    //      to prevent streaming use-after-free errors.
    //  2.  Parse the entire json with parseFromSlice(Value, ...)
    //  3.  Parse the resulting nested StringArrayHashMap(Value) into
    //      a single StringArrayHashMap(Pokemon)
    //
    // However, after only 2 small changes, this entire process is now 1 pass.
    //  1.  Read a stream of json data.
    //      One reaching the inner polymorphic type, recursively call
    //      parseFromTokenSourceLeaky(Pokemon, ...) to parse exactly
    //      the data we need.
    const pokedex_parsed = try std.json.parseFromTokenSourceLeaky(
        json.JsonPokedex,
        life_allocator,
        &pokedex_json_reader,
        .{},
    );
    return pokedex_parsed.gen8nd.map;
}

pub fn main() !void {
    // This will hold allocations that will live for the lifetime of the program
    var life_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer life_arena.deinit();
    const life_allocator = life_arena.allocator();

    const pokedex = try init_pokedex(life_allocator);

    // Find and store the longest pokemon name
    for (pokedex.keys()) |pokemon_name| {
        if (pokemon_name.len > format.longest_pokemon_name_length) {
            format.longest_pokemon_name_length = pokemon_name.len;
        }
    }

    // Print 'em all
    var iterator = pokedex.iterator();
    while (iterator.next()) |pokemon| {
        std.debug.print("{}", .{pokemon.value_ptr.*});
    }
}
