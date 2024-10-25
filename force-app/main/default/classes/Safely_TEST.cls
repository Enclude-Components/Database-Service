@IsTest
@SuppressWarnings(
  'PMD.MethodNamingConventions,PMD.ExcessiveParameterList,PMD.CyclomaticComplexity'
)
public class Safely_TEST {
  @IsTest
  static void constructorChains() {
    Test.startTest();
    Safely db = new Safely();

    System.AssertEquals(
      System.AccessLevel.USER_MODE,
      db.accessLevel,
      'Safely constructor set an unexpected value for "accessLevel"'
    );
    System.AssertEquals(
      false,
      db.throwIfRemovedFields,
      'Safely constructor set an unexpected value for "throwIfRemovedfields"'
    );
    System.AssertEquals(
      true,
      db.dmlOptions.allowFieldTruncation,
      'Safely constructor set an unexpected value for "dmlOptions.allowFieldTruncation"'
    );
    System.AssertEquals(
      true,
      db.dmlOptions.optAllOrNone,
      'Safely constructor set an unexpected value for "dmlOptions.optAllOrNone"'
    );

    db.withAccessLevel(System.AccessLevel.SYSTEM_MODE);
    System.AssertEquals(
      System.AccessLevel.SYSTEM_MODE,
      db.accessLevel,
      'Safely.withAccessLevel set an unexpected value'
    );

    db.allOrNone(false);
    System.AssertEquals(
      false,
      db.dmlOptions.optAllOrNone,
      'Safely.withAccessLevel set an unexpected value'
    );

    db.allOrNothing();
    System.AssertEquals(
      true,
      db.dmlOptions.optAllOrNone,
      'Safely.withAccessLevel set an unexpected value'
    );

    db.throwIfRemovedFields();
    System.AssertEquals(
      true,
      db.allFieldsRequired,
      'Safely.allFieldsRequired returned an unexpected value'
    );
    System.AssertEquals(
      true,
      db.throwIfRemovedFields,
      'Safely.throwIfRemovedFields set an unexpected value'
    );
    db.throwIfRemovedFields(false);

    db.throwIfRemovedFields(
      'Account',
      new Set<String>{ 'AccountNumber', 'AccountSource' }
    );
    System.AssertEquals(
      true,
      db.throwIfRemovedFields,
      'Safely.throwIfRemovedFields set an unexpected value'
    );
    System.AssertEquals(
      true,
      db.requiredFieldsMap.containsKey('Account'),
      'Safely.throwIfRemovedFields set an unexpected value'
    );
    System.AssertEquals(
      2,
      db.requiredFieldsMap.get('Account').size(),
      'Safely.throwIfRemovedFields set an unexpected value'
    );

    try {
      db.throwIfRemovedFields('Contact', new Set<String>());
      System.assert(
        false,
        'Safely.throwIfRemovedFields should throw an IllegalArgumentException if passed empty args'
      );
    } catch (IllegalArgumentException e) {
      System.assert(
        true,
        'Safely.throwIfRemovedFields should throw an IllegalArgumentException if passed empty args'
      );
    }

    Database.DmlOptions opts = new Database.DmlOptions();
    opts.AllowFieldTruncation = false;
    db.withOptions(opts);
    System.AssertEquals(
      false,
      db.dmlOptions.AllowFieldTruncation,
      'Safely.withOptions set an unexpected value'
    );
  }

  @IsTest
  static void doQuery_SystemMode() {
    User minAccessUser = createMinAccessUser(true);

    Test.startTest();
    Account testAccount = createTestAccount(minAccessUser.Id);
    System.runAs(minAccessUser) {
      Safely db = new Safely()
        .withAccessLevel(System.AccessLevel.SYSTEM_MODE);

      SObject[] results = db.doQuery(getTestAccountQuery(testAccount.Id));

      System.assertEquals(1, results.size(), 'Should return one Account');
      Account queriedAccount = (Account) results[0];
      System.assertEquals(
        'Technology',
        queriedAccount.Industry,
        'Should have access to Industry in SYSTEM_MODE'
      );
    }
    Test.stopTest();
  }
  @IsTest
  static void doQuery_UserModeStrippedFields() {
    User minAccessUser = createMinAccessUser(true);
    PermissionSet ps = createPermSet('DB_Service_Test');
    createObjectPerm(ps.Id, 'Account', new Set<CrudType>{ CrudType.READ });
    assignPermSetToUser(minAccessUser, ps.Id);
    Account testAccount = createTestAccount(minAccessUser.Id);

    Test.startTest();
    System.runAs(minAccessUser) {
      Safely db = new Safely();

      SObject[] results = db.doQuery(getTestAccountQuery(testAccount.Id));

      System.assertEquals(1, results.size(), 'Should return one Account');
      Account queriedAccount = (Account) results[0];
      Map<String, Object> populatedFields = queriedAccount.getPopulatedFieldsAsMap();
      System.assert(
        !populatedFields.containsKey('Industry'),
        'Should not have access to Industry in USER_MODE'
      );
    }
    Test.stopTest();
  }

