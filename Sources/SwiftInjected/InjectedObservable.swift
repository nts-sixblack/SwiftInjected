//
//  InjectedObservable.swift
//  SwiftInjected
//
//  Created by sau.nguyen on 4/2/26.
//

import SwiftUI

/// Wrapper designed for SwiftUI Views to listen to changes from a Service
@propertyWrapper
public struct InjectedObservable<T: ObservableObject>: DynamicProperty {

  // Use @ObservedObject for SwiftUI to listen
  @ObservedObject private var dependency: T

  public init() {
    // Resolve dependency (lazy — resolved on first access from container)
    self.dependency = Dependencies.shared.resolve()
  }

  public var wrappedValue: T {
    dependency
  }
}
