/**
 * @description Strategy implementation for handling Salesforce Delete DML operation results.
 * Implements IDmlResultStrategy interface to process Database.DeleteResult objects.
 */
public with sharing class DeleteResultStrategy implements IDmlResultStrategy {
    
    /**
     * @description Processes a list of Database.DeleteResult objects and returns DmlResult objects for failed operations
     * @param results List of Object - Contains Database.DeleteResult objects to be processed
     * @return List<DmlResult> List of DmlResult objects containing information about failed delete operations
     */
    public List<DmlResult> process(List<Object> results) {
        return getDeleteResults((List<Database.DeleteResult>) results);
    }

    /**
     * @description Helper method that converts Database.DeleteResult objects into DmlResult objects
     * @param dmlResults List of Database.DeleteResult objects from delete operations
     * @return List<DmlResult> List containing only the failed delete operations as DmlResult objects
     * @private
     */
    private static List<DmlResult> getDeleteResults(List<Database.DeleteResult> dmlResults) {
        List<DmlResult> result = new List<DmlResult>();
        for (Database.DeleteResult sr : dmlResults) {
            if (!sr.isSuccess()) {
                result.add(new DmlResult(sr));
            }
        }
        return result;
    }
}