  @IsTest
  static void doQuery_UserModeThrowIfRemovedFields() {
    User minAccessUser = createMinAccessUser(true);
    PermissionSet ps = createPermSet('DB_Service_Test');
    createObjectPerm(ps.Id, 'Account', new Set<CrudType>{ CrudType.READ });
    assignPermSetToUser(minAccessUser, ps.Id);

    Test.startTest();
    Account testAccount = createTestAccount(minAccessUser.Id);
    System.runAs(minAccessUser) {
      Safely db = new Safely().throwIfRemovedFields();

      try {
        db.doQuery(getTestAccountQuery(testAccount.Id));
        System.assert(
          false,
          'Safely.doQuery should have thrown a RemovedFieldsException'
        );
      } catch (Safely.RemovedFieldsException e) {
        String errorMsg = e.getMessage();
        System.assert(
          errorMsg.contains('Account.Industry'),
          'Exception message should mention the specific field that was removed: ' +
          errorMsg
        );
      }
    }
    Test.stopTest();
  }
  @IsTest
  static void doQueryWithBinds() {
    Safely db = new Safely();
    Account testAccount = createTestAccount(UserInfo.getUserId());

    SObject[] results = db.doQueryWithBinds(
      'SELECT Id FROM Account WHERE Id = :accountId',
      new Map<String, Object>{ 'accountId' => testAccount.Id }
    );

    System.assertEquals(1, results.size(), 'Should return one Account');
  }

  @IsTest
  static void doInsert_SystemMode() {
    User minAccessUser = createMinAccessUser(true);

    Test.startTest();
    System.runAs(minAccessUser) {
      Safely db = new Safely()
        .withAccessLevel(System.AccessLevel.SYSTEM_MODE);

      Account acc = new Account(
        Name = 'Test Account',
        Industry = 'Technology',
        Rating = 'Hot'
      );

      Database.SaveResult result = db.doInsert(acc);

      System.assert(result.isSuccess(), 'Insert should succeed in SYSTEM_MODE');

      Account savedAcc = [
        SELECT Name, Industry, Rating
        FROM Account
        WHERE Id = :result.getId()
      ];
      System.assertEquals(
        'Technology',
        savedAcc.Industry,
        'Industry should be saved'
      );
      System.assertEquals('Hot', savedAcc.Rating, 'Rating should be saved');
    }
    Test.stopTest();
  }

  @IsTest
  static void doInsert_UserModeWithPermissions() {
    User minAccessUser = createMinAccessUser(true);
    PermissionSet ps = createPermSet('DB_Service_Test');
    createObjectPerm(
      ps.Id,
      'Account',
      new Set<CrudType>{ CrudType.READ, CrudType.CREATE }
    );
    createFieldPerms(
      ps.Id,
      'Account',
      new Set<String>{ 'Industry', 'Rating' },
      new Set<FieldPermType>{ FieldPermType.READ, FieldPermType.EDIT }
    );
    assignPermSetToUser(minAccessUser, ps.Id);

    Test.startTest();
    System.runAs(minAccessUser) {
      Safely db = new Safely();

      Account acc = new Account(
        Name = 'Test Account',
        Industry = 'Technology',
        Rating = 'Hot'
      );

      Database.SaveResult result = db.doInsert(acc);

      System.assert(
        result.isSuccess(),
        'Insert should succeed with proper permissions'
      );

      Account savedAcc = [
        SELECT Name, Industry, Rating
        FROM Account
        WHERE Id = :result.getId()
      ];
      System.assertEquals(
        'Technology',
        savedAcc.Industry,
        'Industry should be saved'
      );
      System.assertEquals('Hot', savedAcc.Rating, 'Rating should be saved');
    }
    Test.stopTest();
  }

