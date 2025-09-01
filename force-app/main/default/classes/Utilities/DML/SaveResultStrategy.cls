/**
 * @description Implements the IDmlResultStrategy interface to process Database.SaveResult objects
 * and convert them into a list of DmlResult objects. This strategy specifically handles
 * results from DML insert and update operations.
 *
 * @implements IDmlResultStrategy
 */
public with sharing class SaveResultStrategy implements IDmlResultStrategy {
    
    /**
     * @description Processes a list of Database.SaveResult objects and converts them into DmlResult objects
     * @param results List<Object> - A list of Database.SaveResult objects to process
     * @return List<DmlResult> - A list containing DmlResult objects for failed operations only
     */
    public List<DmlResult> process(List<Object> results) {
        return getSaveResults((List<Database.SaveResult>) results);
    }
    
    /**
     * @description Converts Database.SaveResult objects into DmlResult objects, filtering for failures
     * @param dmlResults List<Database.SaveResult> - The save results to process
     * @return List<DmlResult> - A list of DmlResult objects representing failed operations
     * @private
     */
    private static List<DmlResult> getSaveResults(List<Database.SaveResult> dmlResults) {
        List<DmlResult> result = new List<DmlResult>();
        for (Database.SaveResult sr : dmlResults) {
            if (!sr.isSuccess()) {
                result.add(new DmlResult(sr));
            }
        }
        return result;
    }
}