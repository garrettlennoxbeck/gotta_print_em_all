const std = @import("std");
const format = @import("format.zig");

/// This type allows for auomated parsing of a json into a
/// StringArrayHashMap from a string to the given type.
fn JsonHashmap(comptime T: type) type {
    return struct {
        map: std.StringArrayHashMap(T),

        pub fn jsonParse(
            allocator: std.mem.Allocator,
            source: anytype,
            options: std.json.ParseOptions,
        ) !@This() {
            var map = std.StringArrayHashMap(T).init(allocator);
            errdefer map.deinit();

            // Consume the opening brace for this object
            if (.object_begin != try source.next()) return error.UnexpectedToken;
            //  Consume the entries of this object
            while (true) {
                switch (try source.nextAlloc(allocator, .alloc_always)) {
                    .allocated_string => |string| {
                        var resolved_options = options;
                        // We need this option because we're only parsing
                        // one struct from the entire json;
                        // we won't end with an EOF
                        resolved_options.allow_partial = true;
                        // We need this options because our source could be
                        // a stream. If it is, any strings referenced
                        // in the parse will cause use-after-free
                        resolved_options.allocate = .alloc_always;
                        const value = try std.json.parseFromTokenSourceLeaky(
                            T,
                            allocator,
                            source,
                            resolved_options,
                        );
                        try map.put(string, value);
                    },
                    // We've reached the closing brace for this overall object
                    .object_end => {
                        return @This(){ .map = map };
                    },
                    // We're only expecting strings (the keys) and our closing brace
                    else => unreachable,
                }
            }
        }
    };
}
/// This type exists to peel the outer layer off the json
pub const JsonPokedex = struct {
    gen8nd: JsonHashmap(format.Pokemon),
};
