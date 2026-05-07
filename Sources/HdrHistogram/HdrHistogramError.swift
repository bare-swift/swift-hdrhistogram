// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

/// Errors thrown by ``HdrHistogram`` initializers and methods.
public enum HdrHistogramError: Error, Equatable, Sendable {
    /// `lowestDiscernibleValue` is < 1.
    case invalidLowestDiscernibleValue

    /// `highestTrackableValue` is < 2 * lowestDiscernibleValue.
    case invalidHighestTrackableValue

    /// `significantValueDigits` is not in 1...5.
    case invalidSignificantValueDigits

    /// `record(_:)` argument is < 0 or > `highestTrackableValue`.
    case valueOutOfRange

    /// `record(_:count:)` argument has count < 0.
    case invalidCount

    /// `record(corrected:expectedInterval:)` has expectedInterval ≤ 0.
    case invalidExpectedInterval

    /// `add(_:)` was called with a histogram of mismatched configuration.
    case mergeIncompatible
}
