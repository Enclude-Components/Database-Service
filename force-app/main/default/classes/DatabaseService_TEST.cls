@IsTest
public class DatabaseService_TEST {

    @IsTest
    static void doInsert_guardAgainstRemovedFields() {

        User minAccessUser = createMinAccessUser(true);
        PermissionSet ps = createPermSet('TestPermSet01');
        createObjectPerm(
          ps.Id,
          'Account'
        );
        assignPermSetToUser(minaccessUser, ps.Id);

        System.runAs(minAccessUser) {
            DatabaseService db = new DatabaseService();
            db.doInsert(
                new Account(Name = 'Test', NumberOfEmployees = 3, AccountSource = 'TradeShow')
            );
            // db.throwIfRemovedFields(true);
            SObject[] records = db.doQuery('SELECT Id, NumberOfEmployees FROM Account');
            System.debug('================================');
            System.debug(records);
            System.debug('================================');
            System.debug('================================');
        }

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