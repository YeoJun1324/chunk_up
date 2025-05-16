# ChunkUp Architecture Guide

This document outlines the architecture and code organization principles for the ChunkUp project.

## Project Structure

The project follows Clean Architecture principles with the following layers:

```
lib/
├── core/               # Core functionality used across all layers
│   ├── constants/      # App-wide constants
│   ├── exceptions/     # Custom exceptions
│   ├── services/       # Core services (logging, error handling, etc.)
│   └── utils/          # Utility classes and extensions
├── data/               # Data layer
│   ├── datasources/    # Data sources (remote, local)
│   ├── models/         # Data models
│   └── repositories/   # Repository implementations
├── di/                 # Dependency injection
├── domain/             # Domain layer
│   ├── entities/       # Business entities
│   ├── models/         # Domain models
│   ├── repositories/   # Repository interfaces
│   └── usecases/       # Use cases (business logic)
└── presentation/       # Presentation layer
    ├── providers/      # State management
    ├── screens/        # UI screens
    ├── utils/          # Presentation-specific utils
    └── widgets/        # Reusable widgets
```

## Import Guidelines

1. Always use package imports (`package:chunk_up/...`) instead of relative imports.
2. Follow the dependency rule: outer layers can import from inner layers, but not vice versa.
   - Presentation can import Domain and Core
   - Domain can import Core only
   - Data can import Domain and Core
   - Core should not import from any other layer

## Dependency Injection

- Use GetIt for dependency injection
- Register dependencies in `lib/di/service_locator.dart`
- Avoid direct instantiation of dependencies; use DI instead

## Best Practices

1. **Avoid Circular Dependencies**: Never create circular references between classes.
2. **Follow Single Responsibility Principle**: Each class should have only one reason to change.
3. **Use Repository Pattern**: Data sources should be abstracted behind repositories.
4. **Separation of Concerns**: Keep UI logic in the presentation layer, business logic in domain layer.
5. **Error Handling**: Use the ErrorService for consistent error handling.
6. **Logging**: Use LoggingService for all logging needs.

## State Management

The project uses Provider for state management:
- Use ChangeNotifier for simple state
- Register providers in the DI container
- Access providers through the GetIt instance or Provider.of

## Testing

- Place tests in the `test/` directory mirroring the `lib/` structure
- Use mocks for dependencies when testing
- Write tests for each layer independently