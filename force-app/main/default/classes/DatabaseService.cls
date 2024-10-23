/**
 * @description     A service class for performing common database operations (query, insert, update, upsert, delete)
 *                  It runs with `inherited sharing` so inherited the sharing model of its consuming class
 *                  Default options:
 *                      - accessLevel: `AccessLevel.USER_MODE`
 *                      - throwIfRemovedFields: `false` (Fields are silently removed)
 *                      - allowFieldTruncation: `true` (Fields are silently truncated if too long)
 *                      - optAllOrNone: `false` (Allows for partial success of DML operations)
 * 
 * @example
 * ```java
  *     DatabaseService db = new DatabaseService()
 *         .withAccessLevel(System.AccessLevel.SYSTEM_MODE)
 *         .throwIfRemovedFields('Account', new Set<String>{'Industry'});
 * ```

 */
public inherited sharing class DatabaseService {
  @TestVisible
  private System.AccessLevel accessLevel = System.AccessLevel.USER_MODE;
  @TestVisible
  private Boolean throwIfRemovedFields = false;
  @TestVisible
  private Map<String, Set<String>> requiredFieldsMap = new Map<String, Set<String>>();
  @TestVisible
  private Database.DmlOptions dmlOptions;
  /**
   * @description Returns true if all fields are required and none were specified in the requiredFieldsMap.
   */
  private Boolean allFieldsRequired {
    get {
      return this.throwIfRemovedFields && this.requiredFieldsMap.isEmpty();
    }
  }
  /**
   * @description Exception class to be thrown when critical fields are removed due to field-level security.
   */
  public class RemovedFieldsException extends Exception {
  }

  // CONSTRUCTOR AND CHAINING METHODS
  /**
   * @description Constructor
   */
  public DatabaseService() {
    this.dmlOptions = new Database.DmlOptions();
    this.dmlOptions.allowFieldTruncation = true;
    this.dmlOptions.optAllOrNone = false;
  }
  /**
   * @description     Sets the allOrNone option for DML operations.
   * @param           optAllOrNone - Boolean indicating whether the DML operation should succeed or fail as a whole.
   * @return          This DatabaseService instance for method chaining.
   */
  public DatabaseService allOrNone(Boolean optAllOrNone) {
    this.dmlOptions.optAllOrNone = optAllOrNone;
    return this;
  }
  /**
   * @description     Configures the service to throw an exception if the specified fields are removed
   *                  due to field-level security (FLS) restrictions.
   * @param           objectApiName - The API name of the object whose fields are being checked.
   * @param           requiredFieldApiNames - A set of field API names that are required for the object.
   * @return          This DatabaseService instance for method chaining.
   */
  public DatabaseService throwIfRemovedFields(
    String objectApiName,
    Set<String> requiredFieldApiNames
  ) {
    if (
      String.isBlank(objectApiName) ||
      requiredFieldApiNames == null ||
      requiredFieldApiNames.isEmpty()
    ) {
      throw new IllegalArgumentException(
        '"objectApiName" and "requiredFieldApiNames" cannot be null or empty.'
      );
    }
    this.throwIfRemovedFields = true;
    this.requiredFieldsMap.put(objectApiName, requiredFieldApiNames);
    return this;
  }
  /**
   * @description     Configures the service to throw an exception if any fields are removed due to FLS restrictions.
   * @param           throwIfRemovedFields - Boolean indicating whether to throw if any field is removed.
   * @return          This DatabaseService instance for method chaining.
   */
  public DatabaseService throwIfRemovedFields(Boolean throwIfRemovedFields) {
    this.throwIfRemovedFields = true;
    return this;
  }
  /**
   * @description     Sets custom DML options for this service.
   * @param           dmlOptions - A Database.DmlOptions object to customize DML behavior (e.g., allow field truncation, allOrNone).
   * @see             https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_methods_system_database_dmloptions.htm
   * @return          This DatabaseService instance for method chaining.
   */
  public DatabaseService withOptions(Database.DmlOptions dmlOptions) {
    this.dmlOptions = dmlOptions;
    return this;
  }
  /**
   * @description     Sets the access level for database operations (USER_MODE or SYSTEM_MODE).
   * @param           accessLevel - The System.AccessLevel to be used for database operations.
   * @return          This DatabaseService instance for method chaining.
   */
  public DatabaseService withAccessLevel(System.AccessLevel accessLevel) {
    this.accessLevel = accessLevel;
    return this;
  }

  // QUERY METHODS
  /**
   * @description     Executes a SOQL query
   * @param           query - The SOQL query string to be executed.
   * @return          An array of SObjects results
   */
  public SObject[] doQuery(String query) {
    SObject[] records = Database.query(query, System.AccessLevel.SYSTEM_MODE);
    records = guardAgainstRemovedFields(AccessType.READABLE, records);
    return records;
  }
  /**
   * @description     Executes a SOQL query with bind variables
   * @param           queries - The SOQL query string to be executed.
   * @param           bindMap - A map of bind variables to be used in the query.
   * @return          An array of SObjects results
   */
  public SObject[] doQueryWithBinds(String query, Map<String, Object> bindMap) {
    SObject[] records = Database.queryWithBinds(
      query,
      bindMap,
      System.AccessLevel.SYSTEM_MODE
    );
    records = guardAgainstRemovedFields(AccessType.READABLE, records);
    return records;
  }

  // INSERT METHODS
  /**
   * @description     Inserts a single record
   * @param           record - The SObject to be inserted.
   * @return          Database.SaveResult
   */
  public Database.SaveResult doInsert(SObject record) {
    record = guardAgainstRemovedFields(AccessType.CREATABLE, record);
    return Database.insert(record, dmlOptions, accessLevel);
  }
  /**
   * @description     Inserts multiple records
   * @param           records - An array of SObjects to be inserted.
   * @return          Database.SaveResult[]
   */
  public Database.SaveResult[] doInsert(SObject[] records) {
    records = guardAgainstRemovedFields(AccessType.CREATABLE, records);
    return Database.insert(records, dmlOptions, accessLevel);
  }

  // UPDATE METHODS
  /**
   * @description     Updates a single record
   * @param           record - The SObject to be updated.
   * @return          Database.SaveResult
   */
  public Database.SaveResult doUpdate(SObject record) {
    record = guardAgainstRemovedFields(AccessType.UPDATABLE, record);
    return Database.update(record, dmlOptions, accessLevel);
  }
  /**
   * @description     Updates multiple records
   * @param           records - An array of SObjects to be updated.
   * @return          Database.SaveResult[]
   */
  public Database.SaveResult[] doUpdate(SObject[] records) {
    records = guardAgainstRemovedFields(AccessType.UPDATABLE, records);
    return Database.update(records, dmlOptions, accessLevel);
  }

  // DELETE METHODS
  /**
   * @description     Deletes a single record
   * @param           record - The SObject to be deleted.
   * @return          Database.SaveResult
   */
  public Database.DeleteResult doDelete(SObject record) {
    return Database.delete(record, dmlOptions.OptAllOrNone, accessLevel);
  }
  /**
   * @description     Deletes multiple records
   * @param           records - An array of SObjects to be deleted.
   * @return          Database.SaveResult[]
   */
  public Database.DeleteResult[] doDelete(SObject[] records) {
    return Database.delete(records, dmlOptions.OptAllOrNone, accessLevel);
  }

  // UPSERT METHODS
  /**
   * @description     Upserts a single record, using Id as the upsert key
   * @param           record - The SObject to be upserted.
   * @return          Database.UpsertResult
   */
  public Database.UpsertResult doUpsert(SObject record) {
    record = guardAgainstRemovedFields(AccessType.UPSERTABLE, record);
    return Database.upsert(record, dmlOptions.OptAllOrNone, accessLevel);
  }
  /**
   * @description     Upserts a single record, using specified upsert key
   * @param           records - An array of SObjects to be deleted.
   * @param           externalIdField - Field to use as upsert key
   * @return          Database.UpsertResult[]
   */
  public Database.UpsertResult doUpsert(
    SObject record,
    Schema.SObjectField externalIdField
  ) {
    record = guardAgainstRemovedFields(AccessType.UPSERTABLE, record);
    return Database.upsert(
      record,
      externalIdField,
      dmlOptions.OptAllOrNone,
      accessLevel
    );
  }
  /**
   * @description     Upserts multiple records, using Id as the upsert key
   * @param           records - An array of SObjects to be upserted.
   * @return          Database.UpsertResult[]
   */
  public Database.UpsertResult[] doUpsert(SObject[] records) {
    records = guardAgainstRemovedFields(AccessType.UPSERTABLE, records);
    return Database.upsert(records, dmlOptions.OptAllOrNone, accessLevel);
  }
  /**
   * @description     Upserts multiple records, using Id as the upsert key
   * @param           records - An array of SObjects to be upserted.
   * @param           externalIdField - Field to use as upsert key
   * @return          Database.UpsertResult[]
   */
  public Database.UpsertResult[] doUpsert(
    SObject[] records,
    Schema.SObjectField externalIdField
  ) {
    records = guardAgainstRemovedFields(AccessType.UPSERTABLE, records);
    return Database.upsert(
      records,
      externalIdField,
      dmlOptions.OptAllOrNone,
      accessLevel
    );
  }

  // UTILITY METHODS
  /**
   * @description		Strips inaccessible fields or throws an exception if throwIfRemovedFields flag is true
   * @param			    accessType - System.AccessType to use in security decision
   * @param             record - SObject record whose fields should be guarded
   * @return			SObject record with fields stripped
   */
  private SObject guardAgainstRemovedFields(
    System.AccessType accessType,
    SObject record
  ) {
    return guardAgainstRemovedFields(accessType, new List<SObject>{ record })
      ?.get(0);
  }
  /**
   * @description		Strips inaccessible fields or throws an exception if throwIfRemovedFields flag is true
   * @param			    accessType - System.AccessType to use in security decision
   * @param             records - SObject[] records whose fields should be guarded
   * @return			SObject records with fields stripped
   */
  private SObject[] guardAgainstRemovedFields(
    System.AccessType accessType,
    SObject[] records
  ) {
    if (accessLevel == System.AccessLevel.SYSTEM_MODE || records.isEmpty()) {
      return records;
    }

    SObjectAccessDecision securityDecision = Security.stripInaccessible(
      accessType,
      records,
      true
    );
    Map<String, Set<String>> removedFieldsMap = securityDecision.getRemovedFields();
    Set<String> removedCriticalFields = getRemovedFieldSet(removedFieldsMap);
    if (!removedCriticalFields.isEmpty()) {
      throw new RemovedFieldsException(
        'User lacks access to the following critical fields: ' +
        removedCriticalFields
      );
    }

    return securityDecision.getRecords();
  }
  /**
   * @description		Returns a set of fully qualified API names of removed fields
   * @param			    removedFieldsMap - result of securityDecision.getRemovedFields()
   * @return			Set of fully qualified API names of removed fields
   */
  private Set<String> getRemovedFieldSet(
    Map<String, Set<String>> removedFieldsMap
  ) {
    Set<String> removedFieldSet = new Set<String>();
    for (String objectApiName : removedFieldsMap.keySet()) {
      for (String fieldApiName : removedFieldsMap.get(objectApiName)) {
        if (
          allFieldsRequired ||
          requiredFieldsMap.get(objectApiName)?.contains(fieldApiName) == true
        ) {
          removedFieldSet.add(objectApiName + '.' + fieldApiName);
        }
      }
    }
    return removedFieldSet;
  }
}
