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
    // Resolve dependency immediately upon initialization
    self.dependency = Dependencies.shared.resolve()
  }

  public var wrappedValue: T {
    dependency
    // Typically the service is the single source of truth so usually not set directly here
  }
}

// Extension to support resolving in the struct wrapper
extension Dependencies {
  fileprivate func resolve<T>() -> T {
    guard let dependency = dependencies.first(where: { $0.value is T })?.value as? T else {
      fatalError("Can't resolve \(T.self)")
    }
    return dependency
  }
}
