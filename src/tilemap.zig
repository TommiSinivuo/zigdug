const std = @import("std");
const math = std.math;
const mem = std.mem;
const assert = std.debug.assert;
const log = std.log;
const Allocator = std.mem.Allocator;

const common = @import("common.zig");
const Point = common.Point;
const Rect = common.Rect;

pub fn Tilemap(comptime T: type) type {
    return struct {
        box: Rect,
        tile_size: i32,
        null_value: T,
        memory: TilemapMemory(T),

        pub fn init(
            allocator: Allocator,
            width: i32,
            height: i32,
            tile_size: i32,
            null_value: T,
        ) !Tilemap(T) {
            const memory = try TilemapMemory(T).init(allocator, width * height, width);
            mem.set(T, memory.tiles, null_value);

            const box = Rect{ .x = 0, .y = 0, .w = width, .h = height };

            return Tilemap(T){
                .box = box,
                .tile_size = tile_size,
                .null_value = null_value,
                .memory = memory,
            };
        }

        pub fn containsPoint(self: *const Tilemap(T), point: Point(i32)) bool {
            return point.x >= self.box.x and
                point.x < (self.box.x + self.box.w) and
                point.y >= self.box.y and
                point.y < (self.box.y + self.box.h);
        }

        pub fn count(self: *const Tilemap(T), predicate: fn (T) bool) i32 {
            var sum: i32 = 0;

            var iter = self.iteratorForward();

            while (iter.next()) |item| {
                if (predicate(item.value)) sum += 1;
            }

            return sum;
        }

        // TODO: needs to be tested properly
        pub fn findFirst(self: *const Tilemap(T), predicate: fn (T) bool) ?Point(i32) {
            var iter = self.iteratorForward();
            while (iter.next()) |item| {
                if (predicate(item.value)) {
                    return item.point;
                }
            }
            return null;
        }

        pub fn getTile(self: *const Tilemap(T), point: Point(i32)) T {
            if (self.containsPoint(point)) {
                const index = self.memoryIndexOf(point);
                return self.memory.tiles[index];
            } else {
                return self.null_value;
            }
        }

        pub fn isEvery(self: *const Tilemap(T), predicate: fn (T) bool) bool {
            var iter = self.iteratorForward();

            while (iter.next()) |item| {
                if (!predicate(item.value)) return false;
            }

            return true;
        }

        pub fn iterator(self: *const Tilemap(T), is_reversed: bool) TilemapIterator(T) {
            const start = switch (is_reversed) {
                true => self.memoryIndexOf(Point(i32){
                    .x = self.box.x + (self.box.w - 1),
                    .y = self.box.y + (self.box.h - 1),
                }),
                false => self.memoryIndexOf(Point(i32){ .x = self.box.x, .y = self.box.y }),
            };
            const end = switch (is_reversed) {
                true => self.memoryIndexOf(Point(i32){ .x = self.box.x, .y = self.box.y }),
                false => self.memoryIndexOf(Point(i32){
                    .x = self.box.x + (self.box.w - 1),
                    .y = self.box.y + (self.box.h - 1),
                }),
            };

            return TilemapIterator(T){
                .tilemap = self.*,
                .cursor = @intCast(i32, start),
                .end_index = @intCast(i32, end),
                .is_reversed = is_reversed,
            };
        }

        pub fn iteratorForward(self: *const Tilemap(T)) TilemapIterator(T) {
            return self.iterator(false);
        }

        pub fn iteratorBackward(self: *const Tilemap(T)) TilemapIterator(T) {
            return self.iterator(true);
        }

        // TODO: this needs to have tests and be made robust
        pub fn loadAndTransform(self: *const Tilemap(T), comptime U: type, source: *Tilemap(U), transform: fn (U) T) void {
            assert(self.box.w == source.box.w);
            assert(self.box.h == source.box.h);

            var src_iter = source.iteratorForward();

            while (src_iter.next()) |src_item| {
                const point = Point(i32){
                    .x = self.box.x + src_item.point.x,
                    .y = self.box.y + src_item.point.y,
                };
                self.setTile(point, transform(src_item.value));
            }
        }

        pub fn setTile(self: *const Tilemap(T), point: Point(i32), value: T) void {
            if (self.containsPoint(point)) {
                const index = self.memoryIndexOf(point);
                self.memory.tiles[index] = value;
            }
        }

        pub fn setTiles(self: *const Tilemap(T), value: T) void {
            const bottom_right_x = self.box.x + (self.box.w - 1);
            const bottom_right_y = self.box.y + (self.box.h - 1);

            const last_index = self.memoryIndexOf(Point(i32){
                .x = bottom_right_x,
                .y = bottom_right_y,
            });

            var row_start_index = self.memoryIndexOf(Point(i32){
                .x = self.box.x,
                .y = self.box.y,
            });

            while (row_start_index < last_index) : (row_start_index += @intCast(usize, self.memory.pitch)) {
                const row = self.memory.tiles[row_start_index..(row_start_index + @intCast(usize, self.box.w))];
                mem.set(T, row, value);
            }
        }

        pub fn subTilemap(self: *const Tilemap(T), rect: Rect) ?Tilemap(T) {
            var top_left: ?Point(i32) = null;
            var bottom_right: ?Point(i32) = null;

            var y: i32 = rect.y;
            while (y < (rect.y + rect.h)) : (y += 1) {
                var x: i32 = rect.x;
                while (x < (rect.x + rect.w)) : (x += 1) {
                    const point = Point(i32){ .x = x, .y = y };
                    if (self.containsPoint(point)) {
                        if (top_left == null) {
                            top_left = point;
                            bottom_right = point;
                        } else {
                            bottom_right = point;
                        }
                    }
                }
            }

            if (top_left == null) return null;

            const box = Rect{
                .x = top_left.?.x,
                .y = top_left.?.y,
                .w = (bottom_right.?.x - top_left.?.x) + 1,
                .h = (bottom_right.?.y - top_left.?.y) + 1,
            };

            return Tilemap(T){
                .box = box,
                .tile_size = self.tile_size,
                .null_value = self.null_value,
                .memory = self.memory,
            };
        }

        pub fn toTileGridPoint(self: *Tilemap(T), world_point: Point(i32)) Point(i32) {
            return Point(i32){
                .x = @divFloor(world_point.x, self.tile_size),
                .y = @divFloor(world_point.y, self.tile_size),
            };
        }

        pub fn toWorldPoint(self: *Tilemap(T), tile_point: Point(i32)) Point(i32) {
            return Point(i32){
                .x = tile_point.x * self.tile_size,
                .y = tile_point.y * self.tile_size,
            };
        }

        fn memoryIndexOf(self: *const Tilemap(T), point: Point(i32)) usize {
            return @intCast(usize, (point.y * self.memory.pitch) + point.x);
        }
    };
}

