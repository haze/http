const HeaderName = @import("name.zig").HeaderName;
const HeaderType = @import("name.zig").HeaderType;
const HeaderValue = @import("value.zig").HeaderValue;

pub const Header = struct {
    name: HeaderName,
    value: []const u8,

    pub fn as_slice(comptime headers: anytype) []Header {
        const typeof = @TypeOf(headers);
        const typeinfo = @typeInfo(typeof);
        switch (typeinfo) {
            .Struct => |obj| {
                comptime {
                    var result: [obj.fields.len]Header = undefined;
                    var i = 0;
                    while (i < obj.fields.len) {
                        _ = HeaderName.parse(headers[i][0]) catch |err| {
                            @compileError("Invalid header name: " ++ headers[i][0]);
                        };

                        _ = HeaderValue.parse(headers[i][1]) catch |err| {
                            @compileError("Invalid header value: " ++ headers[i][1]);
                        };

                        var _type = HeaderType.from_bytes(headers[i][0]);
                        var name = headers[i][0];
                        var value = headers[i][1];
                        result[i] = Header{ .name = .{ .type = _type, .value = name }, .value = value };
                        i += 1;
                    }
                    return &result;
                }
            },
            else => {
                @compileError("The parameter type must be an anonymous list literal.\n" ++ "Ex: Header.as_slice(.{.{\"Gotta-Go\", \"Fast!\"}});");
            },
        }
    }
};

const std = @import("std");
const expect = std.testing.expect;

test "AsSlice" {
    var result = Header.as_slice(.{
        .{ "Content-Length", "9000" },
        .{ "Gotta-Go", "Fast!" },
    });
    expect(result.len == 2);
    expect(result[0].name.type == .ContentLength);
    expect(std.mem.eql(u8, result[0].name.raw(), "Content-Length"));
    expect(std.mem.eql(u8, result[0].value, "9000"));
    expect(result[1].name.type == .Custom);
    expect(std.mem.eql(u8, result[1].name.raw(), "Gotta-Go"));
    expect(std.mem.eql(u8, result[1].value, "Fast!"));
}
