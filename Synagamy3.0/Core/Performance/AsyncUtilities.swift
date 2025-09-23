//
//  AsyncUtilities.swift
//  Synagamy3.0
//
//  Utility functions for async operations
//

import Foundation

/// Executes an async operation with a timeout
/// - Parameters:
///   - seconds: Timeout duration in seconds
///   - operation: The async operation to execute
/// - Returns: The result of the operation
/// - Throws: TimeoutError if the operation takes longer than the specified timeout
func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        // Add the actual operation
        group.addTask {
            try await operation()
        }
        
        // Add the timeout task
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw TimeoutError()
        }
        
        // Return the first completed task and cancel the rest
        defer { group.cancelAll() }
        return try await group.next()!
    }
}

struct TimeoutError: Error, LocalizedError {
    var errorDescription: String? {
        return "Operation timed out"
    }
}

/// Debounces an async operation to prevent rapid repeated calls
actor Debouncer {
    private var task: Task<Void, Never>?
    
    func debounce(for duration: TimeInterval, operation: @escaping () async -> Void) {
        task?.cancel()
        task = Task {
            do {
                try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                await operation()
            } catch {
                // Task was cancelled - this is expected behavior
            }
        }
    }
}

/// Throttles an async operation to prevent excessive calls
actor Throttler {
    private var lastExecutionTime: Date = .distantPast
    
    func throttle(interval: TimeInterval, operation: @escaping () async -> Void) async {
        let now = Date()
        if now.timeIntervalSince(lastExecutionTime) >= interval {
            lastExecutionTime = now
            await operation()
        }
    }
}

/// Retries an async operation with exponential backoff
func withRetry<T>(
    maxAttempts: Int = 3,
    baseDelay: TimeInterval = 1.0,
    operation: @escaping () async throws -> T
) async throws -> T {
    var lastError: Error?
    
    for attempt in 1...maxAttempts {
        do {
            return try await operation()
        } catch {
            lastError = error
            
            if attempt < maxAttempts {
                let delay = baseDelay * pow(2.0, Double(attempt - 1))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
    }
    
    throw lastError ?? TimeoutError()
}

/// Combines multiple async operations and provides progress updates
func withProgress<T>(
    operations: [() async throws -> T],
    progressHandler: @escaping (Double) -> Void
) async throws -> [T] {
    var results: [T] = []
    
    for (index, operation) in operations.enumerated() {
        let result = try await operation()
        results.append(result)
        
        let progress = Double(index + 1) / Double(operations.count)
        progressHandler(progress)
    }
    
    return results
}