pub fn TilemapMemory(comptime T: type) type {
    return struct {
        tiles: []T,
        pitch: i32,

        pub fn init(allocator: Allocator, size: i32, pitch: i32) !TilemapMemory(T) {
            const tiles = try allocator.alloc(T, @intCast(usize, size));
            return TilemapMemory(T){
                .tiles = tiles,
                .pitch = pitch,
            };
        }
    };
}

pub fn TilemapIterator(comptime T: type) type {
    return struct {
        tilemap: Tilemap(T),
        end_index: i32,
        cursor: i32,
        help_cursor: u32 = 0,
        is_reversed: bool = false,

        pub fn next(self: *TilemapIterator(T)) ?TilemapIteratorResult(T) {
            const stop_iteration = switch (self.is_reversed) {
                true => self.cursor < self.end_index,
                false => self.cursor > self.end_index,
            };

            if (stop_iteration) return null;

            const value = self.tilemap.memory.tiles[@intCast(usize, self.cursor)];
            const point = Point(i32){
                .x = @mod(self.cursor, self.tilemap.memory.pitch),
                .y = @divFloor(self.cursor, self.tilemap.memory.pitch),
            };

            self.help_cursor += 1;

            if (self.is_reversed) {
                if (self.help_cursor == self.tilemap.box.w) {
                    self.help_cursor = 0;
                    self.cursor -= self.tilemap.memory.pitch - (self.tilemap.box.w - 1);
                } else {
                    self.cursor -= 1;
                }
            } else {
                if (self.help_cursor == self.tilemap.box.w) {
                    self.help_cursor = 0;
                    self.cursor += self.tilemap.memory.pitch - (self.tilemap.box.w - 1);
                } else {
                    self.cursor += 1;
                }
            }

            return TilemapIteratorResult(T){ .value = value, .point = point };
        }
    };
}