  @IsTest
  static void doInsert_UserModeStrippedFields() {
    User minAccessUser = createMinAccessUser(true);
    PermissionSet ps = createPermSet('DB_Service_Test');
    createObjectPerm(
      ps.Id,
      'Account',
      new Set<CrudType>{ CrudType.READ, CrudType.CREATE }
    );

    createFieldPerms(
      ps.Id,
      'Account',
      new Set<String>{ 'Industry' },
      new Set<FieldPermType>{ FieldPermType.EDIT }
    );
    assignPermSetToUser(minAccessUser, ps.Id);

    Test.startTest();
    System.runAs(minAccessUser) {
      Safely db = new Safely();

      Account acc = new Account(
        Name = 'Test Account',
        Industry = 'Technology',
        Rating = 'Hot'
      );

      Database.SaveResult result = db.doInsert(acc);

      System.assert(
        result.isSuccess(),
        'Insert should succeed with stripped fields'
      );

      Account savedAcc = [SELECT Name, Industry, Rating FROM Account];
      System.assertEquals(
        'Technology',
        savedAcc.Industry,
        'Industry should be saved'
      );
      System.assertEquals(null, savedAcc.Rating, 'Rating should be stripped');
    }
    Test.stopTest();
  }

  @IsTest
  static void doInsert_UserModeThrowOnStrippedFields() {
    User minAccessUser = createMinAccessUser(true);
    PermissionSet ps = createPermSet('DB_Service_Test');
    createObjectPerm(
      ps.Id,
      'Account',
      new Set<CrudType>{ CrudType.READ, CrudType.CREATE }
    );
    createFieldPerms(
      ps.Id,
      'Account',
      new Set<String>{ 'Industry' },
      new Set<FieldPermType>{ FieldPermType.EDIT }
    );
    assignPermSetToUser(minAccessUser, ps.Id);

    Test.startTest();
    System.runAs(minAccessUser) {
      Safely db = new Safely()
        .throwIfRemovedFields('Account', new Set<String>{ 'Rating' });

      Account acc = new Account(
        Name = 'Test Account',
        Industry = 'Technology',
        Rating = 'Hot'
      );

      try {
        db.doInsert(acc);
        System.assert(false, 'Should have thrown RemovedFieldsException');
      } catch (Safely.RemovedFieldsException e) {
        String errorMsg = e.getMessage();
        System.assert(
          errorMsg.contains('Account.Rating'),
          'Exception should mention Rating field: ' + errorMsg
        );
      }
    }
    Test.stopTest();
  }

  @IsTest
  static void doInsert_UserModeThrowOnNoAccess() {
    User minAccessUser = createMinAccessUser(true);

    Test.startTest();
    System.runAs(minAccessUser) {
      Safely db = new Safely()
        .throwIfRemovedFields('Account', new Set<String>{ 'Rating' });

      Account acc = new Account(
        Name = 'Test Account',
        Industry = 'Technology',
        Rating = 'Hot'
      );

      try {
        db.doInsert(acc);
        System.assert(false, 'Should have thrown NoAccessException');
      } catch (NoAccessException e) {
        System.assertNotEquals(null, e, 'Should have thrown NoAccessException');
      }
    }
    Test.stopTest();
  }

  @IsTest
  static void doInsert_BulkInsert() {
    Safely db = new Safely();

    Account[] accounts = new List<Account>{
      new Account(Name = 'Test Account 1'),
      new Account(Name = 'Test Account 2')
    };

    Database.SaveResult[] results = db.doInsert(accounts);

    System.assertEquals(2, results.size(), 'Should return two save results');
    for (Database.SaveResult result : results) {
      System.assert(result.isSuccess(), 'Each insert should succeed');
    }
  }

  @IsTest
  static void doUpdate_SingleRecord() {
    Safely db = new Safely();

    Account testAccount = createTestAccount(UserInfo.getUserId());
    testAccount.Name = 'Updated Account';
    Database.SaveResult result = db.doUpdate(testAccount);

    System.assert(result.isSuccess(), 'Update should succeed');
    System.assertEquals(
      'Updated Account',
      [SELECT Name FROM Account WHERE Id = :testAccount.Id].Name,
      'Name should be updated'
    );
  }

  @IsTest
  static void doUpdate_BulkUpdate() {
    Safely db = new Safely();
    Account[] testAccounts = new List<Account>{
      createTestAccount(UserInfo.getUserId())
    };

    for (Account acc : testAccounts) {
      acc.Name += ' Updated';
    }

    Database.SaveResult[] results = db.doUpdate(testAccounts);

    System.assertEquals(1, results.size(), 'Should return one save result');
    for (Database.SaveResult result : results) {
      System.assert(result.isSuccess(), 'Each update should succeed');
    }
  }

