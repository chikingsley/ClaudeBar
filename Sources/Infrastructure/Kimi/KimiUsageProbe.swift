import Foundation
import Domain

public struct KimiUsageProbe: UsageProbe {
    private let cliExecutor: any CLIExecutor

    public init(cliExecutor: (any CLIExecutor)? = nil) {
        self.cliExecutor = cliExecutor ?? DefaultCLIExecutor()
    }

    public func isAvailable() async -> Bool {
        do {
            // Simple check for running process using ps
            // In a real implementation, we might use pgrep or specific arguments
            let result = try cliExecutor.execute(
                binary: "/bin/ps",
                args: ["aux"],
                input: nil,
                timeout: 5.0,
                workingDirectory: nil,
                autoResponses: [:]
            )
            return result.output.contains("Kimi")
        } catch {
            return false
        }
    }

    public func probe() async throws -> UsageSnapshot {
        // TODO: Implement actual data fetching logic here.
        // Currently returning a hardcoded snapshot for demonstration purposes.
        // You would typically:
        // 1. Fetch data from a local API (like Antigravity) or remote API (like Gemini).
        // 2. Parse the response using parseResponse.

        // Example:
        // let data = try await fetchData()
        // return try Self.parseResponse(data, providerId: "kimi")

        // For now, return a hardcoded snapshot as we don't have the API
        let quota = UsageQuota(
            percentRemaining: 100.0,
            quotaType: .modelSpecific("moonshot-v1-8k"),
            providerId: "kimi",
            resetsAt: nil
        )

        return UsageSnapshot(
            providerId: "kimi",
            quotas: [quota],
            capturedAt: Date(),
            accountEmail: "user@kimi.com",
            accountTier: .free
        )
    }

    // For testing and future implementation
    static func parseResponse(_ data: Data, providerId: String) throws -> UsageSnapshot {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let response: KimiResponse
        do {
            response = try decoder.decode(KimiResponse.self, from: data)
        } catch {
             throw ProbeError.parseFailed("Invalid JSON: \(error.localizedDescription)")
        }

        let quotas = response.quotas.map { quota -> UsageQuota in
            // Calculate percentage remaining
            // usage 200, limit 1000 -> 20% used -> 80% remaining
            let usedPercent = Double(quota.usage) / Double(quota.limit) * 100.0
            let percentRemaining = max(0, 100.0 - usedPercent)

            return UsageQuota(
                percentRemaining: percentRemaining,
                quotaType: .modelSpecific(quota.model),
                providerId: providerId,
                resetsAt: quota.resetTime
            )
        }

        return UsageSnapshot(
            providerId: providerId,
            quotas: quotas,
            capturedAt: Date(),
            accountEmail: response.account.email,
            accountTier: nil
        )
    }
}

// Private response models
private struct KimiResponse: Decodable {
    let quotas: [KimiQuota]
    let account: KimiAccount
}

private struct KimiQuota: Decodable {
    let model: String
    let limit: Int
    let usage: Int
    let resetTime: Date
}

private struct KimiAccount: Decodable {
    let email: String
}