fn TilemapIteratorResult(comptime T: type) type {
    return struct {
        value: T,
        point: Point(i32),
    };
}

const testing = std.testing;
const expect = testing.expect;
const expectEqual = testing.expectEqual;
const expectError = testing.expectError;

fn isZero(val: u8) bool {
    return val == 0;
}

fn isOne(val: u8) bool {
    return val == 1;
}

fn isTwo(val: u8) bool {
    return val == 2;
}

test "Tilemap - init and destroy" {
    var tilemap = try Tilemap(u8).init(testing.allocator, 16, 16, 16, 0);
    defer testing.allocator.free(tilemap.memory.tiles);

    for (tilemap.memory.tiles) |tile| {
        try expect(tile == 0);
    }
}

test "Tilemap - getTile and setTile basic usage" {
    var tilemap = try Tilemap(u8).init(testing.allocator, 16, 16, 16, 0);
    defer testing.allocator.free(tilemap.memory.tiles);

    const position = Point(i32){ .x = 8, .y = 8 };
    var res = tilemap.getTile(position);
    try expectEqual(@intCast(u8, 0), res);
    tilemap.setTile(position, 1);
    res = tilemap.getTile(position);
    try expectEqual(@intCast(u8, 1), res);
}

test "Tilemap - getTile with position out of bounds returns tilemap null value" {
    var tilemap = try Tilemap(u8).init(testing.allocator, 16, 16, 16, 0);
    defer testing.allocator.free(tilemap.memory.tiles);

    tilemap.setTiles(1);

    const outside_1 = Point(i32){ .x = -1, .y = -1 };
    const outside_2 = Point(i32){ .x = 16, .y = 16 };
    const outside_3 = Point(i32){ .x = -1, .y = 0 };
    const outside_4 = Point(i32){ .x = 0, .y = -1 };

    try expectEqual(@intCast(u8, 0), tilemap.getTile(outside_1));
    try expectEqual(@intCast(u8, 0), tilemap.getTile(outside_2));
    try expectEqual(@intCast(u8, 0), tilemap.getTile(outside_3));
    try expectEqual(@intCast(u8, 0), tilemap.getTile(outside_4));
}

test "Tilemap - setTile on sub tilemap" {
    var tilemap = try Tilemap(u8).init(testing.allocator, 8, 8, 1, 0);
    defer testing.allocator.free(tilemap.memory.tiles);

    const submap_rect = Rect{ .x = 2, .y = 2, .w = 4, .h = 4 };
    var submap = tilemap.subTilemap(submap_rect).?;
    submap.setTile(Point(i32){ .x = 2, .y = 2 }, 1);

    const expected_1: u8 = 1;
    const result_1 = submap.getTile(Point(i32){ .x = 2, .y = 2 });
    try expectEqual(expected_1, result_1);

    const expected_2: u8 = 1;
    const result_2 = tilemap.getTile(Point(i32){ .x = 2, .y = 2 });
    try expectEqual(expected_2, result_2);
}

test "Tilemap - setTile with position out of bounds should be no-op" {
    var tilemap = try Tilemap(u8).init(testing.allocator, 16, 16, 16, 0);
    defer testing.allocator.free(tilemap.memory.tiles);

    const outside_1 = Point(i32){ .x = -1, .y = -1 };
    const outside_2 = Point(i32){ .x = 16, .y = 16 };
    const outside_3 = Point(i32){ .x = -1, .y = 0 };
    const outside_4 = Point(i32){ .x = 0, .y = -1 };

    tilemap.setTile(outside_1, 1);
    tilemap.setTile(outside_2, 1);
    tilemap.setTile(outside_3, 1);
    tilemap.setTile(outside_4, 1);

    for (tilemap.memory.tiles) |tile| {
        try expectEqual(@intCast(u8, 0), tile);
    }
}

