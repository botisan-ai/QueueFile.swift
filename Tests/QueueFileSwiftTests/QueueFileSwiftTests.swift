import Foundation
import Testing
@testable import QueueFileSwift

struct TestItem: Codable, Sendable, Equatable {
    let id: String
    let value: Int
}

@Test func testBasicQueueOperations() async throws {
    let tempDir = FileManager.default.temporaryDirectory
    let queuePath = tempDir.appendingPathComponent("test_queue_\(UUID().uuidString).qf").path

    let queue = try QueueFileSwiftQueue(path: queuePath)

    #expect(try await queue.isEmpty() == true)
    #expect(try await queue.size() == 0)

    let testData = "Hello, QueueFile!".data(using: .utf8)!
    try await queue.add(testData)

    #expect(try await queue.isEmpty() == false)
    #expect(try await queue.size() == 1)

    let peeked = try await queue.peek()
    #expect(peeked == testData)

    try await queue.remove()
    #expect(try await queue.isEmpty() == true)

    try FileManager.default.removeItem(atPath: queuePath)
}

@Test func testMultipleItems() async throws {
    let tempDir = FileManager.default.temporaryDirectory
    let queuePath = tempDir.appendingPathComponent("test_queue_multi_\(UUID().uuidString).qf").path

    let queue = try QueueFileSwiftQueue(path: queuePath)

    let items = ["First", "Second", "Third"].map { $0.data(using: .utf8)! }
    try await queue.addMultiple(items)

    #expect(try await queue.size() == 3)

    let allItems = try await queue.getAll()
    #expect(allItems.count == 3)
    #expect(allItems[0] == items[0])
    #expect(allItems[1] == items[1])
    #expect(allItems[2] == items[2])

    try await queue.clear()
    #expect(try await queue.isEmpty() == true)

    try FileManager.default.removeItem(atPath: queuePath)
}

@Test func testCodableQueue() async throws {
    let tempDir = FileManager.default.temporaryDirectory
    let queuePath = tempDir.appendingPathComponent("test_codable_queue_\(UUID().uuidString).qf").path

    let queue = try CodableQueueFile<TestItem>(path: queuePath)

    let item1 = TestItem(id: "1", value: 100)
    let item2 = TestItem(id: "2", value: 200)

    try await queue.add(item1)
    try await queue.add(item2)

    #expect(try await queue.size() == 2)

    let peeked = try await queue.peek()
    #expect(peeked == item1)

    let allItems = try await queue.getAll()
    #expect(allItems == [item1, item2])

    try await queue.clear()

    try FileManager.default.removeItem(atPath: queuePath)
}
