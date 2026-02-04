# SwiftInjected

A lightweight, simple, and type-safe dependency injection library for Swift.

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/nts-sixblack/SwiftInjected.git", from: "1.0.0")
]
```

## Usage

### 1. Define your dependencies

First, create a protocol and a concrete implementation for your service.

```swift
protocol NetworkServiceProtocol {
    func fetch()
}

class NetworkService: NetworkServiceProtocol {
    func fetch() {
        print("Fetching data...")
    }
}
```

### 2. Register dependencies

You need to register your dependencies at the start of your application (e.g., in `AppDelegate` or `SceneDelegate`).

```swift
import SwiftInjected

// Configure dependencies
let dependencies = Dependencies {
    Dependency { NetworkService() }
}

// Build the dependency graph
dependencies.build()
```

### 3. Inject dependencies

Use the `@Injected` property wrapper to inject the dependency into your classes or structs.

```swift
import SwiftInjected

class MyViewModel {
    @Injected var networkService: NetworkService
    
    func loadData() {
        networkService.fetch()
    }
}
```

### 4. SwiftUI with ObservableObject

For SwiftUI views observing an `ObservableObject`, use `@InjectedObservable`.

```swift
import SwiftUI
import SwiftInjected

class MyViewModel: ObservableObject, NetworkServiceProtocol {
    @Published var data: String = ""
    // ...
}

struct MyView: View {
    @InjectedObservable var viewModel: MyViewModel
    
    var body: some View {
        Text(viewModel.data)
    }
}
```


## Advanced Usage

### Customizing Dependency Name

By default, the dependency name is the class name. You can customize it if needed, although the current implementation primarily uses type inference.

### Resolving dependencies manually

You can also resolve dependencies manually if needed, though `@Injected` is preferred.

```swift
let service: NetworkService = Dependencies.shared.resolve() // Internal method, prefer @Injected
```

(Note: `Dependencies.shared` is used internally by the property wrapper).

## License

This library is released under the MIT License.
