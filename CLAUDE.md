# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Rust-to-Swift wrapper that exposes the `queue-file` crate (a transactional, file-based FIFO queue) to iOS/macOS applications using Mozilla's UniFFI for FFI bindings generation.

## Build Commands

```bash
# Full build (generates bindings + builds for all iOS targets + creates XCFramework)
./build-ios.sh

# Run Rust tests
cargo test

# Run Swift tests (requires build-ios.sh to have been run first)
swift test

# Manual bindgen (usually run via build-ios.sh)
cargo run --bin uniffi-bindgen generate --library ./target/debug/libqueuefile.dylib --language swift --out-dir ./out
```

## Architecture: Rust + Swift via UniFFI

### Layer Structure

```
┌─────────────────────────────────────────┐
│  Swift App Layer                        │
│  (Uses QueueFileSwiftQueue actor or     │
│   CodableQueueFile<T> for typed items)  │
├─────────────────────────────────────────┤
│  Sources/QueueFileSwift/QueueFileSwift.swift│
│  (Swift-native API with generics)       │
├─────────────────────────────────────────┤
│  Sources/QueueFileFFI/queuefile.swift   │
│  (UniFFI-generated bindings)            │
├─────────────────────────────────────────┤
│  XCFramework (libqueuefile-rs.xcframework)│
│  (Compiled Rust static libraries)       │
├─────────────────────────────────────────┤
│  src/lib.rs                             │
│  (Rust implementation with UniFFI attrs)│
└─────────────────────────────────────────┘
```

### Key Files

- **src/lib.rs**: Rust implementation with `#[uniffi::export]` annotations wrapping the `queue-file` crate
- **src/uniffi-bindgen.rs**: Binary that invokes UniFFI's Swift code generator
- **Sources/QueueFileFFI/queuefile.swift**: Auto-generated Swift bindings (do not edit manually)
- **Sources/QueueFileSwift/QueueFileSwift.swift**: Hand-written Swift wrapper providing idiomatic API with actors and generics
- **build-ios.sh**: Build script that orchestrates the entire build pipeline

### Data Flow Pattern

The QueueFile stores raw bytes (`Vec<u8>` / `Data`). The Swift layer provides:
1. `QueueFileSwiftQueue` - works with raw `Data` objects
2. `CodableQueueFile<T>` - automatically encodes/decodes `Codable` types using JSON

## API Reference

### Rust API (via UniFFI)

- `QueueFile::open(path)` - Open or create a queue file
- `QueueFile::with_capacity(path, capacity)` - Open with minimum capacity
- `add(data)` / `add_multiple(items)` - Add elements to queue
- `peek()` - Read eldest element without removing
- `remove()` / `remove_n(n)` - Remove elements from queue
- `clear()` - Remove all elements
- `is_empty()` / `size()` - Query queue state
- `sync_all()` - Sync to disk
- `set_sync_writes(bool)` - Enable/disable sync on every write
- `set_overwrite_on_remove(bool)` - Overwrite data on remove for security
- `set_cache_offset_policy(policy)` - Configure iteration performance

### Swift API

```swift
// Raw data queue
let queue = try QueueFileSwiftQueue(path: "/path/to/queue.qf")
try await queue.add(myData)
let data = try await queue.peek()
try await queue.remove()

// Typed queue with Codable
let typedQueue = try CodableQueueFile<MyStruct>(path: "/path/to/queue.qf")
try await typedQueue.add(MyStruct(id: "1", value: 42))
let item: MyStruct? = try await typedQueue.peek()
```

## iOS Build Considerations

- **Targets**: Build for `aarch64-apple-ios` (devices), `aarch64-apple-ios-sim` (Apple Silicon simulators), `aarch64-apple-darwin` (macOS)
- **Modulemap naming**: UniFFI generates `queuefileFFI.modulemap` but Swift packages require `module.modulemap`

## Testing

Swift tests are in `Tests/QueueFileSwiftTests/`. The test suite demonstrates:
- Basic queue operations (add, peek, remove)
- Multiple item handling
- `CodableQueueFile` with custom Codable types