test "Tilemap - setTiles basic usage" {
    var tilemap = try Tilemap(u8).init(testing.allocator, 16, 16, 16, 0);
    defer testing.allocator.free(tilemap.memory.tiles);

    tilemap.setTiles(1);

    for (tilemap.memory.tiles) |tile| {
        try expectEqual(@intCast(u8, 1), tile);
    }
}

test "Tilemap - setTiles on sub tilemap" {
    var tilemap = try Tilemap(u8).init(testing.allocator, 8, 8, 1, 0);
    defer testing.allocator.free(tilemap.memory.tiles);

    const submap_rect = Rect{ .x = 2, .y = 2, .w = 4, .h = 4 };
    tilemap.subTilemap(submap_rect).?.setTiles(1);

    try expectEqual(@intCast(u8, 0), tilemap.getTile(Point(i32){ .x = 0, .y = 0 }));
    try expectEqual(@intCast(u8, 1), tilemap.getTile(Point(i32){ .x = 2, .y = 2 }));
    try expectEqual(@intCast(u8, 1), tilemap.getTile(Point(i32){ .x = 5, .y = 5 }));
    try expectEqual(@intCast(u8, 0), tilemap.getTile(Point(i32){ .x = 1, .y = 2 }));
    try expectEqual(@intCast(u8, 0), tilemap.getTile(Point(i32){ .x = 2, .y = 1 }));
    try expectEqual(@intCast(u8, 0), tilemap.getTile(Point(i32){ .x = 5, .y = 6 }));
    try expectEqual(@intCast(u8, 0), tilemap.getTile(Point(i32){ .x = 6, .y = 5 }));
}

test "Tilemap - containsPoint basic usage" {
    var tilemap = try Tilemap(u8).init(testing.allocator, 16, 16, 16, 0);
    defer testing.allocator.free(tilemap.memory.tiles);

    try expect(tilemap.containsPoint(Point(i32){ .x = 0, .y = 0 }));
    try expect(tilemap.containsPoint(Point(i32){ .x = 15, .y = 15 }));
    try expect(!tilemap.containsPoint(Point(i32){ .x = -1, .y = 0 }));
    try expect(!tilemap.containsPoint(Point(i32){ .x = 0, .y = -1 }));
    try expect(!tilemap.containsPoint(Point(i32){ .x = 16, .y = 0 }));
    try expect(!tilemap.containsPoint(Point(i32){ .x = 0, .y = 16 }));
    try expect(!tilemap.containsPoint(Point(i32){ .x = -1, .y = -1 }));
    try expect(!tilemap.containsPoint(Point(i32){ .x = 16, .y = 16 }));
}

test "Tilemap - containsPoint on sub tilemap" {
    var tilemap = try Tilemap(u8).init(testing.allocator, 16, 16, 16, 0);
    defer testing.allocator.free(tilemap.memory.tiles);

    const submap_rect = Rect{ .x = 2, .y = 2, .w = 4, .h = 4 };
    var submap = tilemap.subTilemap(submap_rect).?;

    try expect(submap.containsPoint(Point(i32){ .x = 2, .y = 2 }));
    try expect(submap.containsPoint(Point(i32){ .x = 5, .y = 5 }));
    try expect(!submap.containsPoint(Point(i32){ .x = 1, .y = 2 }));
    try expect(!submap.containsPoint(Point(i32){ .x = 2, .y = 1 }));
    try expect(!submap.containsPoint(Point(i32){ .x = 6, .y = 2 }));
    try expect(!submap.containsPoint(Point(i32){ .x = 2, .y = 6 }));
    try expect(!submap.containsPoint(Point(i32){ .x = 1, .y = 1 }));
    try expect(!submap.containsPoint(Point(i32){ .x = 6, .y = 6 }));
}

test "Tilemap - count" {
    var tilemap = try Tilemap(u8).init(testing.allocator, 8, 8, 1, 0);
    defer testing.allocator.free(tilemap.memory.tiles);

    const submap_rect = Rect{ .x = 2, .y = 2, .w = 4, .h = 4 };
    var submap = tilemap.subTilemap(submap_rect).?;

    tilemap.setTile(Point(i32){ .x = 0, .y = 0 }, 1);
    submap.setTiles(1);

    try expectEqual(@intCast(i32, 17), tilemap.count(isOne));
    try expectEqual(@intCast(i32, 16), submap.count(isOne));
    try expectEqual(@intCast(i32, 47), tilemap.count(isZero));
    try expectEqual(@intCast(i32, 0), tilemap.count(isTwo));
}

