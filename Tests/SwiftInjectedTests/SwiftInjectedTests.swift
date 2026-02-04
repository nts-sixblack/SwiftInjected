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

final class SwiftInjectedTests: XCTestCase {

  func testInjection() {
    let dependencies = Dependencies {
      Dependency { TestService() }
    }

    dependencies.build()

    class Convert {
      @Injected var service: TestService
    }

    let convert = Convert()
    XCTAssertEqual(convert.service.foo(), "bar")
  }
}
