import Foundation
import QueueFileFFI

public enum QueueFileSwiftError: Error {
    case emptyQueue
    case encodingError
    case decodingError
}

public actor QueueFileSwiftQueue {
    private let queue: QueueFile

    public init(path: String) throws {
        self.queue = try QueueFile.open(path: path)
    }

    public init(path: String, capacity: UInt64) throws {
        self.queue = try QueueFile.withCapacity(path: path, capacity: capacity)
    }

    public func add(_ data: Data) throws {
        try queue.add(data: data)
    }

    public func addMultiple(_ items: [Data]) throws {
        try queue.addMultiple(items: items)
    }

    public func peek() throws -> Data? {
        return try queue.peek()
    }

    public func remove() throws {
        try queue.remove()
    }

    public func removeN(_ n: UInt32) throws {
        try queue.removeN(n: n)
    }

    public func clear() throws {
        try queue.clear()
    }

    public func isEmpty() throws -> Bool {
        return try queue.isEmpty()
    }

    public func size() throws -> UInt32 {
        return try queue.size()
    }

    public func fileLen() throws -> UInt64 {
        return try queue.fileLen()
    }

    public func usedBytes() throws -> UInt64 {
        return try queue.usedBytes()
    }

    public func getAll() throws -> [Data] {
        return try queue.getAll()
    }

    public func syncAll() throws {
        try queue.syncAll()
    }

    public func setSyncWrites(_ value: Bool) throws {
        try queue.setSyncWrites(value: value)
    }

    public func syncWrites() throws -> Bool {
        return try queue.syncWrites()
    }

    public func setOverwriteOnRemove(_ value: Bool) throws {
        try queue.setOverwriteOnRemove(value: value)
    }

    public func overwriteOnRemove() throws -> Bool {
        return try queue.overwriteOnRemove()
    }

    public func setCacheOffsetPolicy(_ policy: OffsetCachePolicy) throws {
        try queue.setCacheOffsetPolicy(policy: policy)
    }
}

public actor CodableQueueFile<T: Codable & Sendable> {
    private let queue: QueueFileSwiftQueue
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(path: String) throws {
        self.queue = try QueueFileSwiftQueue(path: path)
    }

    public init(path: String, capacity: UInt64) throws {
        self.queue = try QueueFileSwiftQueue(path: path, capacity: capacity)
    }

    public func add(_ item: T) async throws {
        let data = try encoder.encode(item)
        try await queue.add(data)
    }

    public func addMultiple(_ items: [T]) async throws {
        let dataItems = try items.map { try encoder.encode($0) }
        try await queue.addMultiple(dataItems)
    }

    public func peek() async throws -> T? {
        guard let data = try await queue.peek() else {
            return nil
        }
        return try decoder.decode(T.self, from: data)
    }

    public func remove() async throws {
        try await queue.remove()
    }

    public func removeN(_ n: UInt32) async throws {
        try await queue.removeN(n)
    }

    public func clear() async throws {
        try await queue.clear()
    }

    public func isEmpty() async throws -> Bool {
        return try await queue.isEmpty()
    }

    public func size() async throws -> UInt32 {
        return try await queue.size()
    }

    public func getAll() async throws -> [T] {
        let dataItems = try await queue.getAll()
        return try dataItems.map { try decoder.decode(T.self, from: $0) }
    }

    public func syncAll() async throws {
        try await queue.syncAll()
    }
}
