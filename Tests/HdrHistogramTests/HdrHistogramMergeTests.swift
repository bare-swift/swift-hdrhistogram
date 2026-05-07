// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

import Testing
@testable import HdrHistogram

@Suite("HdrHistogram merge")
struct HdrHistogramMergeTests {
    @Test("merging an empty histogram is a no-op")
    func mergeEmpty() throws {
        var a = try HdrHistogram(highestTrackableValue: 100_000, significantValueDigits: 3)
        try a.record(100); try a.record(200)
        let b = try HdrHistogram(highestTrackableValue: 100_000, significantValueDigits: 3)
        try a.add(b)
        #expect(a.count == 2)
    }

    @Test("merging into empty adopts the other's contents")
    func emptyMergeNonEmpty() throws {
        var a = try HdrHistogram(highestTrackableValue: 100_000, significantValueDigits: 3)
        var b = try HdrHistogram(highestTrackableValue: 100_000, significantValueDigits: 3)
        try b.record(100); try b.record(200); try b.record(300)
        try a.add(b)
        #expect(a.count == 3)
        #expect(a.recordedValueRange.min == 100)
        #expect(a.recordedValueRange.max == 300)
    }

    @Test("merge sums counts, expands min/max")
    func basicMerge() throws {
        var a = try HdrHistogram(highestTrackableValue: 100_000, significantValueDigits: 3)
        try a.record(100); try a.record(200)
        var b = try HdrHistogram(highestTrackableValue: 100_000, significantValueDigits: 3)
        try b.record(50); try b.record(500)
        try a.add(b)
        #expect(a.count == 4)
        #expect(a.recordedValueRange.min == 50)
        #expect(a.recordedValueRange.max == 500)
    }

    @Test("merge with mismatched configuration throws .mergeIncompatible")
    func mismatchedConfig() throws {
        var a = try HdrHistogram(highestTrackableValue: 100_000, significantValueDigits: 3)
        let b = try HdrHistogram(highestTrackableValue: 100_000, significantValueDigits: 4)
        #expect(throws: HdrHistogramError.mergeIncompatible) {
            try a.add(b)
        }
    }

    @Test("merge is associative on counts")
    func associative() throws {
        var a = try HdrHistogram(highestTrackableValue: 10_000, significantValueDigits: 3)
        var b = try HdrHistogram(highestTrackableValue: 10_000, significantValueDigits: 3)
        for v in 1...100 { try a.record(Int64(v)) }
        for v in 200...300 { try b.record(Int64(v)) }
        try a.add(b)
        #expect(a.count == 100 + 101)
        #expect(a.recordedValueRange.min == 1)
        #expect(a.recordedValueRange.max == 300)
    }
}
