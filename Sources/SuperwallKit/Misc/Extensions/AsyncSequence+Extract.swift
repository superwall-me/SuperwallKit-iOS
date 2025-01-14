//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AsyncExtensions.swift
//
//  Created by Nacho Soto on 9/27/22.

extension AsyncSequence {
  /// Returns the elements of the asynchronous sequence.
  func extractValues() async rethrows -> [Element] {
    return try await self.reduce(into: []) {
      $0.append($1)
    }
  }
}
