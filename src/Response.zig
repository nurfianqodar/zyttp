const Response = @This();
const std = @import("std");

conn: *std.net.Server.Connection,
body: []const u8,
headers: std.StringHashMap([]const u8),
status: StatusCode,

pub fn init(allocator: std.mem.Allocator, conn: *std.net.Server.Connection) !Response {
    var headers = std.StringHashMap([]const u8).init(allocator);
    try headers.put("Content-Type", "text/plain");
    return Response{
        .conn = conn,
        .body = "",
        .headers = headers,
        .status = StatusCode.OK,
    };
}

pub fn setBody(self: *Response, body: []const u8) void {
    self.body = body;
}

pub fn setHeader(self: *Response, key: []const u8, value: []const u8) !void {
    try self.headers.put(key, value);
}

pub fn send(self: *Response) !void {
    const response = try self.generateResponse();
    _ = try self.conn.stream.writeAll(response);
}

fn generateResponse(self: *Response) ![]u8 {
    var buffer = std.ArrayList(u8).init(self.headers.allocator);
    defer buffer.deinit();

    try buffer.writer().print("HTTP/1.1 {d} {s}\r\n", .{ @intFromEnum(self.status), self.getStatusText() });

    var iter = self.headers.iterator();
    while (iter.next()) |entry| {
        try buffer.writer().print("{s}: {s}\r\n", .{ entry.key_ptr.*, entry.value_ptr.* });
    }

    try buffer.writer().print("Content-Length: {d}\r\n\r\n", .{self.body.len});
    try buffer.appendSlice(self.body);

    return buffer.toOwnedSlice();
}

fn getStatusText(self: *Response) []const u8 {
    return switch (self.status) {
        .OK => "OK",
        .BAD_REQUEST => "Bad Request",
        .NOT_FOUND => "Not Found",
        .INTERNAL_SERVER_ERROR => "Internal Server Error",
        else => "Unknown",
    };
}

pub const StatusCode = enum(u16) {
    CONTINUE = 100,
    OK = 200,
    CREATED = 201,
    BAD_REQUEST = 400,
    NOT_FOUND = 404,
    INTERNAL_SERVER_ERROR = 500,
};
