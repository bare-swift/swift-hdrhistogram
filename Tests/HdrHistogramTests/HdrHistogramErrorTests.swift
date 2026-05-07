// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

import Testing
@testable import HdrHistogram

@Suite("HdrHistogramError")
struct HdrHistogramErrorTests {
    @Test("HdrHistogramError is Sendable, Equatable, Error")
    func conformances() {
        let a: HdrHistogramError = .invalidLowestDiscernibleValue
        let b: HdrHistogramError = .invalidLowestDiscernibleValue
        let c: HdrHistogramError = .valueOutOfRange
        #expect(a == b)
        #expect(a != c)
        let _: any Error = a
        let _: any Sendable = a
    }

    @Test("All seven cases are distinguishable")
    func cases() {
        let xs: [HdrHistogramError] = [
            .invalidLowestDiscernibleValue,
            .invalidHighestTrackableValue,
            .invalidSignificantValueDigits,
            .valueOutOfRange,
            .invalidCount,
            .invalidExpectedInterval,
            .mergeIncompatible,
        ]
        for i in 0..<xs.count {
            for j in 0..<xs.count where i != j {
                #expect(xs[i] != xs[j])
            }
        }
    }
}
