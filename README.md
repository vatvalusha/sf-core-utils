# DML Result Strategy Library

A comprehensive Salesforce Apex library that provides standardized DML operation handling with consistent error reporting and result processing. This library implements the Strategy pattern to handle different types of DML results uniformly.

---

## Features

- **Unified DML Operations**: Standardized interface for bulk update, upsert, and delete operations  
- **Consistent Error Handling**: Converts all DML errors into a uniform format  
- **Strategy Pattern Implementation**: Extensible architecture for processing different DML result types  
- **Lightning Component Ready**: Simplified error structures suitable for Lightning component integration  
- **Bulk Operation Support**: Efficient handling of large data sets with proper error reporting  

---
## 🧱 Core Components

### `DmlResultService`

Main service class providing static methods for DML operations and result processing:

- `bulkUpdate(List<SObject>)` – Performs bulk update operations  
- `bulkUpsert(List<SObject>)` – Performs bulk upsert operations  
- `bulkDelete(List<SObject>)` – Performs bulk delete operations  
- `getGenericErrorResults(List<Object>)` – Converts any DML results to a standardized format  

---

### `DmlResult`

Standardized wrapper for DML operation results containing:

- `recordId` – ID of the processed record  
- `success` – Operation success indicator  
- `errors` – List of standardized error objects  

---

## 🧩 Strategy Pattern Implementation

- `IDmlResultStrategy` – Interface defining result processing contract  
- `SaveResultStrategy` – Handles `Database.SaveResult` objects  
- `UpsertResultStrategy` – Handles `Database.UpsertResult` objects  
- `DeleteResultStrategy` – Handles `Database.DeleteResult` objects  

---

## 🛠 Error Handling

`DmlError` class provides a simplified error structure:

- `fields` – Affected field names  
- `message` – Human-readable error message  
- `statusCode` – Error status code

---

## Usage Examples

### 1. Basic Bulk Operations

#### Update Operations

```apex
// Update multiple accounts
List<Account> accounts = [SELECT Id, Name, Industry FROM Account LIMIT 100];
for (Account acc : accounts) {
    acc.Industry = 'Technology';
}

List<DmlResult> results = DmlResultService.bulkUpdate(accounts);

// Process results
for (DmlResult result : results) {
    if (result.success) {
        System.debug('Successfully updated account: ' + result.recordId);
    } else {
        System.debug('Failed to update account: ' + result.recordId);
    }
}
```

#### Upsert Operations

```apex
// Upsert contacts with external ID
List<Contact> contacts = new List<Contact>{
    new Contact(Email = 'john@example.com', FirstName = 'John', LastName = 'Doe'),
    new Contact(Email = 'jane@example.com', FirstName = 'Jane', LastName = 'Smith')
};

List<DmlResult> results = DmlResultService.bulkUpsert(contacts);

// Check for successful upserts
Integer successCount = 0;
for (DmlResult result : results) {
    if (result.success) {
        successCount++;
    }
}
System.debug('Successfully upserted ' + successCount + ' contacts');
```

#### Delete Operations

```apex
// Delete inactive accounts
List<Account> inactiveAccounts = [SELECT Id FROM Account WHERE Active__c = false];

List<DmlResult> results = DmlResultService.bulkDelete(inactiveAccounts);

// Log deletion results
for (DmlResult result : results) {
    if (!result.success) {
        System.debug('Failed to delete account ' + result.recordId + ': ' + 
                    result.errors[0].message);
    }
}
```

### 2. Error Handling Patterns

#### Comprehensive Error Processing

```apex
List<Contact> contacts = new List<Contact>{
    new Contact(FirstName = 'Test'), // Missing required LastName
    new Contact(LastName = 'Valid', Email = 'valid@test.com')
};

List<Database.SaveResult> saveResults = Database.insert(contacts, false);
List<DmlResult> standardizedResults = DmlResultService.getGenericErrorResults(saveResults);

for (DmlResult result : standardizedResults) {
    if (!result.success) {
        System.debug('Record failed: ' + result.recordId);
        for (DmlError error : result.errors) {
            System.debug('Error Code: ' + error.statusCode);
            System.debug('Error Message: ' + error.message);
            System.debug('Affected Fields: ' + String.join(error.fields, ', '));
        }
    }
}
```

#### Building Error Response for Lightning Components

```apex
@AuraEnabled
public static Map<String, Object> processContactUpdates(List<Contact> contacts) {
    List<DmlResult> results = DmlResultService.bulkUpdate(contacts);
    
    Map<String, Object> response = new Map<String, Object>();
    List<String> errorMessages = new List<String>();
    Integer successCount = 0;
    
    for (DmlResult result : results) {
        if (result.success) {
            successCount++;
        } else {
            for (DmlError error : result.errors) {
                errorMessages.add('Record ' + result.recordId + ': ' + error.message);
            }
        }
    }
    
    response.put('successCount', successCount);
    response.put('totalCount', results.size());
    response.put('errors', errorMessages);
    response.put('hasErrors', !errorMessages.isEmpty());
    
    return response;
}
```

### 3. Advanced Usage Patterns

#### Mixed DML Operations with Unified Error Handling

