@IsTest
public class DatabaseService_TEST {
    @IsTest
    static void constructorChains() {
      Test.startTest();
      DatabaseService db = new DatabaseService();

      System.AssertEquals(
        System.AccessLevel.USER_MODE,
        db.accessLevel,
        'DatabaseService constructor set an unexpected value for "accessLevel"'
      );
      System.AssertEquals(
        false,
        db.throwIfRemovedFields,
        'DatabaseService constructor set an unexpected value for "throwIfRemovedfields"'
      );
      System.AssertEquals(
        true,
        db.dmlOptions.allowFieldTruncation,
        'DatabaseService constructor set an unexpected value for "dmlOptions.allowFieldTruncation"'
      );
      System.AssertEquals(
        true,
        db.dmlOptions.optAllOrNone,
        'DatabaseService constructor set an unexpected value for "dmlOptions.optAllOrNone"'
      );

      db.withAccessLevel(System.AccessLevel.SYSTEM_MODE);
      System.AssertEquals(
        System.AccessLevel.SYSTEM_MODE,
        db.accessLevel,
        'DatabaseService.withAccessLevel set an unexpected value'
      );

      db.allOrNone(false);
      System.AssertEquals(
        false,
        db.dmlOptions.optAllOrNone,
        'DatabaseService.withAccessLevel set an unexpected value'
      );

      db.throwIfRemovedFields(true);
      System.AssertEquals(
        true,
        db.allFieldsRequired,
        'DatabaseService.allFieldsRequired returned an unexpected value'
      );
      System.AssertEquals(
        true,
        db.throwIfRemovedFields,
        'DatabaseService.throwIfRemovedFields set an unexpected value'
      );
      db.throwIfRemovedFields(false);

      db.throwIfRemovedFields(
        'Account',
        new Set<String> {
            'AccountNumber',
            'AccountSource'
        }
      );
      System.AssertEquals(
        true,
        db.throwIfRemovedFields,
        'DatabaseService.throwIfRemovedFields set an unexpected value'
      );
      System.AssertEquals(
        true,
        db.requiredFieldsMap.containsKey('Account'),
        'DatabaseService.throwIfRemovedFields set an unexpected value'
      );
      System.AssertEquals(
        2,
        db.requiredFieldsMap.get('Account').size(),
        'DatabaseService.throwIfRemovedFields set an unexpected value'
      );

      try {
        db.throwIfRemovedFields('Contact', new Set<String>());
        System.assert(false, 'DatabaseService.throwIfRemovedFields should throw an IllegalArgumentException if passed empty args');
      } catch (IllegalArgumentException e) {
        System.assert(true, 'DatabaseService.throwIfRemovedFields should throw an IllegalArgumentException if passed empty args');
      }

      Database.DmlOptions opts = new Database.DmlOptions();
      opts.AllowFieldTruncation = false;
      db.withOptions(opts);
      System.AssertEquals(
        false,
        db.dmlOptions.AllowFieldTruncation,
        'DatabaseService.withOptions set an unexpected value'
      );
    }

  /**
   * @description Creates a User and assigns the 'Minimum Access - Salesforce' profile
   * @param   doInsert    Boolean flag. Inserts User if true, otherwise just returns
   * @return  `User`
   */
  public static User createMinAccessUser(Boolean doInsert) {
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
  public static User createTestUser(Id profileId, boolean doInsert) {
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
  public static void assignPermSetToUser(User usr, Id permSetId) {
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
  public static PermissionSet createPermSet(String permSetApiName) {
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
   * @param   crudTypes     List of CanTheUser.CrudType representing CRUD permissions to assign
   * @return  `ObjectPermissions`
   */
  public static ObjectPermissions createObjectPerm(
    Id permSetId,
    String sObjectType
  ) {
    ObjectPermissions op = new ObjectPermissions(
      ParentId = permSetId,
      SobjectType = sObjectType
    );
    op.PermissionsCreate = true;
    op.PermissionsRead = true;
    insert op;
    return op;
  }
}
