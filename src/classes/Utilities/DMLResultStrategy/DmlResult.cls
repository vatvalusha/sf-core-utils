/**
 * @description Wrapper class for handling DML operation results in a standardized way.
 * This class encapsulates the results of various DML operations (insert, update, upsert, delete)
 * and provides a consistent interface for accessing operation outcomes.
 */
public class DmlResult {

    /** @description ID of the record that was processed in the DML operation */
    public Id recordId;

    /** @description Indicates whether the DML operation was successful */
    public Boolean success;

    /** @description List of errors that occurred during the DML operation */
    public List<DmlError> errors;

    /**
     * @description Default constructor that initializes a new DmlResult instance
     * Sets success to false and initializes an empty errors list
     */
    public DmlResult() {
        this.success = false;
        this.errors = new List<DmlError>();
    }

    /**
     * @description Constructor that processes a Database.SaveResult
     * @param saveResult Result of insert or update DML operation
     */
    public DmlResult(Database.SaveResult saveResult) {
        this();
        this.recordId = saveResult.getId();
        this.success = saveResult.isSuccess();
        this.errors.addAll(this.processDatabaseErrors(saveResult.getErrors()));
    }

    /**
     * @description Constructor that processes a Database.UpsertResult
     * @param upsertResult Result of upsert DML operation
     */
    public DmlResult(Database.UpsertResult upsertResult) {
        this();
        this.recordId = upsertResult.getId();
        this.success = upsertResult.isSuccess();
        this.errors.addAll(this.processDatabaseErrors(upsertResult.getErrors()));
    }

    /**
     * @description Constructor that processes a Database.DeleteResult
     * @param deleteResult Result of delete DML operation
     */
    public DmlResult(Database.DeleteResult deleteResult) {
        this();
        this.recordId = deleteResult.getId();
        this.success = deleteResult.isSuccess();
        this.errors.addAll(this.processDatabaseErrors(deleteResult.getErrors()));
    }

    /**
     * @description Converts Salesforce Database.Error objects into custom DmlError objects
     * @param dbErrors List of Database.Error objects to process
     * @return List<DmlError> Converted list of DmlError objects
     * @private
     */
    private List<DmlError> processDatabaseErrors(List<Database.Error> dbErrors) {
        List<DmlError> errors = new List<DmlError>();
        for (Database.Error dbErrorItem : dbErrors) {
            errors.add(new DmlError(dbErrorItem));
        }

        return errors;
    }
}