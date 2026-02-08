import Testing
import Foundation
@testable import Infrastructure
@testable import Domain

@Suite
struct KimiUsageProbeParsingTests {

    static let sampleResponse = """
    {
      "quotas": [
        {
          "model": "moonshot-v1-8k",
          "limit": 1000,
          "usage": 200,
          "resetTime": "2025-01-01T00:00:00Z"
        },
        {
          "model": "moonshot-v1-32k",
          "limit": 500,
          "usage": 500,
          "resetTime": "2025-01-02T00:00:00Z"
        }
      ],
      "account": {
        "email": "user@kimi.com"
      }
    }
    """

    @Test
    func `parses quota into UsageQuota`() throws {
        let data = Data(Self.sampleResponse.utf8)
        let snapshot = try KimiUsageProbe.parseResponse(data, providerId: "kimi")

        #expect(snapshot.quotas.count == 2)
        #expect(snapshot.quotas[0].quotaType == .modelSpecific("moonshot-v1-8k"))
        #expect(snapshot.quotas[1].quotaType == .modelSpecific("moonshot-v1-32k"))
    }

    @Test
    func `maps usage to percentRemaining`() throws {
        let data = Data(Self.sampleResponse.utf8)
        let snapshot = try KimiUsageProbe.parseResponse(data, providerId: "kimi")

        // 200 used out of 1000 limit -> 80% remaining
        #expect(snapshot.quotas[0].percentRemaining == 80.0)

        // 500 used out of 500 limit -> 0% remaining
        #expect(snapshot.quotas[1].percentRemaining == 0.0)
    }

    @Test
    func `parses reset time`() throws {
        let data = Data(Self.sampleResponse.utf8)
        let snapshot = try KimiUsageProbe.parseResponse(data, providerId: "kimi")

        let expectedDate = ISO8601DateFormatter().date(from: "2025-01-01T00:00:00Z")
        #expect(snapshot.quotas[0].resetsAt == expectedDate)
    }

    @Test
    func `extracts account email`() throws {
        let data = Data(Self.sampleResponse.utf8)
        let snapshot = try KimiUsageProbe.parseResponse(data, providerId: "kimi")

        #expect(snapshot.accountEmail == "user@kimi.com")
    }

    @Test
    func `handles invalid JSON`() throws {
        let data = Data("invalid json".utf8)

        #expect(throws: ProbeError.self) {
            try KimiUsageProbe.parseResponse(data, providerId: "kimi")
        }
    }
}
