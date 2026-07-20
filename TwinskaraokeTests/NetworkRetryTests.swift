import Foundation
import Testing
@testable import Twinskaraoke

@Suite("Network retry cancellation")
struct NetworkRetryTests {
    @Test("A cancelled retry exits with cancellation instead of retrying")
    func cancellationStopsRetries() async {
        let task = Task<Int, Error> {
            try await NetworkRetry.execute {
                throw URLError(.timedOut)
            }
        }

        task.cancel()

        do {
            _ = try await task.value
            Issue.record("Expected the cancelled retry task to throw")
        } catch is CancellationError {
            // Expected.
        } catch {
            Issue.record("Expected CancellationError, got \(error)")
        }
    }

    @Test("Conditional retries do not swallow cancellation")
    func conditionalCancellationStopsRetries() async {
        let task = Task<Int, Error> {
            try await NetworkRetry.execute(shouldRetry: { _ in true }) {
                throw URLError(.networkConnectionLost)
            }
        }

        task.cancel()

        do {
            _ = try await task.value
            Issue.record("Expected the cancelled conditional retry task to throw")
        } catch is CancellationError {
            // Expected.
        } catch {
            Issue.record("Expected CancellationError, got \(error)")
        }
    }
}