```apex
public class DataMigrationService {
    
    public static void migrateAccountData(List<Account> accounts) {
        // Step 1: Update existing accounts
        List<Account> existingAccounts = new List<Account>();
        List<Account> newAccounts = new List<Account>();
        
        for (Account acc : accounts) {
            if (acc.Id != null) {
                existingAccounts.add(acc);
            } else {
                newAccounts.add(acc);
            }
        }
        
        // Process updates
        if (!existingAccounts.isEmpty()) {
            List<DmlResult> updateResults = DmlResultService.bulkUpdate(existingAccounts);
            logResults('UPDATE', updateResults);
        }
        
        // Process inserts
        if (!newAccounts.isEmpty()) {
            List<Database.SaveResult> insertResults = Database.insert(newAccounts, false);
            List<DmlResult> standardizedResults = DmlResultService.getGenericErrorResults(insertResults);
            logResults('INSERT', standardizedResults);
        }
    }
    
    private static void logResults(String operation, List<DmlResult> results) {
        Integer failures = 0;
        for (DmlResult result : results) {
            if (!result.success) {
                failures++;
                System.debug(operation + ' failed for ' + result.recordId);
            }
        }
        System.debug(operation + ' completed. Failures: ' + failures + '/' + results.size());
    }
}
```

#### Batch Processing with Error Accumulation

```apex
public class BatchAccountProcessor implements Database.Batchable<SObject> {
    
    private List<String> allErrors = new List<String>();
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id, Name, Industry FROM Account');
    }
    
    public void execute(Database.BatchableContext bc, List<Account> accounts) {
        // Transform data
        for (Account acc : accounts) {
            acc.Industry = 'Updated_' + acc.Industry;
        }
        
        // Process with standardized error handling
        List<DmlResult> results = DmlResultService.bulkUpdate(accounts);
        
        // Accumulate errors for final processing
        for (DmlResult result : results) {
            if (!result.success) {
                for (DmlError error : result.errors) {
                    allErrors.add('Account ' + result.recordId + ': ' + error.message);
                }
            }
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        if (!allErrors.isEmpty()) {
            // Send error report
            EmailService.sendErrorReport('Batch Account Processing Errors', allErrors);
        }
    }
}
```

### 4. Integration with Trigger Framework

#### Trigger Handler with Standardized Error Logging

```apex
public class AccountTriggerHandler {
    
    public static void handleAfterUpdate(List<Account> newAccounts, Map<Id, Account> oldMap) {
        List<Contact> contactsToUpdate = new List<Contact>();
        
        // Prepare related contacts for update
        for (Account acc: newAccounts) {
            if (acc.Industry != oldMap.get(acc.Id).Industry) {
                contactsToUpdate.addAll([SELECT Id, Department FROM Contact WHERE AccountId = :acc.Id]);
            }
        }
        
        if (!contactsToUpdate.isEmpty()) {
            // Update contacts with standardized error handling
            for (Contact con : contactsToUpdate) {
                con.Department = 'Updated Department';
            }
            
            List<DmlResult> results = DmlResultService.bulkUpdate(contactsToUpdate);
            
            // Log any failures
            for (DmlResult result : results) {
                if (!result.success) {
                    System.debug(LoggingLevel.ERROR, 
                        'Failed to update contact ' + result.recordId + ': ' + 
                        result.errors[0].message);
                }
            }
        }
    }
}
```

### 5. Testing Patterns

#### Comprehensive Test Coverage

```apex
@IsTest
private class DmlResultServiceIntegrationTest {
    
    @IsTest
    static void testMixedOperationsWithErrorHandling() {
        // Setup test data with intentional failures
        List<Account> accounts = new List<Account>{
            new Account(Name = 'Valid Account'),
            new Account(), // Missing required Name field
            new Account(Name = 'Another Valid Account')
        };
        
        // Test insert with mixed results
        List<Database.SaveResult> insertResults = Database.insert(accounts, false);
        List<DmlResult> standardizedResults = DmlResultService.getGenericErrorResults(insertResults);
        
        // Verify error handling
        Integer successCount = 0;
        Integer errorCount = 0;
        
        for (DmlResult result : standardizedResults) {
            if (result.success) {
                successCount++;
            } else {
                errorCount++;
                System.assert(!result.errors.isEmpty(), 'Failed result should have errors');
            }
        }
        
        System.assertEquals(1, errorCount, 'Should have one error for missing Name');
    }
}
```
## Best Practices

1. **Always Check Success Status**: Always verify `result.success` before assuming operation completed successfully
2. **Handle Partial Failures**: In bulk operations, some records may succeed while others fail
3. **Log Detailed Errors**: Use the error details for debugging and user feedback
4. **Use in Lightning Components**: The standardized structure makes it easy to display errors in UI
5. **Implement Retry Logic**: For transient errors, consider implementing retry mechanisms
6. **Monitor Performance**: For large datasets, consider batch processing patterns

## Benefits

- **Consistency**: All DML operations return the same result structure
- **Maintainability**: Strategy pattern allows easy extension for new DML result types
- **Error Visibility**: Comprehensive error reporting with field-level details
- **Lightning Integration**: Simplified error structures for frontend consumption
- **Bulk Processing**: Efficient handling of large datasets with detailed failure reporting

## Contributing

This library follows Salesforce best practices and is designed to be extended. To add support for new DML result types,
implement the `IDmlResultStrategy` interface and register it in the `DmlResultService.RESULT_PROCESSORS` map.
---

