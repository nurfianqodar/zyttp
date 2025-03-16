const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseSafe,
    });

    const lib_mod = b.addModule("zyttp", .{
        .root_source_file = b.path("src/zyttp.zig"),
        .target = target,
        .optimize = optimize,
    });
    const lib = b.addLibrary(.{
        .name = "zyttp",
        .root_module = lib_mod,
        .linkage = .static,
    });
    b.installArtifact(lib);

    const test_lib = b.addTest(.{
        .root_module = lib_mod,
    });
    const run_test = b.addRunArtifact(test_lib);
    const test_step = b.step("test", "Testing lib");
    test_step.dependOn(&run_test.step);
}
