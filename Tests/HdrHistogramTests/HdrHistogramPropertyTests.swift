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

struct LCG {
    var state: UInt64
    init(seed: UInt64) { self.state = seed }
    mutating func nextU64() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
    mutating func nextUnit() -> Double {
        let v: UInt64 = nextU64() & ((1 << 53) - 1)
        return Double(v) / Double(1 << 53)
    }
    mutating func nextNormal() -> Double {
        let u1: Double = Swift.max(nextUnit(), 1e-300)
        let u2: Double = nextUnit()
        let r: Double = sqrt(-2.0 * log(u1))
        let theta: Double = 2.0 * .pi * u2
        return r * cos(theta)
    }
}

func trueValueAtRank(_ samples: [Int64], _ q: Double) -> Int64 {
    let sorted = samples.sorted()
    if sorted.isEmpty { return 0 }
    let n = sorted.count
    if q <= 0 { return sorted.first! }
    if q >= 1 { return sorted.last! }
    let rank: Int = Swift.max(0, Swift.min(n - 1, Int(q * Double(n))))
    return sorted[rank]
}

@Suite("HdrHistogram property tests")
struct HdrHistogramPropertyTests {
    static let nSamples = 50_000
    static let quantiles: [Double] = [0.5, 0.75, 0.9, 0.95, 0.99]

    private func runDistribution(name: String, samples: [Int64]) throws {
        var hist = try HdrHistogram(
            highestTrackableValue: 1_000_000_000,
            significantValueDigits: 3
        )
        for v in samples { try hist.record(v) }
        for q in Self.quantiles {
            let estimated = hist.valueAtQuantile(q)
            let trueValue = trueValueAtRank(samples, q)
            if abs(trueValue) > 1 {
                let relErr: Double = abs(Double(estimated - trueValue)) / Double(abs(trueValue))
                // HdrHistogram's precision bound (1/10^N) bounds the bucket-midpoint
                // vs any *recorded value* in that bucket. For property tests against
                // a true distribution-quantile (which may sit at a bucket edge), the
                // worst-case error is up to 2 * 1/10^N. Java HdrHistogram's own
                // tests use the same 2x relaxation.
                #expect(relErr <= 2e-3,
                        "\(name) q=\(q) true=\(trueValue) est=\(estimated) relErr=\(relErr)")
            }
        }
    }

    @Test("uniform distribution: percentiles within precision")
    func uniform() throws {
        var lcg = LCG(seed: 0x9E37_79B9_7F4A_7C15)
        var samples: [Int64] = []
        samples.reserveCapacity(Self.nSamples)
        for _ in 0..<Self.nSamples {
            samples.append(Int64(1 + lcg.nextUnit() * 999_999.0))
        }
        try runDistribution(name: "uniform", samples: samples)
    }

    @Test("exponential distribution: percentiles within precision")
    func exponential() throws {
        var lcg = LCG(seed: 0xDEAD_BEEF_CAFE_BABE)
        var samples: [Int64] = []
        samples.reserveCapacity(Self.nSamples)
        for _ in 0..<Self.nSamples {
            let u = Swift.max(lcg.nextUnit(), 1e-12)
            let v = Int64(-log(u) * 1000.0) + 1
            samples.append(v)
        }
        try runDistribution(name: "exponential", samples: samples)
    }

    @Test("lognormal distribution: percentiles within precision")
    func lognormal() throws {
        var lcg = LCG(seed: 0x1234_5678_90AB_CDEF)
        var samples: [Int64] = []
        samples.reserveCapacity(Self.nSamples)
        for _ in 0..<Self.nSamples {
            let v = Int64(exp(lcg.nextNormal()) * 1000.0) + 1
            samples.append(v)
        }
        try runDistribution(name: "lognormal", samples: samples)
    }
}
