/**
 * @description Wrapper class that encapsulates Salesforce DML (Data Manipulation Language) error information
 * from Database.Error object into a simplified structure.
 * 
 * This class provides a way to handle and transport DML error details in a more manageable format,
 * particularly useful when working with bulk operations or API responses.
 * 
 * @property {List<String>} fields - List of field names that caused or are related to the DML error
 * @property {String} message - The error message describing what went wrong during the DML operation
 * @property {String} statusCode - The status code of the error converted to String format
 */
public with sharing class DmlError {
    public List<String> fields;
    public String message;
    public String statusCode;

    /**
     * @description Constructor that transforms a Database.Error object into DmlError
     * @param dbError The Salesforce Database.Error object containing error details
     */
    public DmlError(Database.Error dbError) {
        this.fields = dbError.fields;
        this.message = dbError.message;
        this.statusCode = String.valueOf(dbError.statusCode);
    }
}