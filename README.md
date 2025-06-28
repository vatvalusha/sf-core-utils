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

## Usage Examples

```apex
// Bulk update with standardized results
List<Account> accounts = [SELECT Id, Name FROM Account LIMIT 10];
List<DmlResult> updateResults = DmlResultService.bulkUpdate(accounts);

// Process mixed DML results uniformly
List<Database.SaveResult> saveResults = Database.insert(records, false);
List<DmlResult> standardizedResults = DmlResultService.getGenericErrorResults(saveResults);

// Error handling
for (DmlResult result : standardizedResults) {
    if (!result.success) {
        for (DmlError error : result.errors) {
            System.debug('Error on fields ' + error.fields + ': ' + error.message);
        }
    }
}
```


