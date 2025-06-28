/**
 * @description Strategy implementation for processing Database.UpsertResult objects.
 *
 * @implements IDmlResultStrategy
 */
public with sharing class UpsertResultStrategy implements IDmlResultStrategy {

    /**
     * @description Processes a list of Database.UpsertResult objects and converts them to DmlResult objects
     * @param results List<Object> - List of Database.UpsertResult objects to process
     * @return List<DmlResult> - List of DmlResult objects containing error information for failed operations
     */
    public List<DmlResult> process(List<Object> results) {
        return getUpsertResults((List<Database.UpsertResult>) results);
    }

    /**
     * @description Converts Database.UpsertResult objects to DmlResult objects, filtering only failed operations
     * @param dmlResults List<Database.UpsertResult> - List of upsert operation results
     * @return List<DmlResult> - List of DmlResult objects containing only failed operations
     * @private
     */
    private static List<DmlResult> getUpsertResults(List<Database.UpsertResult> dmlResults) {
        List<DmlResult> result = new List<DmlResult>();
        for (Database.UpsertResult sr : dmlResults) {
            if (!sr.isSuccess()) {
                result.add(new DmlResult(sr));
            }
        }
        return result;
    }
}