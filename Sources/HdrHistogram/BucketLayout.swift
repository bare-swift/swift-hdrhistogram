// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

/// Internal: bucket arithmetic for ``HdrHistogram``.
///
/// HdrHistogram divides the dynamic range into powers-of-2 buckets, each
/// subdivided into a fixed number of equally-sized sub-buckets. The
/// sub-bucket count is the next power of 2 ≥ `2 * 10^significantValueDigits`,
/// which gives `significantValueDigits` decimal precision throughout the
/// range.
///
/// Reference: Java HdrHistogram (`AbstractHistogram.java`) and the Rust
/// `hdrhistogram` crate (`core/mod.rs`).
struct BucketLayout: Sendable, Equatable {
    let lowestDiscernibleValue: Int64
    let highestTrackableValue: Int64
    let significantValueDigits: Int

    /// `floor(log2(lowestDiscernibleValue))`.
    let unitMagnitude: Int

    /// Number of sub-buckets per bucket. Power of 2 ≥ `2 * 10^significantValueDigits`.
    let subBucketCount: Int

    /// `subBucketCount / 2`.
    let subBucketHalfCount: Int

    /// `log2(subBucketHalfCount)`.
    let subBucketHalfCountMagnitude: Int

    /// `(subBucketCount - 1) << unitMagnitude`.
    let subBucketMask: Int64

    /// Number of buckets needed to span [lowestDiscernibleValue, highestTrackableValue].
    let bucketCount: Int

    /// Total length of the flat counts array.
    let countsArrayLength: Int

    init(
        lowestDiscernibleValue: Int64,
        highestTrackableValue: Int64,
        significantValueDigits: Int
    ) throws(HdrHistogramError) {
        guard lowestDiscernibleValue >= 1 else {
            throw .invalidLowestDiscernibleValue
        }
        guard highestTrackableValue >= 2 * lowestDiscernibleValue else {
            throw .invalidHighestTrackableValue
        }
        guard significantValueDigits >= 1 && significantValueDigits <= 5 else {
            throw .invalidSignificantValueDigits
        }

        self.lowestDiscernibleValue = lowestDiscernibleValue
        self.highestTrackableValue = highestTrackableValue
        self.significantValueDigits = significantValueDigits

        let unitMag: Int = Self.floorLog2(UInt64(lowestDiscernibleValue))
        self.unitMagnitude = unitMag

        let largestValueWithSingleUnitResolution: Int64 = 2 * Self.pow10(significantValueDigits)
        let subBucketCountMagnitude: Int = Self.ceilLog2(UInt64(largestValueWithSingleUnitResolution))
        let subCount: Int = 1 << subBucketCountMagnitude
        self.subBucketCount = subCount
        self.subBucketHalfCount = subCount / 2
        self.subBucketHalfCountMagnitude = subBucketCountMagnitude - 1

        let mask: Int64 = (Int64(subCount) - 1) << unitMag
        self.subBucketMask = mask

        var bucketsNeeded: Int = 1
        var smallestUntrackable: Int64 = Int64(subCount) << unitMag
        while smallestUntrackable <= highestTrackableValue {
            if smallestUntrackable > Int64.max / 2 {
                bucketsNeeded += 1
                break
            }
            smallestUntrackable <<= 1
            bucketsNeeded += 1
        }
        self.bucketCount = bucketsNeeded

        self.countsArrayLength = (bucketsNeeded + 1) * (subCount / 2)
    }

    /// Map a value to a flat counts-array index.
    /// Caller is responsible for ensuring 0 ≤ value ≤ highestTrackableValue.
    func indexFor(_ value: Int64) -> Int {
        let bucketIdx: Int = self.bucketIndex(for: value)
        let subIndex: Int = self.subBucketIndex(for: value, bucketIndex: bucketIdx)
        return countsArrayIndex(bucketIndex: bucketIdx, subBucketIndex: subIndex)
    }

    /// Map a flat counts-array index back to the bucket midpoint value.
    func valueFor(_ index: Int) -> Int64 {
        let bucketIdx: Int = (index >> subBucketHalfCountMagnitude) - 1
        if bucketIdx < 0 {
            let subIdx: Int = index & (subBucketHalfCount - 1)
            return self.valueFromIndex(bucketIndex: 0, subBucketIndex: subIdx)
                + halfRange(bucketIndex: 0)
        } else {
            let subIdx: Int = (index & (subBucketHalfCount - 1)) + subBucketHalfCount
            return self.valueFromIndex(bucketIndex: bucketIdx, subBucketIndex: subIdx)
                + halfRange(bucketIndex: bucketIdx)
        }
    }

    // MARK: - Helpers

    private func bucketIndex(for value: Int64) -> Int {
        let masked: Int64 = value | subBucketMask
        let cl: Int = Self.ceilLog2(UInt64(masked) + 1)
        let raw: Int = cl - subBucketHalfCountMagnitude - unitMagnitude - 1
        return raw < 0 ? 0 : raw
    }

    private func subBucketIndex(for value: Int64, bucketIndex: Int) -> Int {
        let shift: Int = bucketIndex + unitMagnitude
        let v: UInt64 = UInt64(bitPattern: value) >> shift
        return Int(v)
    }

    private func countsArrayIndex(bucketIndex: Int, subBucketIndex: Int) -> Int {
        if bucketIndex == 0 {
            return subBucketIndex
        }
        let bucketBaseIndex: Int = (bucketIndex + 1) << subBucketHalfCountMagnitude
        let offsetInBucket: Int = subBucketIndex - subBucketHalfCount
        return bucketBaseIndex + offsetInBucket
    }

    private func valueFromIndex(bucketIndex: Int, subBucketIndex: Int) -> Int64 {
        let shift: Int = bucketIndex + unitMagnitude
        return Int64(subBucketIndex) << shift
    }

    private func halfRange(bucketIndex: Int) -> Int64 {
        let shift: Int = bucketIndex + unitMagnitude
        let unit: Int64 = Int64(1) << shift
        return unit / 2
    }

    // MARK: - Math primitives

    static func floorLog2(_ x: UInt64) -> Int {
        if x <= 1 { return 0 }
        return 63 - x.leadingZeroBitCount
    }

    static func ceilLog2(_ x: UInt64) -> Int {
        if x <= 1 { return 0 }
        return 64 - (x - 1).leadingZeroBitCount
    }

    static func pow10(_ n: Int) -> Int64 {
        var result: Int64 = 1
        for _ in 0..<n { result *= 10 }
        return result
    }
}
