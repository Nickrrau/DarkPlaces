const std = @import("std");
const builtin = @import("builtin");
const c = @cImport({
    @cInclude("./darkplaces.h");
});

// Globals - To Be Replaced Eventually
var sentinel_seed: u64 = undefined;
var mem_bigendian: bool = undefined;
// mem_mutex: ?*mut?? = null;
var clumpchain: ?*Clump = null;
var poolchain: ?*Pool = null;
// used for temporary memory allocations around the engine, not for longterm
// storage, if anything in this pool stays allocated during gameplay, it is
// considered a leak
var tempmempool: *Pool = undefined;
// only for zone
var zonemempool: *Pool = undefined;

// smallest unit we care about is this many bytes
const MemUnit = 128;
// try to do 32MB clumps, but overhead eats into this
const MemWantClumpSize = 1 << 27;
// give malloc padding so we can't waste most of a page at the end
const MemClumpSize = MemWantClumpSize - MemWantClumpSize / MemUnit / 32 - 128;
const MemBits = MemClumpSize / MemUnit;
const MemBitsInts = MemBits / 32;

// mempool_s
const Pool = struct {
    // should always be MEMPOOL_SENTINEL
    sentinel1: u64,
    // chain of individual memory allocations
    // chain:
    flags: u64,
    // total memory allocated in this pool (inside memheaders)
    total_size: usize,
    // total memory allocated in this pool (actual malloc total)
    real_size: usize,
    // updated each time the pool is displayed by memlist, shows change from previous time (unless pool was freed)
    last_check_size: usize,
    // linked into global mempool list
    next: *Pool,
    // parent object (used for nested memory pools)
    parent: *Pool,
    // file name and line where Mem_AllocPool was called
    filename: []const u8,
    file_line: u64,
    // name of the pool
    name: [128]u8,
    // should always be MEMPOOL_SENTINEL
    sentinel2: usize,

    pub fn Alloc() void {}
    pub fn Free() void {}
    pub fn Empty() void {}
    pub fn StrDup() void {}
};

// memheader_s
const Header = struct {
    // address returned by Chunk_Alloc (may be significantly before this header to satisify alignment)
    base_address: *anyopaque,

    // pool this memheader belongs to
    pool: *Pool,
    // size of the memory after the header (excluding header and sentinel2)
    size: usize,
    // file name and line where Mem_Alloc was called
    filename: []const u8,
    file_line: u64,
    // should always be equal to MEMHEADER_SENTINEL_FOR_ADDRESS()
    sentinel: u64,
    // immediately followed by data, which is followed by another copy of mem_sentinel[]
};

// memclump_s
const Clump = struct {
    // contents of the clump
    block: [MemClumpSize]u8,
    // should always be MEMCLUMP_SENTINEL
    sentinel1: u64,
    // if a bit is on, it means that the MEMUNIT bytes it represents are
    // allocated, otherwise free
    bits: [MemBitsInts]usize,
    // should always be MEMCLUMP_SENTINEL
    sentinel2: u64,

    // if this drops to 0, the clump is freed
    blocks_in_use: usize,
    // largest block of memory available (this is reset to an optimistic
    // number when anything is freed, and updated when alloc fails the clump)
    largest_available: usize,
    // next clump in the chain
    chain: *Clump,

    pub fn NewClump() Clump {}
    pub fn AllocBlock() void {}
    pub fn FreeBlock() void {}
    pub fn CheckSentinels() void {}
};

const MMapData = struct {
    len: usize,
};

// memexpandablearray_s
const ExpandableArray = struct {
    mempool: *Pool,
    recordsize: usize,
    numrecordsperarray: usize,
    numarrays: usize,
    maxarrays: usize,
    arrays: []struct {
        data: []u8,
        flags: []const u8,
        flagged_records: usize,
    },

    pub fn New(l: *ExpandableArray, pool: *Pool, record_size: usize, records_per_array: usize) void {
        @memset(@sizeOf(*l), l);
        l.mempool = pool;
        l.recordsize = record_size;
        l.numrecordsperarray = records_per_array;
    }
    pub fn Free(self: *ExpandableArray) void {
        if (self.maxarrays > 0) {
            for (0..self.numarrays) |i| {
                Free(self.arrays[i].data);
            }
            Free(self.arrays);
        }
    }
    pub fn AllocRecord() void {}

    // IF YOU EDIT THIS:
    // If this function was to change the size of the "expandable" array, you have
    // to update r_shadow.c
    // Just do a search for "range =", R_ShadowClearWorldLights would be the first
    // function to look at. (And also seems like the only one?) You  might have to
    // move the  call to Mem_ExpandableArray_IndexRange  back into for(...) loop's
    // condition
    pub fn FreeRecord() void {}

    pub fn IndexRange() void {}
    pub fn RecordAtIndex() void {}
};

// fn mmap_malloc() void {}
// fn mmap_free() void {}
// fn attempt_malloc() void {}
// fn Alloc() void {}
// fn FreeBlock() void {}
// fn Free() void {}
// fn CheckSentinels() void {}
// fn CheckSentinelsGlobal() void {}
// fn IsAllocated() void {}
//
// fn PrintStats() void {}
// fn PrintList() void {}
//
// fn List() void {}
//
// fn Stats() void {}

// Init
fn Init() void {
    if (builtin.cpu.arch.endian() == .big) mem_bigendian = true;

    var rand = std.Random.Sfc64.init(123456789);
    sentinel_seed = rand.random().int(u64);

    tempmempool = Pool.Alloc();
    zonemempool = Pool.Alloc();
    // if (Thread_HasThreads())
    //     mem_mutex = Thread_CreateMutex();
}
// fn Shutdown() void {}
// fn InitCommands() void {}
