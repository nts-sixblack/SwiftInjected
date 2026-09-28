import XCTest

@testable import SwiftInjected

protocol TestServiceProtocol {
  func foo() -> String
}

class TestService: TestServiceProtocol {
  func foo() -> String {
    return "bar"
  }
}

class AnotherService {
  let value = 42
}

final class SwiftInjectedTests: XCTestCase {

  func testInjection() {
    let dependencies = Dependencies {
      Dependency { TestService() }
    }

    dependencies.build()

    class Consumer {
      @Injected var service: TestService
    }

    let consumer = Consumer()
    XCTAssertEqual(consumer.service.foo(), "bar")
  }

  func testLazyResolution() {
    // Track whether the closure has been called
    var resolved = false
    let dependencies = Dependencies {
      Dependency { () -> TestService in
        resolved = true
        return TestService()
      }
    }

    // build() should NOT resolve anything
    dependencies.build()
    XCTAssertFalse(resolved, "Dependency should NOT be resolved during build()")

    // First access triggers resolution
    class Consumer {
      @Injected var service: TestService
    }
    let consumer = Consumer()
    _ = consumer.service
    XCTAssertTrue(resolved, "Dependency should be resolved on first access")
  }

  func testEagerBuild() {
    var resolved = false
    let dependencies = Dependencies {
      Dependency { () -> TestService in
        resolved = true
        return TestService()
      }
    }

    // buildEager() should resolve immediately
    dependencies.buildEager()
    XCTAssertTrue(resolved, "Dependency should be resolved during buildEager()")
  }

  func testMultipleDependencies() {
    let dependencies = Dependencies {
      Dependency { TestService() }
      Dependency { AnotherService() }
    }

    dependencies.build()

    class Consumer {
      @Injected var service: TestService
      @Injected var another: AnotherService
    }

    let consumer = Consumer()
    XCTAssertEqual(consumer.service.foo(), "bar")
    XCTAssertEqual(consumer.another.value, 42)
  }

  func testDuplicateRegistrationIgnored() {
    let dependencies = Dependencies {
      Dependency { TestService() }
      Dependency { TestService() }
    }

    dependencies.build()

    // Should still work — first registration wins
    class Consumer {
      @Injected var service: TestService
    }
    let consumer = Consumer()
    XCTAssertEqual(consumer.service.foo(), "bar")
  }
}
