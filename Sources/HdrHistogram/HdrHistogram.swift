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

extension HdrHistogram {
    // MARK: - Queries

    /// Returns the value at the `percentile`-th percentile (0–100 scale).
    /// Clamps `percentile` to [0, 100]. Returns 0 for the empty histogram.
    public func valueAtPercentile(_ percentile: Double) -> Int64 {
        if _count == 0 { return 0 }
        let clamped: Double = Swift.max(0.0, Swift.min(100.0, percentile))
        let target: Double = (clamped / 100.0) * Double(_count)
        let targetCount: UInt64 = UInt64(target.rounded(.up))
        var cumulative: UInt64 = 0
        for i in 0..<counts.count {
            let c: UInt64 = counts[i]
            if c == 0 { continue }
            cumulative &+= c
            if cumulative >= targetCount {
                return layout.valueFor(i)
            }
        }
        return _max
    }

    /// Alias for `valueAtPercentile(quantile * 100)`.
    public func valueAtQuantile(_ quantile: Double) -> Int64 {
        valueAtPercentile(quantile * 100.0)
    }

    /// Mean of all recorded values, weighted by their counts. Returns 0 for empty.
    public var mean: Double {
        if _count == 0 { return 0 }
        var weightedSum: Double = 0
        var n: Double = 0
        for i in 0..<counts.count {
            let c: UInt64 = counts[i]
            if c == 0 { continue }
            let v: Double = Double(layout.valueFor(i))
            weightedSum += v * Double(c)
            n += Double(c)
        }
        return weightedSum / n
    }

    /// Population standard deviation. Returns 0 for empty.
    public var stdDeviation: Double {
        if _count == 0 { return 0 }
        let m: Double = mean
        var sqSum: Double = 0
        var n: Double = 0
        for i in 0..<counts.count {
            let c: UInt64 = counts[i]
            if c == 0 { continue }
            let v: Double = Double(layout.valueFor(i))
            let d: Double = v - m
            sqSum += (d * d) * Double(c)
            n += Double(c)
        }
        let variance: Double = sqSum / n
        return variance.squareRoot()
    }
}

extension HdrHistogram {
    /// Coordinated-omission correction. Per Gil Tene: if a sample at `value`
    /// arrives at intervals of `expectedInterval` and `value > expectedInterval`,
    /// record `value` plus synthetic samples for `value - expectedInterval`,
    /// `value - 2 * expectedInterval`, ... down to (but not below) `expectedInterval`.
    public mutating func record(
        corrected value: Int64,
        expectedInterval: Int64
    ) throws(HdrHistogramError) {
        guard expectedInterval > 0 else { throw .invalidExpectedInterval }
        try record(value)
        if value <= expectedInterval { return }
        var missing: Int64 = value - expectedInterval
        while missing >= expectedInterval {
            try record(missing)
            missing -= expectedInterval
        }
    }
}

extension HdrHistogram {
    // MARK: - Merge

    /// Add another histogram's counts into self. Both histograms must share
    /// `(lowestDiscernibleValue, highestTrackableValue, significantValueDigits)`.
    public mutating func add(_ other: HdrHistogram) throws(HdrHistogramError) {
        guard self.layout == other.layout else { throw .mergeIncompatible }
        if other._count == 0 { return }
        for i in 0..<counts.count {
            counts[i] &+= other.counts[i]
        }
        if _count == 0 {
            _min = other._min
            _max = other._max
        } else {
            if other._min < _min { _min = other._min }
            if other._max > _max { _max = other._max }
        }
        _count &+= other._count
    }

    // MARK: - Reset

    public mutating func reset() {
        for i in 0..<counts.count { counts[i] = 0 }
        _count = 0
        _min = 0
        _max = 0
    }
}
