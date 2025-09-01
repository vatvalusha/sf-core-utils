/**
 * # IDmlResultStrategy Interface
 *
 * ## Overview
 *`IDmlResultStrategy` is an interface that defines a contract for processing DML (Data Manipulation Language) operation results in Salesforce Apex. It provides a standardized way to handle results from different types of DML operations (insert, update, delete, undelete).
 *
 * ## Interface Details
 *
 * ### Method
 *  - **process(List<Object> results)**
 *  - **Purpose**: Transforms raw DML operation results into a standardized `DmlResult` format
 *  - **Parameters**:
 *  - `results`: List<Object> - A list of raw DML operation results
 *  - **Returns**: List<DmlResult> - A collection of processed DML results
 *  - **Responsibility**: Converts operation-specific results into a unified format for consistent error handling and result processing
 *
 * ## Usage
 * This interface is typically implemented by concrete classes that handle specific types of DML operations. For example:
 * - Database.SaveResult processing
 * - Database.DeleteResult processing
 * - Database.UndeleteResult processing
 * - Database.UpsertResult processing
 *
 * ## Implementation Example
 */
public interface IDmlResultStrategy {
    List<DmlResult> process(List<Object> results);
}