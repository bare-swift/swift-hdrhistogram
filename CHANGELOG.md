# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.1.0] - 2026-05-07

### Added
- `HdrHistogram` value type — Sendable, Foundation-free fixed-precision-per-decade quantile structure. Configurable `lowestDiscernibleValue` (default 1), `highestTrackableValue`, `significantValueDigits` (1–5).
- Recording: `record(_:)` (single sample), `record(_:count:)` (weighted), `record(corrected:expectedInterval:)` (Gil Tene's coordinated-omission correction).
- Queries: `valueAtPercentile(_:)` (0–100 scale), `valueAtQuantile(_:)` (0–1 alias), `count`, `mean`, `stdDeviation`, `min`, `max`, `isEmpty`, `recordedValueRange`.
- Merging: `add(_:)` — exact configuration match required; throws `mergeIncompatible` on mismatch.
- Reset: `reset()` — zero counts; keep layout.
- `HdrHistogramError` typed error enum (`invalidLowestDiscernibleValue`, `invalidHighestTrackableValue`, `invalidSignificantValueDigits`, `valueOutOfRange`, `invalidCount`, `invalidExpectedInterval`, `mergeIncompatible`).
- DocC documentation, full README example, NOTICE crediting upstream Rust `hdrhistogram` crate, Java HdrHistogram, and Gil Tene's algorithm work.

### Limitations (out of scope for v0.1)
- Iteration APIs (`recordedValues`, `allValues`, `linearBucketValues`, `logarithmicBucketValues`).
- V2 serialization (zlib over packed counts; will use swift-bytes when added).
- AtomicHistogram / ConcurrentHistogram — v0.1 is single-threaded.
- Recorder pattern (read-write split).
- DoubleHistogram (auto-resizing).
- HdrLogV2 (time-series histogram log format).