test "Tilemap - toTileGridPoint" {
    var tilemap = try Tilemap(u8).init(testing.allocator, 8, 8, 8, 0);
    defer testing.allocator.free(tilemap.memory.tiles);

    var result: Point(i32) = undefined;

    result = tilemap.toTileGridPoint(Point(i32){ .x = 4, .y = 4 });
    try expectEqual(@intCast(i32, 0), result.x);
    try expectEqual(@intCast(i32, 0), result.y);

    result = tilemap.toTileGridPoint(Point(i32){ .x = 60, .y = 60 });
    try expectEqual(@intCast(i32, 7), result.x);
    try expectEqual(@intCast(i32, 7), result.y);

    result = tilemap.toTileGridPoint(Point(i32){ .x = -1, .y = -1 });
    try expectEqual(@intCast(i32, -1), result.x);
    try expectEqual(@intCast(i32, -1), result.y);

    result = tilemap.toTileGridPoint(Point(i32){ .x = 65, .y = 65 });
    try expectEqual(@intCast(i32, 8), result.x);
    try expectEqual(@intCast(i32, 8), result.y);
}

test "Tilemap - toWorldPoint" {
    var tilemap = try Tilemap(u8).init(testing.allocator, 8, 8, 8, 0);
    defer testing.allocator.free(tilemap.memory.tiles);

    var result: Point(i32) = undefined;

    result = tilemap.toWorldPoint(Point(i32){ .x = 0, .y = 0 });
    try expectEqual(@intCast(i32, 0), result.x);
    try expectEqual(@intCast(i32, 0), result.y);

    result = tilemap.toWorldPoint(Point(i32){ .x = 7, .y = 7 });
    try expectEqual(@intCast(i32, 56), result.x);
    try expectEqual(@intCast(i32, 56), result.y);

    result = tilemap.toWorldPoint(Point(i32){ .x = -1, .y = -1 });
    try expectEqual(@intCast(i32, -8), result.x);
    try expectEqual(@intCast(i32, -8), result.y);

    result = tilemap.toWorldPoint(Point(i32){ .x = 8, .y = 8 });
    try expectEqual(@intCast(i32, 64), result.x);
    try expectEqual(@intCast(i32, 64), result.y);
}

test "Tilemap - isEvery basic usage" {
    var tilemap = try Tilemap(u8).init(testing.allocator, 8, 8, 1, 0);
    defer testing.allocator.free(tilemap.memory.tiles);

    try expect(tilemap.isEvery(isZero));
}

test "Tilemap - isEvery on sub tilemap" {
    var tilemap = try Tilemap(u8).init(testing.allocator, 8, 8, 1, 0);
    defer testing.allocator.free(tilemap.memory.tiles);

    const submap_rect = Rect{ .x = 2, .y = 2, .w = 4, .h = 4 };
    var submap = tilemap.subTilemap(submap_rect).?;

    submap.setTiles(1);

    try expect(!tilemap.isEvery(isZero));
    try expect(!tilemap.isEvery(isOne));
    try expect(submap.isEvery(isOne));
}

