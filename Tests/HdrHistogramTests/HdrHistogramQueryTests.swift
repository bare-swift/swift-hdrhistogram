// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#endif

import Testing
@testable import HdrHistogram

@Suite("HdrHistogram queries")
struct HdrHistogramQueryTests {
    @Test("empty histogram returns 0 for percentile / mean / std")
    func empty() throws {
        let h = try HdrHistogram(highestTrackableValue: 1000, significantValueDigits: 3)
        #expect(h.valueAtPercentile(50) == 0)
        #expect(h.valueAtQuantile(0.5) == 0)
        #expect(h.mean == 0)
        #expect(h.stdDeviation == 0)
    }

    @Test("single value: any percentile returns that value within precision")
    func singleValue() throws {
        var h = try HdrHistogram(highestTrackableValue: 1_000_000, significantValueDigits: 3)
        try h.record(42)
        for p in [0.0, 25.0, 50.0, 75.0, 99.0, 100.0] {
            let r = h.valueAtPercentile(p)
            let relErr = abs(Double(r - 42)) / 42.0
            #expect(relErr <= 0.001, "p=\(p) result=\(r)")
        }
    }

    @Test("uniform 1...10000: percentiles within 0.1% of value-at-rank")
    func uniformRange() throws {
        var h = try HdrHistogram(highestTrackableValue: 100_000, significantValueDigits: 3)
        for v in 1...10_000 { try h.record(Int64(v)) }
        let cases: [(Double, Int64)] = [
            (50.0, 5000), (90.0, 9000), (95.0, 9500), (99.0, 9900),
        ]
        for (p, trueValue) in cases {
            let r = h.valueAtPercentile(p)
            let relErr = abs(Double(r - trueValue)) / Double(trueValue)
            #expect(relErr <= 0.001, "p=\(p) true=\(trueValue) got=\(r) relErr=\(relErr)")
        }
    }

    @Test("valueAtQuantile and valueAtPercentile agree (q × 100 = p)")
    func quantilePercentileAgreement() throws {
        var h = try HdrHistogram(highestTrackableValue: 100_000, significantValueDigits: 3)
        for v in 1...1000 { try h.record(Int64(v)) }
        for q in [0.5, 0.9, 0.99] {
            let qResult = h.valueAtQuantile(q)
            let pResult = h.valueAtPercentile(q * 100)
            #expect(qResult == pResult, "q=\(q)")
        }
    }

    @Test("mean of {1, 2, 3, 4, 5} equals 3")
    func meanSmall() throws {
        var h = try HdrHistogram(highestTrackableValue: 1000, significantValueDigits: 3)
        for v: Int64 in [1, 2, 3, 4, 5] { try h.record(v) }
        #expect(abs(h.mean - 3.0) <= 0.01)
    }

    @Test("stdDeviation of {1,2,3,4,5} ≈ √2")
    func stdSmall() throws {
        var h = try HdrHistogram(highestTrackableValue: 1000, significantValueDigits: 3)
        for v: Int64 in [1, 2, 3, 4, 5] { try h.record(v) }
        let expected = sqrt(2.0)
        #expect(abs(h.stdDeviation - expected) <= 0.05)
    }

    @Test("p=0 returns ~min, p=100 returns ~max")
    func extremes() throws {
        var h = try HdrHistogram(highestTrackableValue: 100_000, significantValueDigits: 3)
        for v in 1...1000 { try h.record(Int64(v)) }
        let p0 = h.valueAtPercentile(0)
        let p100 = h.valueAtPercentile(100)
        #expect(abs(Double(p0 - 1)) / 1.0 <= 0.001)
        #expect(abs(Double(p100 - 1000)) / 1000.0 <= 0.001)
    }

    @Test("percentile clamps to [0, 100]")
    func percentileClamp() throws {
        var h = try HdrHistogram(highestTrackableValue: 1000, significantValueDigits: 3)
        for v in 1...100 { try h.record(Int64(v)) }
        #expect(h.valueAtPercentile(-1) == h.valueAtPercentile(0))
        #expect(h.valueAtPercentile(101) == h.valueAtPercentile(100))
    }
}
