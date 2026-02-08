import Testing
import Foundation
import Mockable
@testable import Infrastructure
@testable import Domain

@Suite
struct KimiUsageProbeTests {

    static let samplePsOutputWithKimi = """
    12345 /Applications/Kimi.app/Contents/MacOS/Kimi
    """

    static let samplePsOutputNoKimi = """
    12345 /path/to/some_other_binary --flag value
    """

    // MARK: - isAvailable Tests

    @Test
    func `isAvailable returns false when process not running`() async {
        // Given
        let mockExecutor = MockCLIExecutor()
        given(mockExecutor)
            .execute(binary: .any, args: .any, input: .any, timeout: .any, workingDirectory: .any, autoResponses: .any)
            .willReturn(CLIResult(output: Self.samplePsOutputNoKimi, exitCode: 0))

        let probe = KimiUsageProbe(cliExecutor: mockExecutor)

        // When & Then
        #expect(await probe.isAvailable() == false)
    }

    @Test
    func `isAvailable returns true when process detected`() async {
        // Given
        let mockExecutor = MockCLIExecutor()
        given(mockExecutor)
            .execute(binary: .any, args: .any, input: .any, timeout: .any, workingDirectory: .any, autoResponses: .any)
            .willReturn(CLIResult(output: Self.samplePsOutputWithKimi, exitCode: 0))

        let probe = KimiUsageProbe(cliExecutor: mockExecutor)

        // When & Then
        #expect(await probe.isAvailable() == true)
    }

    // MARK: - Probe Tests

    @Test
    func `probe returns snapshot on success`() async throws {
        // Given
        let mockExecutor = MockCLIExecutor()
        given(mockExecutor)
            .execute(binary: .any, args: .any, input: .any, timeout: .any, workingDirectory: .any, autoResponses: .any)
            .willReturn(CLIResult(output: Self.samplePsOutputWithKimi, exitCode: 0))

        let probe = KimiUsageProbe(cliExecutor: mockExecutor)

        // When
        let snapshot = try await probe.probe()

        // Then
        #expect(snapshot.providerId == "kimi")
        #expect(snapshot.quotas.count > 0)
    }
}
