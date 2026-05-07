# swift-hdrhistogram

Sendable, Foundation-free [HdrHistogram](https://github.com/HdrHistogram/HdrHistogram) — Gil Tene's high-dynamic-range histogram with **fixed precision per decade**. Pairs with [swift-ddsketch](https://github.com/bare-swift/swift-ddsketch) (which gives a relative-error guarantee).

Translated from the Rust [`hdrhistogram`](https://crates.io/crates/hdrhistogram) crate.

Part of the [bare-swift](https://github.com/bare-swift) ecosystem.

## Install

```swift
.package(url: "https://github.com/bare-swift/swift-hdrhistogram.git", from: "0.1.0")
```

```swift
.product(name: "HdrHistogram", package: "swift-hdrhistogram")
```

## Usage

```swift
import HdrHistogram

// Latency in microseconds, up to 1 hour, 3-digit precision (0.1%).
var hist = try HdrHistogram(
    lowestDiscernibleValue: 1,
    highestTrackableValue: 3_600_000_000,
    significantValueDigits: 3
)

for sampleMicros in latencies {
    try hist.record(sampleMicros)
}

let p50 = hist.valueAtPercentile(50)         // ±0.1%
let p99 = hist.valueAtPercentile(99)         // ±0.1%
let mean = hist.mean
```

### When to choose HdrHistogram vs DDSketch

- **HdrHistogram:** you know the range up-front (latencies in µs / packet sizes / etc.) and want a known maximum count.
- **DDSketch:** the input distribution is unknown or extremely heavy-tailed, and you'd rather pay a relative-error budget than configure a range.

Both ship in bare-swift's observability tier; pick by guarantee shape.

## Documentation

Full DocC documentation: <https://bare-swift.github.io/swift-hdrhistogram/>

## Source

Translated from the Rust crate [`hdrhistogram`](https://crates.io/crates/hdrhistogram). Algorithm: Gil Tene, [HdrHistogram.org](https://hdrhistogram.org).

## License

Apache 2.0 with LLVM exception. See [LICENSE](./LICENSE) and [NOTICE](./NOTICE).
