# Database Service Class
A wrapper class for the system Database class which is secure by default. Also allows for database operations to be mocked in unit tests.

## Deploy

<a href="https://githubsfdeploy.herokuapp.com?owner=Enclude-Components&repo=Database-Service&ref=main">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>

## Usage

### Construction
```java
// Constructed with default parameters
DatabaseService db = new DatabaseService();
```

By default, constructing the class with no additional parameters will run SOQL and DML:
- In USER_MODE
- Silently stripping away inaccessible fields
- AllOrNone (bulk transactions will fail as a whole, if any of the transactions fail)

```java
// The various builder methods, invoke one or more to set the parameters
DatabaseService db = new DatabaseService()
    .allOrNone(false) // Allows bulk operation failures
    .throwIfRemovedFields(true) // Throws `DatabaseService.RemovedFieldsException` if any fields are stripped
    .throwIfRemovedFields( // Throws `DatabaseService.RemovedFieldsException` only if specified fields are stripped
        'Account',
        new Set<String>{ 'AccountNumber', 'AccountSource' }
    )
    .withAccessLevel(System.AccessLevel.SYSTEM_MODE) // Runs queries and DML in SYSTEM_MODE
```

### Queries
```java
DatabaseService db = new DatabaseService();
Account[] accounts = (Account[])db.doQuery('SELECT Id from Account');
Account[] accountsWithBinds = (Account[])db.doQueryWithBinds(
    'SELECT Id from Account WHERE Id = :myAccountId',
    new Map<String, Object> {
        'myAccountId' => '001AP00000U22m3YAB'
    }
);
```

### DML
```java
// Insert Methods
DatabaseService db = new DatabaseService();
Database.SaveResult singleResult = db.doInsert(new Account(Name = 'My Account'));
Database.SaveResult[] bulkResult = db.doInsert(
    new List<Account> {
        new Account(Name = 'My Bulk Account 1'),
        new Account(Name = 'My Bulk Account 2')
    }
);
```
```java
// Update Methods
DatabaseService db = new DatabaseService();
Database.SaveResult singleResult = db.doUpdate(myUpdatedRecord);
Database.SaveResult[] bulkResult = db.doUpdate(myUpdatedRecordList);
```
```java
// Delete Methods
DatabaseService db = new DatabaseService();
Database.DeleteResult singleResult = db.doDelete(myDeletedRecord);
Database.DeleteResult[] bulkResult = db.doDelete(myDeletedRecordList);
```
```java
// Upsert Methods
DatabaseService db = new DatabaseService();
Database.UpsertResult singleResult = db.doUpsert(myUpsertedRecord);
Database.UpsertResult[] bulkResult = db.doUpsert(myUpsertedRecordList);
Database.UpsertResult singleResult = db.doUpsert(
    myUpsertedRecordWithExternalId,
    My_Custom_Object__c.My_External_ID_Field__c
);
Database.UpsertResult[] bulkResult = db.doUpsert(
    myUpsertedRecordWithExternalIdList,
    My_Custom_Object__c.My_External_ID_Field__c
);
```