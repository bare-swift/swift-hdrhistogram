// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

import Testing
@testable import HdrHistogram

@Suite("HdrHistogram coordinated-omission correction")
struct HdrHistogramCorrectedTests {
    @Test("record(corrected:expectedInterval:) when value <= expectedInterval records once")
    func valueAtOrBelowInterval() throws {
        var h = try HdrHistogram(highestTrackableValue: 1_000_000, significantValueDigits: 3)
        try h.record(corrected: 50, expectedInterval: 100)
        try h.record(corrected: 100, expectedInterval: 100)
        #expect(h.count == 2)
    }

    @Test("record(corrected:expectedInterval:) when value > expectedInterval records synthetic samples")
    func syntheticSamples() throws {
        var h = try HdrHistogram(highestTrackableValue: 1_000_000, significantValueDigits: 3)
        // Recording 1000 with expectedInterval 100:
        //   real:       1000
        //   synthetic:  900, 800, 700, 600, 500, 400, 300, 200, 100
        // Total = 10 samples.
        try h.record(corrected: 1000, expectedInterval: 100)
        #expect(h.count == 10)
        #expect(h.recordedValueRange.min == 100)
        #expect(h.recordedValueRange.max == 1000)
    }

    @Test("record(corrected:expectedInterval:) with non-divisible value")
    func nonDivisible() throws {
        var h = try HdrHistogram(highestTrackableValue: 1_000_000, significantValueDigits: 3)
        // value=350, expectedInterval=100:
        //   real:       350
        //   synthetic:  250, 150
        //   stop: 50 < 100, no further.
        // Total = 3 samples.
        try h.record(corrected: 350, expectedInterval: 100)
        #expect(h.count == 3)
    }

    @Test("record(corrected:expectedInterval:) with expectedInterval ≤ 0 throws")
    func invalidExpectedInterval() throws {
        var h = try HdrHistogram(highestTrackableValue: 1_000, significantValueDigits: 3)
        #expect(throws: HdrHistogramError.invalidExpectedInterval) {
            try h.record(corrected: 100, expectedInterval: 0)
        }
        #expect(throws: HdrHistogramError.invalidExpectedInterval) {
            try h.record(corrected: 100, expectedInterval: -1)
        }
    }

    @Test("record(corrected:expectedInterval:) propagates value-out-of-range")
    func outOfRangePropagated() throws {
        var h = try HdrHistogram(highestTrackableValue: 1000, significantValueDigits: 3)
        #expect(throws: HdrHistogramError.valueOutOfRange) {
            try h.record(corrected: 5000, expectedInterval: 100)
        }
    }
}
