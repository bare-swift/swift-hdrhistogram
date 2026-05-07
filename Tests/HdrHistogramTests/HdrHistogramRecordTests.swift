// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

import Testing
@testable import HdrHistogram

@Suite("HdrHistogram record")
struct HdrHistogramRecordTests {
    @Test("init with valid params sets configuration introspection")
    func validInit() throws {
        let h = try HdrHistogram(
            lowestDiscernibleValue: 1,
            highestTrackableValue: 1_000_000,
            significantValueDigits: 3
        )
        #expect(h.lowestDiscernibleValue == 1)
        #expect(h.highestTrackableValue == 1_000_000)
        #expect(h.significantValueDigits == 3)
        #expect(h.isEmpty)
        #expect(h.count == 0)
        #expect(h.min == 0)
        #expect(h.max == 0)
    }

    @Test("init throws on invalid params")
    func invalidInit() {
        #expect(throws: HdrHistogramError.invalidLowestDiscernibleValue) {
            try HdrHistogram(lowestDiscernibleValue: 0, highestTrackableValue: 100, significantValueDigits: 3)
        }
        #expect(throws: HdrHistogramError.invalidHighestTrackableValue) {
            try HdrHistogram(lowestDiscernibleValue: 10, highestTrackableValue: 10, significantValueDigits: 3)
        }
        #expect(throws: HdrHistogramError.invalidSignificantValueDigits) {
            try HdrHistogram(highestTrackableValue: 1000, significantValueDigits: 0)
        }
        #expect(throws: HdrHistogramError.invalidSignificantValueDigits) {
            try HdrHistogram(highestTrackableValue: 1000, significantValueDigits: 6)
        }
    }

    @Test("record(_:) increments count and updates min/max")
    func recordSingle() throws {
        var h = try HdrHistogram(highestTrackableValue: 1_000_000, significantValueDigits: 3)
        try h.record(100)
        try h.record(500)
        try h.record(50)
        #expect(h.count == 3)
        #expect(h.recordedValueRange.min == 50)
        #expect(h.recordedValueRange.max == 500)
    }

    @Test("record(_:count:) increments by weight")
    func recordWeighted() throws {
        var h = try HdrHistogram(highestTrackableValue: 1_000_000, significantValueDigits: 3)
        try h.record(100, count: 5)
        try h.record(200, count: 3)
        #expect(h.count == 8)
    }

    @Test("record out-of-range throws .valueOutOfRange")
    func recordOutOfRange() throws {
        var h = try HdrHistogram(highestTrackableValue: 1000, significantValueDigits: 3)
        #expect(throws: HdrHistogramError.valueOutOfRange) {
            try h.record(-1)
        }
        #expect(throws: HdrHistogramError.valueOutOfRange) {
            try h.record(1_000_000)
        }
    }

    @Test("record(_:count:) with count < 0 throws .invalidCount")
    func recordInvalidCount() throws {
        var h = try HdrHistogram(highestTrackableValue: 1000, significantValueDigits: 3)
        #expect(throws: HdrHistogramError.invalidCount) {
            try h.record(100, count: -1)
        }
    }

    @Test("record 1...10000 produces correct count and recordedValueRange")
    func recordRange() throws {
        var h = try HdrHistogram(highestTrackableValue: 100_000, significantValueDigits: 3)
        for v in 1...10_000 { try h.record(Int64(v)) }
        #expect(h.count == 10_000)
        #expect(h.recordedValueRange.min == 1)
        #expect(h.recordedValueRange.max == 10_000)
    }

    @Test("HdrHistogram is Sendable")
    func sendable() throws {
        let h = try HdrHistogram(highestTrackableValue: 1000, significantValueDigits: 3)
        let _: any Sendable = h
    }
}
