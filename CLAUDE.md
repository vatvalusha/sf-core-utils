# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Salesforce Apex library project focused on standardized DML operations and utility classes. The codebase implements a **DML Result Strategy Library** that provides consistent error handling and result processing for Salesforce bulk operations.

## Architecture

### Core Design Patterns

- **Strategy Pattern**: Used extensively in the DML Result Strategy system (`IDmlResultStrategy` interface with concrete implementations)
- **Service Layer**: `DmlResultService` provides static methods for standardized DML operations
- **Wrapper Classes**: `DmlResult` and `DmlError` standardize error reporting across different DML operation types

### Key Components

1. **DML Result Strategy System** (`src/classes/Utilities/DMLResultStrategy/`)
   - `DmlResultService.cls`: Main service providing bulk operations (update, upsert, delete)
   - `IDmlResultStrategy.cls`: Interface for processing different DML result types
   - Strategy implementations: `SaveResultStrategy`, `UpsertResultStrategy`, `DeleteResultStrategy`
   - `DmlResult.cls` and `DmlError.cls`: Standardized result wrappers

2. **Utility Classes** (`src/classes/`)
   - `PicklistUtility.cls`: Handles Salesforce picklist dependencies and base64 encoding
   - `Constants.cls`: Application constants

3. **Test Classes** (`src/classes/Tests/`)
   - Follow Salesforce testing patterns with `@IsTest` annotation

## Development Environment

This project uses **Illuminated Cloud** as the primary development environment:
- TypeScript configuration managed by Illuminated Cloud (`src/lwc/tsconfig.json`)
- Offline symbol tables stored in `IlluminatedCloud/` directory
- Package metadata defined in `src/package.xml` (Salesforce API version 48.0)

## Code Conventions

### Apex Standards
- Use `with sharing` on all service classes for security
- Document classes with comprehensive `@description`, `@author`, and `@version` tags
- Include `@example` annotations for usage patterns
- Follow consistent error handling patterns using the DML Result Strategy system

### Error Handling Patterns
Always use the standardized DML Result Strategy for database operations:

```apex
// Preferred approach
List<DmlResult> results = DmlResultService.bulkUpdate(records);
for (DmlResult result : results) {
    if (!result.success) {
        // Handle errors using result.errors
    }
}
```

### Lightning Component Integration
The DML Result system is designed for Lightning component integration:
- `DmlError` class includes `@AuraEnabled` properties
- Error structures are simplified for frontend consumption
- Use `getGenericErrorResults()` to convert any DML results to standard format

## Testing Approach

- All test classes should be placed in `src/classes/Tests/`
- Use descriptive test method names following pattern: `testMethodName_Scenario_ExpectedResult`
- Test both success and failure scenarios, especially for DML operations
- Mock external dependencies and focus on unit testing individual components

## Key Development Guidelines

1. **Always use the DML Result Strategy system** for database operations instead of direct Database methods
2. **Extend the strategy pattern** by implementing `IDmlResultStrategy` for new DML result types
3. **Maintain consistent error reporting** using `DmlResult` and `DmlError` classes
4. **Follow Salesforce security best practices** with proper sharing rules (`with sharing`)
5. **Document new utility methods** with comprehensive examples and usage patterns