  @IsTest
  static void doDelete_SingleRecord() {
    Safely db = new Safely();
    Account testAccount = createTestAccount(UserInfo.getUserId());

    Database.DeleteResult result = db.doDelete(testAccount);

    System.assert(result.isSuccess(), 'Delete should succeed');
    System.assertEquals(
      0,
      [SELECT COUNT() FROM Account WHERE Id = :testAccount.Id],
      'Account should be deleted'
    );
  }

  @IsTest
  static void doDelete_BulkDelete() {
    Safely db = new Safely();
    Account[] testAccounts = new List<Account>{
      createTestAccount(UserInfo.getUserId())
    };

    Database.DeleteResult[] results = db.doDelete(testAccounts);

    System.assertEquals(1, results.size(), 'Should return one delete result');
    for (Database.DeleteResult result : results) {
      System.assert(result.isSuccess(), 'Delete should succeed');
    }

    System.assertEquals(
      0,
      [SELECT COUNT() FROM Account],
      'All accounts should be deleted'
    );
  }

  @IsTest
  static void doUpsert_SingleRecordWithoutExternalId() {
    Safely db = new Safely()
      .withAccessLevel(System.AccessLevel.USER_MODE);

    Account testAccount = new Account(Name = 'Test Account');
    Database.UpsertResult result = db.doUpsert(testAccount);
    System.assert(result.isSuccess(), 'Upsert (insert) should succeed');
    System.assert(result.isCreated(), 'Record should be created');

    testAccount.Id = result.getId();
    testAccount.Name = 'Updated Account';
    result = db.doUpsert(testAccount);
    System.assert(result.isSuccess(), 'Upsert (update) should succeed');
    System.assert(!result.isCreated(), 'Record should not be created');
  }

  @IsTest
  static void doUpsert_SingleRecordWithExternalId() {
    Safely db = new Safely()
      .withAccessLevel(System.AccessLevel.USER_MODE);

    Account testAccount = new Account(Name = 'Test Account');
    Database.UpsertResult result = db.doUpsert(testAccount);
    System.assert(result.isSuccess(), 'Upsert (insert) should succeed');
    System.assert(result.isCreated(), 'Record should be created');

    testAccount.Id = result.getId();
    testAccount.Name = 'Updated Account';
    result = db.doUpsert(testAccount, Account.Id);
    System.assert(result.isSuccess(), 'Upsert (update) should succeed');
    System.assert(!result.isCreated(), 'Record should not be created');
  }

  @IsTest
  static void doUpsert_BulkWithoutExternalId() {
    Safely db = new Safely()
      .withAccessLevel(System.AccessLevel.USER_MODE);

    Account[] testAccounts = new List<Account>{
      new Account(Name = 'Test Account 1')
    };

    Database.UpsertResult[] results = db.doUpsert(testAccounts);
    System.assertEquals(1, results.size(), 'Should return one upsert result');
    System.assert(results[0].isSuccess(), 'Upsert should succeed');
  }

  @IsTest
  static void doUpsert_BulkWithExternalId() {
    Safely db = new Safely()
      .withAccessLevel(System.AccessLevel.USER_MODE);

    Account[] testAccounts = new List<Account>{
      new Account(Name = 'Test Account 1')
    };

    Database.UpsertResult[] results = db.doUpsert(testAccounts);
    System.assertEquals(1, results.size(), 'Should return one upsert result');
    System.assert(results[0].isSuccess(), 'Upsert should succeed');

    testAccounts[0].Id = results[0].getId();
    testAccounts[0].Name = 'Updated Account 1';

    results = db.doUpsert(testAccounts, Account.Id);
    System.assertEquals(1, results.size(), 'Should return one upsert result');
    System.assert(results[0].isSuccess(), 'Upsert should succeed');
  }

