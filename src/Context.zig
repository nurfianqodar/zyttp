const Context = @This();
const std = @import("std");
const Request = @import("Request.zig");
const Response = @import("Response.zig");

req: *Request,
res: *Response,

pub fn init(allocator: std.mem.Allocator, conn: *std.net.Server.Connection) !Context {
    var stream = conn.stream;
    defer stream.close();

    var buf: [1024]u8 = undefined;
    _ = try stream.read(&buf);
    // Create context instance
    // Context contains request and responses
    var request = try Request.parse(buf[0..], conn);
    var response = try Response.init(allocator, conn);
    const context = Context{
        .req = &request,
        .res = &response,
    };
    return context;
}