test "Tilemap - subTilemap clipping" {
    var tilemap = try Tilemap(u8).init(testing.allocator, 8, 8, 1, 0);
    defer testing.allocator.free(tilemap.memory.tiles);

    const rect_partially_off_left = Rect{ .x = -1, .y = 0, .w = 4, .h = 4 };
    const rect_partially_off_top = Rect{ .x = 0, .y = -1, .w = 4, .h = 4 };
    const rect_partially_off_right = Rect{ .x = 7, .y = 0, .w = 4, .h = 4 };
    const rect_partially_off_bottom = Rect{ .x = 0, .y = 7, .w = 4, .h = 4 };
    const rect_partially_off_top_left = Rect{ .x = -1, .y = -1, .w = 4, .h = 4 };
    const rect_partially_off_top_right = Rect{ .x = 7, .y = -1, .w = 4, .h = 4 };
    const rect_partially_off_bottom_right = Rect{ .x = 7, .y = 7, .w = 4, .h = 4 };
    const rect_partially_off_bottom_left = Rect{ .x = -1, .y = 7, .w = 4, .h = 4 };
    const rect_completely_off = Rect{ .x = 8, .y = 8, .w = 4, .h = 4 };

    var result = tilemap.subTilemap(rect_partially_off_left).?;
    try expectEqual(@intCast(i32, 0), result.box.x);
    try expectEqual(@intCast(i32, 0), result.box.y);
    try expectEqual(@intCast(i32, 3), result.box.w);
    try expectEqual(@intCast(i32, 4), result.box.h);

    result = tilemap.subTilemap(rect_partially_off_top).?;
    try expectEqual(@intCast(i32, 0), result.box.x);
    try expectEqual(@intCast(i32, 0), result.box.y);
    try expectEqual(@intCast(i32, 4), result.box.w);
    try expectEqual(@intCast(i32, 3), result.box.h);

    result = tilemap.subTilemap(rect_partially_off_right).?;
    try expectEqual(@intCast(i32, 7), result.box.x);
    try expectEqual(@intCast(i32, 0), result.box.y);
    try expectEqual(@intCast(i32, 1), result.box.w);
    try expectEqual(@intCast(i32, 4), result.box.h);

    result = tilemap.subTilemap(rect_partially_off_bottom).?;
    try expectEqual(@intCast(i32, 0), result.box.x);
    try expectEqual(@intCast(i32, 7), result.box.y);
    try expectEqual(@intCast(i32, 4), result.box.w);
    try expectEqual(@intCast(i32, 1), result.box.h);

    result = tilemap.subTilemap(rect_partially_off_top_left).?;
    try expectEqual(@intCast(i32, 0), result.box.x);
    try expectEqual(@intCast(i32, 0), result.box.y);
    try expectEqual(@intCast(i32, 3), result.box.w);
    try expectEqual(@intCast(i32, 3), result.box.h);

    result = tilemap.subTilemap(rect_partially_off_top_right).?;
    try expectEqual(@intCast(i32, 7), result.box.x);
    try expectEqual(@intCast(i32, 0), result.box.y);
    try expectEqual(@intCast(i32, 1), result.box.w);
    try expectEqual(@intCast(i32, 3), result.box.h);

    result = tilemap.subTilemap(rect_partially_off_bottom_right).?;
    try expectEqual(@intCast(i32, 7), result.box.x);
    try expectEqual(@intCast(i32, 7), result.box.y);
    try expectEqual(@intCast(i32, 1), result.box.w);
    try expectEqual(@intCast(i32, 1), result.box.h);

    result = tilemap.subTilemap(rect_partially_off_bottom_left).?;
    try expectEqual(@intCast(i32, 0), result.box.x);
    try expectEqual(@intCast(i32, 7), result.box.y);
    try expectEqual(@intCast(i32, 3), result.box.w);
    try expectEqual(@intCast(i32, 1), result.box.h);

    try expect(tilemap.subTilemap(rect_completely_off) == null);
}

test "TilemapIterator basic usage" {
    var tilemap = try Tilemap(u8).init(testing.allocator, 2, 2, 1, 0);
    defer testing.allocator.free(tilemap.memory.tiles);

    tilemap.setTile(Point(i32){ .x = 0, .y = 0 }, 1);

    var iterator = tilemap.iterator(false);

    var item = iterator.next().?;
    try expectEqual(@intCast(u8, 1), item.value);
    try expectEqual(@intCast(i32, 0), item.point.x);
    try expectEqual(@intCast(i32, 0), item.point.y);

    item = iterator.next().?;
    try expectEqual(@intCast(u8, 0), item.value);
    try expectEqual(@intCast(i32, 1), item.point.x);
    try expectEqual(@intCast(i32, 0), item.point.y);

    item = iterator.next().?;
    try expectEqual(@intCast(u8, 0), item.value);
    try expectEqual(@intCast(i32, 0), item.point.x);
    try expectEqual(@intCast(i32, 1), item.point.y);

    item = iterator.next().?;
    try expectEqual(@intCast(u8, 0), item.value);
    try expectEqual(@intCast(i32, 1), item.point.x);
    try expectEqual(@intCast(i32, 1), item.point.y);

    try expect(iterator.next() == null);
}