  /**
   * @description Creates a User and assigns the 'Minimum Access - Salesforce' profile
   * @param   doInsert    Boolean flag. Inserts User if true, otherwise just returns
   * @return  `User`
   */
  private static User createMinAccessUser(Boolean doInsert) {
    Id profileId = [
      SELECT Id
      FROM Profile
      WHERE Name = 'Minimum Access - Salesforce'
    ]
    .Id;
    return createTestUser(profileId, doInsert);
  }
  /**
   * @description Creates a User with the given profileId
   * @param   profileId   Id of the profile to assign to User
   * @param   doInsert    Boolean flag. Inserts User if true, otherwise just returns
   * @return  `User`
   */
  private static User createTestUser(Id profileId, boolean doInsert) {
    User u = new User(
      profileId = profileId,
      LastName = 'last',
      Email = 'Testuser@test.example.com',
      Username = 'Testuser@test.example.com' + Crypto.getRandomInteger(),
      CompanyName = 'TEST',
      Title = 'title',
      Alias = 'alias',
      TimeZoneSidKey = 'America/Los_Angeles',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US'
    );
    if (doInsert) {
      insert u;
    }
    return u;
  }
  /**
   * @description Assigns Permission Set to User
   * @param   usr         User to assign Permission set to
   * @param   permSetId   ID of Permission Set to assign
   */
  private static void assignPermSetToUser(User usr, Id permSetId) {
    PermissionSetAssignment psa = new PermissionSetAssignment(
      AssigneeId = usr.Id,
      PermissionSetId = permSetId
    );
    insert psa;
  }
  /**
   * @description Create Permission Set with given API name
   * @param   permSetApiName    Permission Set API Name
   * @return  `PermissionSet`
   */
  private static PermissionSet createPermSet(String permSetApiName) {
    PermissionSet ps = new PermissionSet(
      Label = permSetApiName,
      Name = permSetApiName
    );
    insert ps;
    return ps;
  }
  /**
   * @description Assigns given CRUD types to Permission Set for given SObject type
   * @param   permSetId     ID of Permission Set
   * @param   sObjectType   API Name of SObject type
   * @param   crudTypes     Set of CrudType representing CRUD permissions to assign
   * @return  `ObjectPermissions`
   */
  private static ObjectPermissions createObjectPerm(
    Id permSetId,
    String sObjectType,
    Set<CrudType> crudTypes
  ) {
    ObjectPermissions op = new ObjectPermissions(
      ParentId = permSetId,
      SobjectType = sObjectType
    );
    for (CrudType permission : crudTypes) {
      switch on permission {
        when CREATE {
          op.PermissionsCreate = true;
        }
        when READ {
          op.PermissionsRead = true;
        }
        when EDIT {
          op.PermissionsEdit = true;
        }
        when DESTROY {
          op.PermissionsDelete = true;
        }
        when VIEW_ALL {
          op.PermissionsViewAllRecords = true;
        }
        when MODIFY_ALL {
          op.PermissionsModifyAllRecords = true;
        }
      }
    }
    insert op;
    return op;
  }
  /**
   * @description Assigns field-level permissions to a Permission Set
   * @param   permSetId        ID of Permission Set
   * @param   sObjectType      API Name of SObject type
   * @param   fieldName        API Name of the field
   * @param   permTypes        Set of FieldPermType values representing permissions to assign
   * @return  `FieldPermissions`
   */
  private static FieldPermissions createFieldPerm(
    Id permSetId,
    String sObjectType,
    String fieldName,
    Set<FieldPermType> permTypes
  ) {
    FieldPermissions fp = new FieldPermissions(
      ParentId = permSetId,
      // The SObjectType field should be just the object name
      SobjectType = sObjectType,
      // The Field field needs to be in the format "ObjectName.FieldName"
      Field = sObjectType + '.' + fieldName
    );

    // Set requested permissions to true
    for (FieldPermType permission : permTypes) {
      switch on permission {
        when READ {
          fp.PermissionsRead = true;
        }
        when EDIT {
          fp.PermissionsEdit = true;
          // Edit permission requires read permission
          fp.PermissionsRead = true;
        }
      }
    }

    insert fp;
    return fp;
  }
  private static List<FieldPermissions> createFieldPerms(
    Id permSetId,
    String sObjectType,
    Set<String> fieldNames,
    Set<FieldPermType> permTypes
  ) {
    List<FieldPermissions> fieldPerms = new List<FieldPermissions>();

    for (String fieldName : fieldNames) {
      fieldPerms.add(
        createFieldPerm(permSetId, sObjectType, fieldName, permTypes)
      );
    }

    return fieldPerms;
  }
  private static String getTestAccountQuery(Id accountId) {
    return 'SELECT Id, Name, Industry, Rating, Type FROM Account WHERE Id = \'' +
      accountId +
      '\'';
  }
  private static Account createTestAccount(Id ownerId) {
    Account testAccount;
    System.runAs(new User(Id = UserInfo.getUserId())) {
      testAccount = new Account(
        OwnerId = ownerId,
        Name = 'Test Account',
        Industry = 'Technology',
        Rating = 'Hot',
        Type = 'Prospect'
      );
      insert testAccount;
    }
    return testAccount;
  }
  public enum CrudType {
    CREATE,
    READ,
    EDIT,
    DESTROY,
    VIEW_ALL,
    MODIFY_ALL
  }
  public enum FieldPermType {
    READ,
    EDIT
  }
}
