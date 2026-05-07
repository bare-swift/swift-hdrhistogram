# ``HdrHistogram``

Sendable, Foundation-free HdrHistogram — fixed-precision-per-decade quantile structure.

## Overview

HdrHistogram divides the dynamic range `[lowestDiscernibleValue,
highestTrackableValue]` into powers-of-2 buckets, each subdivided so that
every bucket gives `significantValueDigits` decimal precision. The same
histogram answers p50, p99, p99.99 within the precision bound.

```swift
import HdrHistogram

var hist = try HdrHistogram(
    highestTrackableValue: 3_600_000_000,    // 1 hour in µs
    significantValueDigits: 3                 // 0.1% precision
)
for sample in latencies { try hist.record(sample) }
let p99 = hist.valueAtPercentile(99)
```

## Topics

### Construction

- ``HdrHistogram/init(lowestDiscernibleValue:highestTrackableValue:significantValueDigits:)``

### Recording

- ``HdrHistogram/record(_:)``
- ``HdrHistogram/record(_:count:)``
- ``HdrHistogram/record(corrected:expectedInterval:)``

### Queries

- ``HdrHistogram/valueAtPercentile(_:)``
- ``HdrHistogram/valueAtQuantile(_:)``
- ``HdrHistogram/count``
- ``HdrHistogram/mean``
- ``HdrHistogram/stdDeviation``
- ``HdrHistogram/min``
- ``HdrHistogram/max``
- ``HdrHistogram/isEmpty``
- ``HdrHistogram/recordedValueRange``

### Merge & reset

- ``HdrHistogram/add(_:)``
- ``HdrHistogram/reset()``

### Configuration introspection

- ``HdrHistogram/lowestDiscernibleValue``
- ``HdrHistogram/highestTrackableValue``
- ``HdrHistogram/significantValueDigits``

### Errors

- ``HdrHistogramError``
