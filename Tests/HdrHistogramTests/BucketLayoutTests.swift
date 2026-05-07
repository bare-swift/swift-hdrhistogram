// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

import Testing
@testable import HdrHistogram

@Suite("BucketLayout")
struct BucketLayoutTests {
    /// Canonical Java HdrHistogram example: 1µs lowest, 1 hour highest, 3 digits.
    static let canonical = try! BucketLayout(
        lowestDiscernibleValue: 1,
        highestTrackableValue: 3_600_000_000,
        significantValueDigits: 3
    )

    @Test("subBucketCount = nextPowerOf2(2 * 10^significantValueDigits)")
    func subBucketCount() {
        #expect(Self.canonical.subBucketCount == 2048)
    }

    @Test("subBucketHalfCount = subBucketCount / 2")
    func subBucketHalfCount() {
        #expect(Self.canonical.subBucketHalfCount == 1024)
    }

    @Test("countsArrayLength has space for the configured range")
    func countsArrayLength() {
        let n = Self.canonical.countsArrayLength
        #expect(n > 0)
        #expect(n < 1_000_000)
    }

    @Test("indexFor(value) returns valid array indices for the configured range")
    func indexForRange() throws {
        let testValues: [Int64] = [1, 10, 100, 1_000, 10_000, 100_000,
                                   1_000_000, 10_000_000, 100_000_000,
                                   1_000_000_000, 3_600_000_000]
        for v in testValues {
            let idx = Self.canonical.indexFor(v)
            #expect(idx >= 0)
            #expect(idx < Self.canonical.countsArrayLength,
                    "v=\(v) idx=\(idx) length=\(Self.canonical.countsArrayLength)")
        }
    }

    @Test("valueFor(indexFor(v)) is within precision bound")
    func roundTripValueIndexValue() throws {
        let bound: Double = 0.001
        let testValues: [Int64] = [1, 10, 100, 1_000, 10_000, 100_000,
                                   1_000_000, 10_000_000, 100_000_000,
                                   1_000_000_000, 3_600_000_000]
        for v in testValues {
            let idx = Self.canonical.indexFor(v)
            let recovered = Self.canonical.valueFor(idx)
            let relErr = abs(Double(recovered - v)) / Double(v)
            #expect(relErr <= bound,
                    "v=\(v) recovered=\(recovered) relErr=\(relErr)")
        }
    }

    @Test("indexFor is monotone non-decreasing across the range")
    func indexMonotone() throws {
        var lastIdx: Int = -1
        for v in stride(from: Int64(1), to: Int64(1_000_000), by: 100) {
            let idx = Self.canonical.indexFor(v)
            #expect(idx >= lastIdx, "v=\(v) idx=\(idx) lastIdx=\(lastIdx)")
            lastIdx = idx
        }
    }

    @Test("layout for sigDigits=2 has half the resolution per decade vs sigDigits=3")
    func layoutForSigDigits2() throws {
        let layout2 = try BucketLayout(
            lowestDiscernibleValue: 1,
            highestTrackableValue: 1_000_000,
            significantValueDigits: 2
        )
        #expect(layout2.subBucketCount == 256)
    }

    @Test("layout for sigDigits=4 has finer resolution")
    func layoutForSigDigits4() throws {
        let layout4 = try BucketLayout(
            lowestDiscernibleValue: 1,
            highestTrackableValue: 1_000_000,
            significantValueDigits: 4
        )
        #expect(layout4.subBucketCount == 32768)
    }
}