test "TilemapIterator basic usage backwards" {
    var tilemap = try Tilemap(u8).init(testing.allocator, 2, 2, 1, 0);
    defer testing.allocator.free(tilemap.memory.tiles);

    tilemap.setTile(Point(i32){ .x = 0, .y = 0 }, 1);

    var iterator = tilemap.iterator(true);

    var item = iterator.next().?;
    try expectEqual(@intCast(u8, 0), item.value);
    try expectEqual(@intCast(i32, 1), item.point.x);
    try expectEqual(@intCast(i32, 1), item.point.y);

    item = iterator.next().?;
    try expectEqual(@intCast(u8, 0), item.value);
    try expectEqual(@intCast(i32, 0), item.point.x);
    try expectEqual(@intCast(i32, 1), item.point.y);

    item = iterator.next().?;
    try expectEqual(@intCast(u8, 0), item.value);
    try expectEqual(@intCast(i32, 1), item.point.x);
    try expectEqual(@intCast(i32, 0), item.point.y);

    item = iterator.next().?;
    try expectEqual(@intCast(u8, 1), item.value);
    try expectEqual(@intCast(i32, 0), item.point.x);
    try expectEqual(@intCast(i32, 0), item.point.y);

    try expect(iterator.next() == null);
}

test "TilemapIterator on sub tilemap" {
    var tilemap = try Tilemap(u8).init(testing.allocator, 4, 4, 1, 0);
    defer testing.allocator.free(tilemap.memory.tiles);

    const submap_rect = Rect{ .x = 1, .y = 1, .w = 2, .h = 2 };
    var submap = tilemap.subTilemap(submap_rect).?;

    submap.setTile(Point(i32){ .x = 2, .y = 2 }, 1);

    var iterator = submap.iterator(false);

    var item = iterator.next().?;
    try expectEqual(@intCast(u8, 0), item.value);
    try expectEqual(@intCast(i32, 1), item.point.x);
    try expectEqual(@intCast(i32, 1), item.point.y);

    item = iterator.next().?;
    try expectEqual(@intCast(u8, 0), item.value);
    try expectEqual(@intCast(i32, 2), item.point.x);
    try expectEqual(@intCast(i32, 1), item.point.y);

    item = iterator.next().?;
    try expectEqual(@intCast(u8, 0), item.value);
    try expectEqual(@intCast(i32, 1), item.point.x);
    try expectEqual(@intCast(i32, 2), item.point.y);

    item = iterator.next().?;
    try expectEqual(@intCast(u8, 1), item.value);
    try expectEqual(@intCast(i32, 2), item.point.x);
    try expectEqual(@intCast(i32, 2), item.point.y);

    try expect(iterator.next() == null);
}

test "TilemapIterator backwards on sub tilemap" {
    var tilemap = try Tilemap(u8).init(testing.allocator, 4, 4, 1, 0);
    defer testing.allocator.free(tilemap.memory.tiles);

    const submap_rect = Rect{ .x = 1, .y = 1, .w = 2, .h = 2 };
    var submap = tilemap.subTilemap(submap_rect).?;

    submap.setTile(Point(i32){ .x = 2, .y = 2 }, 1);

    var iterator = submap.iterator(true);

    var item = iterator.next().?;
    try expectEqual(@intCast(u8, 1), item.value);
    try expectEqual(@intCast(i32, 2), item.point.x);
    try expectEqual(@intCast(i32, 2), item.point.y);

    item = iterator.next().?;
    try expectEqual(@intCast(u8, 0), item.value);
    try expectEqual(@intCast(i32, 1), item.point.x);
    try expectEqual(@intCast(i32, 2), item.point.y);

    item = iterator.next().?;
    try expectEqual(@intCast(u8, 0), item.value);
    try expectEqual(@intCast(i32, 2), item.point.x);
    try expectEqual(@intCast(i32, 1), item.point.y);

    item = iterator.next().?;
    try expectEqual(@intCast(u8, 0), item.value);
    try expectEqual(@intCast(i32, 1), item.point.x);
    try expectEqual(@intCast(i32, 1), item.point.y);

    try expect(iterator.next() == null);
}
