const std = @import("std");

const httpz = @import("httpz");
const pg = @import("pg");

const Level = enum {
    genin,
    chuunin,
    jonin,
    sannin,
    anbu,
    kage,
    forbidden,

    pub fn to_string(self: *Level) []const 8 {
        switch (self) {
            .genin => "GENIN",
            .chuunin => "CHUUNIN",
            .jonin => "JONIN",
            .sannin => "SANNIN",
            .anbu => "ANBU",
            .kage => "KAGE",
            .forbidden => "FORBIDDEN",
        }
    }

    /// decided to not use std.meta.stringToEnum because it returns an optional
    /// and I didn't dig to get case sensitivity
    pub fn from_string(string: []const u8) !Level {
        if (std.mem.eql(u8, "GENIN", string))
            return .genin;
        if (std.mem.eql(u8, "CHUUNIN", string))
            return .chuunin;
        if (std.mem.eql(u8, "JONIN", string))
            return .jonin;
        if (std.mem.eql(u8, "SANNIN", string))
            return .sannin;
        if (std.mem.eql(u8, "ANBU", string))
            return .anbu;
        if (std.mem.eql(u8, "KAGE", string))
            return .kage;
        if (std.mem.eql(u8, "FORBIDDEN", string))
            return .forbidden;

        return error.UnknownRank;
    }
};

const Scroll = struct {
    id: u32,
    rank: Level,
    jutsu: []const u8,
    usage: []const u8,
};

const ScrollRequest = struct {
    rank: []const u8,
    jutsu: []const u8,
    usage: []const u8,
};

const App = struct {
    connection_pool: *pg.Pool,
};

fn getScrolls(app: *App, req: *httpz.Request, res: *httpz.Response) !void {
    // const user_id = req.param("id").?;

    std.debug.print("request received", .{});

    const query = try req.query();
    const requested_id = query.get("id");

    if (requested_id) |captured_id| {
        const id = try std.fmt.parseInt(i32, captured_id, 10);

        const query_result = try app.connection_pool.query("SELECT * FROM scroll WHERE id = $1", .{id});
        defer query_result.deinit();

        while (try query_result.next()) |row| {
            const scroll_id = row.get(i32, 0);

            const rank = try Level.from_string(row.get([]u8, 1));

            const jutsu = row.get([]u8, 2);

            const usage = row.get([]u8, 3);

            return try res.json(.{
                .scroll_id = scroll_id,
                .rank = rank,
                .jutsu = jutsu,
                .usage = usage,
            }, .{});
        }
    }

    const query_result = try app.connection_pool.query("SELECT * FROM scroll", .{});
    defer query_result.deinit();

    var scrolls = std.ArrayList(Scroll).init(req.arena);

    while (try query_result.next()) |row| {
        const id = row.get(i32, 0);

        const rank = try Level.from_string(row.get([]u8, 1));

        const jutsu = row.get([]u8, 2);

        const usage = row.get([]u8, 3);

        const scroll = Scroll{
            .id = @bitCast(id),
            .rank = rank,
            .jutsu = jutsu,
            .usage = usage,
        };

        try scrolls.append(scroll);
    }

    const scrolls_response = try scrolls.toOwnedSlice();

    return try res.json(scrolls_response, .{});
}

fn getScroll(app: *App, req: *httpz.Request, res: *httpz.Response) !void {
    const requested_id = req.param("id") orelse {
        res.status = 401;
        res.body = "Bad Request";
        return;
    };

    const id = try std.fmt.parseInt(i32, requested_id, 10);

    const query_result = try app.connection_pool.query("SELECT * FROM scroll WHERE id = $1", .{id});
    defer query_result.deinit();

    while (try query_result.next()) |row| {
        const scroll_id = row.get(i32, 0);

        const rank = try Level.from_string(row.get([]u8, 1));

        const jutsu = row.get([]u8, 2);

        const usage = row.get([]u8, 3);

        const scroll = Scroll{
            .id = @bitCast(scroll_id),
            .rank = rank,
            .jutsu = jutsu,
            .usage = usage,
        };

        return try res.json(scroll, .{});
    }
}

fn postScroll(app: *App, req: *httpz.Request, res: *httpz.Response) !void {
    const body = req.body() orelse {
        res.status = 401;
        res.body = "Bad Request";
        return;
    };

    const parsed = try std.json.parseFromSlice(ScrollRequest, req.arena, body, .{ .ignore_unknown_fields = true });

    const new_scroll = parsed.value;

    // repository
    const query_result = try app.connection_pool.query("INSERT INTO scroll (rank, jutsu, usage) VALUES ($1::level, $2, $3)", .{ new_scroll.rank, new_scroll.jutsu, new_scroll.usage });
    defer query_result.deinit();

    res.status = 201;
    res.body = "Created";
    return;
}

fn deleteScroll(app: *App, req: *httpz.Request, res: *httpz.Response) !void {
    const requested_id = if (req.param("id")) |id| id else if ((try req.query()).get("id")) |id| id else {
        res.status = 401;
        res.body = "Bad Request";
        return;
    };

    const id = try std.fmt.parseInt(i32, requested_id, 10);

    // repository
    const query_result = try app.connection_pool.query("DELETE FROM scroll WHERE id = $1", .{id});
    defer query_result.deinit();

    res.status = 202;
    res.body = "Accepted";
    return;
}

pub fn main() !void {
    var debugAllocator: std.heap.DebugAllocator(.{
        .stack_trace_frames = 50,
    }) = .init;
    defer std.debug.print("\n\nLeaks detected: {}\n\n", .{debugAllocator.deinit() != .ok});

    const allocator = debugAllocator.allocator();

    var env_map = try std.process.getEnvMap(allocator);
    defer env_map.deinit();

    const database_url = env_map.get("DATABASE_URL") orelse @panic("DATABASE_URL is not set in the environment");

    const database_uri = std.Uri.parse(database_url) catch @panic("DATABASE_URL is malformed and not a valid URI");

    const port = std.process.parseEnvVarInt("PORT", u16, 10) catch @panic("PORT is not set in the environment");

    var pool = try pg.Pool.initUri(allocator, database_uri, .{ .size = 5, .timeout = 10_000 });
    defer pool.deinit();

    var app = App{
        .connection_pool = pool,
    };

    var server = try httpz.Server(*App).init(allocator, .{ .port = port, .address = "0.0.0.0" }, &app);

    var router = try server.router(.{});

    router.get("/scroll", getScrolls, .{});
    router.get("/scroll/:id", getScroll, .{});
    router.post("/scroll", postScroll, .{});
    router.delete("/scroll/:id", deleteScroll, .{});
    router.delete("/scroll", deleteScroll, .{});

    std.debug.print("listening on port {d}", .{port});

    try server.listen();
}
