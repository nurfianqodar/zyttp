/// HTTP Server Struct
const Server = @This();
const std = @import("std");
const Router = @import("Router.zig");
const Request = @import("Request.zig");
const Response = @import("Response.zig");
const Context = @import("Context.zig");

// Allocator
allocator: std.mem.Allocator,
// Server options
options: ServerOptions,

// Server constructor
pub fn init(allocator: std.mem.Allocator, options: ServerOptions) Server {
    return Server{
        .allocator = allocator,
        .options = options,
    };
}

// Run server
pub fn run(self: *const Server) !void {
    var address = try std.net.Address.resolveIp(self.options.host, self.options.port);
    var server = try address.listen(.{
        .reuse_address = true,
    });
    std.debug.print("Server listening on {s}:{d}\n", .{
        self.options.host,
        self.options.port,
    });
    while (true) {
        var conn = server.accept() catch |err| {
            std.log.err("Error while accept connection: {}\n", .{err});
            continue;
        };
        self.handleConnection(&conn) catch |err| {
            std.log.err("Error while handle connection {}\n", .{err});
            continue;
        };
    }
}

fn handleConnection(self: *const Server, conn: *std.net.Server.Connection) !void {
    var context = try Context.init(self.allocator, conn);
    try self.options.root_router.handle(&context);
}

const ServerOptions = struct {
    host: []const u8,
    port: u16,
    root_router: *Router,
};

test "run" {
    const ally = std.testing.allocator;
    const server = Server.init(ally, .{
        .port = 8000,
        .host = "127.0.0.1",
        .root_router = undefined, // FIXME
    });

    try server.run();
}
