/**
 * @description Service for standardized DML operations and error handling in Salesforce.
 * Provides unified interface for bulk DML operations (update, upsert, delete) with consistent
 * error handling and result standardization. Supports Lightning Components integration.
 *
 * Features:
 * - Bulk DML operations with standardized results
 * - Consistent error handling across operations
 * - Lightning-ready error reporting
 * - Sharing rules compliance
 *
 * @example 1
 * List<Account> accounts = [SELECT Id FROM Account LIMIT 10];
 * List<DmlResultService.DmlResult> results = DmlResultService.bulkUpdate(accounts);
 *
 * @example 2
 * List<Account> accounts = [SELECT Id FROM Account LIMIT 10];
 * List<DmlResult> result = DmlResultService.getGenericErrorResults(dmlResults);
 * 
 * @author Valerii Artemenko
 * @version 1.0
 */

public with sharing class DmlResultService {

    private static final Map<String, IDmlResultStrategy> RESULT_PROCESSORS = new Map<String, IDmlResultStrategy>{
            Database.SaveResult.class.getName() => new SaveResultStrategy(),
            Database.UpsertResult.class.getName() => new UpsertResultStrategy(),
            Database.DeleteResult.class.getName() => new DeleteResultStrategy()
    };

    /**
     * @description Converts various types of DML operation results into a standardized format. Takes a list of DML results (such as SaveResult, UpsertResult, or DeleteResult) and processes them using an appropriate strategy based on their type, returning a unified list of DmlResult objects.
     * @param dmlResults List<Object> The DML operation results to process
     * @return List<DmlResult> Standardized DML results, or empty list if input is invalid
     */
    public static List<DmlResult> getGenericErrorResults(List<Object> dmlResults) {
        if (dmlResults == null || dmlResults.isEmpty()) {
            return new List<DmlResult>();
        }

        String resultType = getClassName(dmlResults.get(0));
        IDmlResultStrategy strategy = RESULT_PROCESSORS.get(resultType);

        return RESULT_PROCESSORS.containsKey(resultType)
                ? strategy.process(dmlResults)
                : new List<DmlResult>();
    }

    /**
     * @description Performs a bulk update operation on a list of SObjects
     * @param records List of SObjects to update
     * @return List<DmlResult> Standardized results of the update operation
     */
    public static List<DmlResult> bulkUpdate(List<SObject> records) {
        List<Database.SaveResult> results = Database.update(records);
        List<DmlResult> dmlResults = new List<DmlResult>();
        for (Database.SaveResult item : results) {
            dmlResults.add(new DmlResult(item));
        }
        return dmlResults;
    }

    /**
     * @description Performs a bulk upsert operation on a list of SObjects
     * @param records List of SObjects to upsert
     * @return List<DmlResult> Standardized results of the upsert operation
     */
    public static List<DmlResult> bulkUpsert(List<SObject> records) {
        List<Database.UpsertResult> results = Database.upsert(records);
        List<DmlResult> dmlResult = new List<DmlResult>();
        for (Database.UpsertResult item : results) {
            dmlResult.add(new DmlResult(item));
        }
        return dmlResult;
    }

    /**
     * @description Performs a bulk delete operation on a list of SObjects
     * @param records List of SObjects to delete
     * @return List<DmlResult> Standardized results of the delete operation
     */
    public static List<DmlResult> bulkDelete(List<SObject> records) {
        List<Database.DeleteResult> results = Database.delete(records);
        List<DmlResult> dmlResults = new List<DmlResult>();
        for (Database.DeleteResult item : results) {
            dmlResults.add(new DmlResult(item));
        }
        return dmlResults;
    }

    private static String getClassName(Object obj) {
        String str = String.valueOf(obj);
        Integer idx = str.indexOf('[');
        return idx > 0
                ? str.substring(0, idx)
                : Constants.UNKNOWN;
    }
}