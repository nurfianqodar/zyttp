const Request = @This();
const Server = @import("Server.zig");
const std = @import("std");

conn: *std.net.Server.Connection,
method: Method,
path: []const u8,
version: []const u8,
headers: std.StringHashMap([]const u8),
body: []const u8,

pub fn parse(buffer: []u8, conn: *std.net.Server.Connection) RequestError!Request {
    var lines = std.mem.tokenizeSequence(u8, buffer, "\r\n");

    // Parse request line
    const request_line = lines.next() orelse return RequestError.InvalidRequest;
    var request_parts = std.mem.tokenizeSequence(u8, request_line, " ");
    const method_str = request_parts.next() orelse return RequestError.InvalidRequest;
    const path = request_parts.next() orelse return RequestError.InvalidRequest;
    const version = request_parts.next() orelse return RequestError.InvalidRequest;

    // Convert method string to enum
    const method = std.meta.stringToEnum(Method, method_str) orelse return RequestError.InvalidMethod;

    // Initialize headers
    var headers = std.StringHashMap([]const u8).init(std.heap.page_allocator);
    defer headers.deinit();

    while (lines.next()) |line| {
        if (line.len == 0) break; // End of headers
        var header_parts = std.mem.tokenizeSequence(u8, line, ": ");
        const key = header_parts.next() orelse continue;
        const value = header_parts.next() orelse continue;
        headers.put(key, value) catch return RequestError.OutOfMemory;
    }

    // Extract body if exists
    var body: []const u8 = "";
    if (lines.rest().len > 0) {
        body = lines.rest();
    }

    return Request{
        .conn = conn,
        .method = method,
        .path = path,
        .version = version,
        .headers = headers,
        .body = body[0..],
    };
}

pub const Method = enum {
    GET,
    POST,
    PUT,
    PATCH,
    DELETE,
    HEAD,
    OPTIONS,
    TRACE,
    CONNECT,
};

pub const RequestError = error{
    InvalidRequest,
    InvalidMethod,
    OutOfMemory,
};
