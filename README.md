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

**Bulk update with standardized results:**
```apex
List<Account> accounts = [SELECT Id, Name FROM Account LIMIT 10];
List<DmlResult> updateResults = DmlResultService.bulkUpdate(accounts);
```

**Process mixed DML results uniformly:**
```apex
List<Database.SaveResult> saveResults = Database.insert(records, false);
List<DmlResult> standardizedResults = DmlResultService.getGenericErrorResults(saveResults);
```

**Error handling:**
```apex
for (DmlResult result : standardizedResults) {
    if (!result.success) {
        for (DmlError error : result.errors) {
            System.debug('Error on fields ' + error.fields + ': ' + error.message);
        }
    }
}
```
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

