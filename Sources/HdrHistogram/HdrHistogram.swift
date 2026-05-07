// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

/// Sendable, Foundation-free HdrHistogram — fixed-precision-per-decade
/// quantile structure.
public struct HdrHistogram: Sendable {
    let layout: BucketLayout
    var counts: [UInt64]
    var _count: Int64 = 0
    var _min: Int64 = 0
    var _max: Int64 = 0

    public init(
        lowestDiscernibleValue: Int64 = 1,
        highestTrackableValue: Int64,
        significantValueDigits: Int
    ) throws(HdrHistogramError) {
        let layout = try BucketLayout(
            lowestDiscernibleValue: lowestDiscernibleValue,
            highestTrackableValue: highestTrackableValue,
            significantValueDigits: significantValueDigits
        )
        self.layout = layout
        self.counts = Array(repeating: 0, count: layout.countsArrayLength)
    }

    // MARK: - Configuration introspection

    public var lowestDiscernibleValue: Int64 { layout.lowestDiscernibleValue }
    public var highestTrackableValue: Int64 { layout.highestTrackableValue }
    public var significantValueDigits: Int { layout.significantValueDigits }

    // MARK: - State

    public var count: Int64 { _count }
    public var isEmpty: Bool { _count == 0 }
    public var min: Int64 { _min }
    public var max: Int64 { _max }
    public var recordedValueRange: (min: Int64, max: Int64) { (_min, _max) }

    // MARK: - Recording

    public mutating func record(_ value: Int64) throws(HdrHistogramError) {
        try recordInternal(value: value, count: 1)
    }

    public mutating func record(_ value: Int64, count: Int64) throws(HdrHistogramError) {
        guard count >= 0 else { throw .invalidCount }
        if count == 0 { return }
        try recordInternal(value: value, count: count)
    }

    private mutating func recordInternal(value: Int64, count: Int64) throws(HdrHistogramError) {
        guard value >= 0 && value <= layout.highestTrackableValue else {
            throw .valueOutOfRange
        }
        let idx: Int = layout.indexFor(value)
        guard idx >= 0 && idx < counts.count else { throw .valueOutOfRange }
        counts[idx] &+= UInt64(count)
        if _count == 0 {
            _min = value
            _max = value
        } else {
            if value < _min { _min = value }
            if value > _max { _max = value }
        }
        _count &+= count
    }
}
