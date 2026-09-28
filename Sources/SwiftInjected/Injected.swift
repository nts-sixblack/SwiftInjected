//
//  Injected.swift
//  SwiftInjected
//
//  Created by sau.nguyen on 20/5/25.
//

import Foundation

public struct Dependency {
  public typealias ResolveBlock<T> = () -> T

  fileprivate var value: Any?
  fileprivate let block: ResolveBlock<Any>
  fileprivate let name: String
  fileprivate let typeKey: ObjectIdentifier

  public init<T>(_ block: @escaping ResolveBlock<T>) {
    self.block = block
    self.value = nil
    name = String(describing: T.self)
    typeKey = ObjectIdentifier(T.self)
  }

  /// Resolves and caches the value. Returns the resolved value.
  @discardableResult
  mutating func resolve() -> Any {
    if let value = value {
      return value
    }
    let resolved = block()
    value = resolved
    return resolved
  }
}

@dynamicMemberLookup
open class Dependencies: Sequence {
  public private(set) static var shared = Dependencies()

  /// Storage: keyed by ObjectIdentifier for O(1) lookup
  private var dependencyMap = [ObjectIdentifier: Int]()
  var dependencies = [Dependency]()

  /// Lock for thread-safe lazy resolution
  private let lock = NSLock()

  @resultBuilder public struct DependencyBuilder {
    public static func buildBlock(_ dependency: Dependency) -> Dependency { dependency }
    public static func buildBlock(_ dependencies: Dependency...) -> [Dependency] { dependencies }
  }

  public init(@DependencyBuilder _ dependencies: () -> [Dependency]) {
    dependencies().forEach { register($0) }
  }

  public init(@DependencyBuilder _ dependency: () -> Dependency) {
    register(dependency())
  }

  /// Builds the dependency graph.
  ///
  /// Dependencies are resolved **lazily** on first access, so this method
  /// only publishes the container as `shared`. If you need every dependency
  /// to be available immediately (e.g. for validation), call `buildEager()`.
  open func build() {
    Self.shared = self
  }

  /// Eagerly resolves every registered dependency, then publishes.
  /// Use only when you need to validate the full graph at startup.
  open func buildEager() {
    lock.lock()
    for index in dependencies.indices {
      dependencies[index].resolve()
    }
    lock.unlock()
    Self.shared = self
  }

  /// Returns iterator for all registered dependencies (resolves lazily)
  public func makeIterator() -> AnyIterator<Any> {
    var index = dependencies.startIndex
    return AnyIterator {
      guard index < self.dependencies.endIndex else { return nil }
      let value = self.resolveDependency(at: index)
      index += 1
      return value
    }
  }

  /// Return dependency by given camelCase name of the object type
  /// For example: if dependency registered as `MyService` name should be `myService`
  public subscript<T>(dynamicMember name: String) -> T? {
    let typeName = name.prefix(1).capitalized + name.dropFirst()
    lock.lock()
    defer { lock.unlock() }
    guard let index = dependencies.firstIndex(where: { $0.name == typeName }) else {
      return nil
    }
    return dependencies[index].resolve() as? T
  }

  // MARK: - Internal Resolution

  func resolve<T>() -> T {
    let key = ObjectIdentifier(T.self)
    lock.lock()
    defer { lock.unlock() }

    // O(1) lookup by type
    if let index = dependencyMap[key] {
      return dependencies[index].resolve() as! T
    }

    // Fallback: check by `is T` for protocol conformance resolution
    if let index = dependencies.firstIndex(where: {
      // Resolve on the fly if needed, then check type
      let val = $0.value ?? $0.block()
      return val is T
    }) {
      // Cache the mapping for future lookups
      dependencyMap[key] = index
      return dependencies[index].resolve() as! T
    }

    fatalError("Can't resolve \(T.self)")
  }

  // MARK: - Private

  fileprivate init() {}

  fileprivate func register(_ dependency: Dependency) {
    // Avoid duplicates
    guard dependencyMap[dependency.typeKey] == nil else {
      debugPrint("\(dependency.name) already registered, ignoring")
      return
    }
    let index = dependencies.count
    dependencies.append(dependency)
    dependencyMap[dependency.typeKey] = index
  }

  private func resolveDependency(at index: Int) -> Any {
    lock.lock()
    defer { lock.unlock() }
    return dependencies[index].resolve()
  }
}

@propertyWrapper
public class Injected<Dependency> {
  private var dependency: Dependency!

  public var wrappedValue: Dependency {
    if dependency == nil {
      let copy: Dependency = Dependencies.shared.resolve()
      dependency = copy
    }
    return dependency
  }

  public init() {}
}
