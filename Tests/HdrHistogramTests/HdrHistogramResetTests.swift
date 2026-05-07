// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

import Testing
@testable import HdrHistogram

@Suite("HdrHistogram reset")
struct HdrHistogramResetTests {
    @Test("reset zeros count, min, max but keeps configuration")
    func resetZeros() throws {
        var h = try HdrHistogram(
            lowestDiscernibleValue: 1,
            highestTrackableValue: 100_000,
            significantValueDigits: 3
        )
        for v in 1...100 { try h.record(Int64(v)) }
        #expect(h.count == 100)
        h.reset()
        #expect(h.isEmpty)
        #expect(h.count == 0)
        #expect(h.min == 0)
        #expect(h.max == 0)
        #expect(h.lowestDiscernibleValue == 1)
        #expect(h.highestTrackableValue == 100_000)
        #expect(h.significantValueDigits == 3)
        try h.record(50)
        #expect(h.count == 1)
    }
}
