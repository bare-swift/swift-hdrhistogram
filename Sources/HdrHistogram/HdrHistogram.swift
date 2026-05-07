// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

/// Sendable, Foundation-free HdrHistogram — fixed-precision-per-decade
/// quantile structure.
///
/// Pairs with `swift-ddsketch` (relative-error guarantee). Use HdrHistogram
/// when you know the input range up-front and want a known maximum count.
public struct HdrHistogram: Sendable {
    public init() {
        fatalError("not implemented yet — Task 7")
    }
}
