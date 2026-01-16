@isTest
public class CommonCaseTriggerHelperTest {
    @isTest
    public static void calculateNextActionDateTest(){
        //Create test data
        Contact testContact = new Contact(FirstName='Test', LastName='1');
        insert testContact;
        Group g = [SELECT Id FROM Group WHERE Name = 'WW Information Security' AND type = 'Queue' LIMIT 1];
        BusinessHours zurichBusinessHours = [SELECT Id FROM BusinessHours WHERE Name = 'Zurich Business Hours' LIMIT 1];

        Case testCase = new case(Status='New', Origin='Email', ContactId=testContact.Id, OwnerId=g.Id);
        insert testCase;

        Case insertedTestCase = [SELECT Id, Status, Next_Action__c, Next_Action_DateTime__c FROM Case WHERE Id =: testCase.Id LIMIT 1];
        //assertion to check the next action date is null
        system.assertEquals(Null, insertedTestCase.Next_Action__c, 'Next action field is not blank');

        test.startTest();
        insertedTestCase.Status = 'Pending';
        update insertedTestCase;
        //query the updated case to check the next action.
        Case updatedTestCase = [SELECT Id, Next_Action__c, Next_Action_DateTime__c FROM Case WHERE Id=:testCase.Id LIMIT 1];
        system.assertEquals('Send Pending Chaser', updatedTestCase.Next_Action__c, 'Next action does not match the actual value');

        //Update the case next action to Status to resolved
        updatedTestCase.Next_Action__c = 'Status To Resolved';
        update updatedTestCase;
        //query the second time updated case
        Case update2TestCase = [Select Id, Status, Next_Action_DateTime__c from Case where Id=:testCase.Id limit 1];
        System.assertEquals(BusinessHours.add(zurichBusinessHours.Id, Datetime.now(), 1*24*60*60*1000), update2TestCase.Next_Action_DateTime__c, 'Next action date time does not match the actual value');

        //Update the case status to Resolved
        update2TestCase.Status = 'Resolved';
        update update2TestCase;
        //query the third time updated case
        Case update3TestCase = [Select Id, Next_Action_DateTime__c from Case where Id=:testCase.Id limit 1];
        System.assertEquals(BusinessHours.add(zurichBusinessHours.Id, Datetime.now(), 5*24*60*60*1000), update3TestCase.Next_Action_DateTime__c, 'Next action date time does not match the actual value');
        test.stopTest();
    }

    @IsTest
    static void testInsertTicketCreatesPrimaryAndSecondaryRoles() {

        // Arrange
        Case c = new Case(
            Subject = 'Test Ticket Insert',
            Status = 'New',
            Origin = 'Email',
            SuppliedEmail = 'primary@test.com',
            CC__c = 'cc1@test.com, cc2@test.com ,cc3@test.com'
        );

        // Act
        Test.startTest();
        insert c;
        Test.stopTest();

        // Assert
        List<Ticket_Contact_Role__c> roles = [
            SELECT Name, Email__c, Relationship_Type__c, Ticket__c
            FROM Ticket_Contact_Role__c
            WHERE Ticket__c = :c.Id
        ];

        System.assertEquals(4, roles.size(), 'Expected 1 Primary + 3 Secondary roles');

        Integer primaryCount = 0;
        Integer secondaryCount = 0;

        for (Ticket_Contact_Role__c r : roles) {
            if (r.Relationship_Type__c == 'Primary') {
                primaryCount++;
                System.assertEquals('primary@test.com', r.Email__c);
            }
            if (r.Relationship_Type__c == 'Secondary') {
                secondaryCount++;
            }
        }

        System.assertEquals(1, primaryCount, 'Exactly one Primary role expected');
        System.assertEquals(3, secondaryCount, 'Three Secondary roles expected');
    }

    @IsTest
    static void testUpdateSuppliedEmailCreatesNewPrimaryRole() {

        // Arrange
        Case c = new Case(
            Subject = 'Test Ticket Update SuppliedEmail',
            Status = 'New',
            Origin = 'Email',
            SuppliedEmail = 'old@test.com'
        );
        insert c;

        // Act
        Test.startTest();
        c.SuppliedEmail = 'new@test.com';
        update c;
        Test.stopTest();

        // Assert
        List<Ticket_Contact_Role__c> roles = [
            SELECT Email__c, Relationship_Type__c
            FROM Ticket_Contact_Role__c
            WHERE Ticket__c = :c.Id
        ];

        Boolean foundNewPrimary = false;

        for (Ticket_Contact_Role__c r : roles) {
            if (r.Relationship_Type__c == 'Primary' &&
                r.Email__c == 'new@test.com') {
                foundNewPrimary = true;
            }
        }

        System.assert(foundNewPrimary, 'New Primary role should be created');
    }

    @IsTest
    static void testUpdateCCCreatesSecondaryRoles() {

        // Arrange
        Case c = new Case(
            Subject = 'Test Ticket Update CC',
            Status = 'New',
            Origin = 'Email',
            SuppliedEmail = 'primary@test.com',
            CC__c = 'cc4@test.com'
        );
        insert c;

        // Act
        Test.startTest();
        c.CC__c = 'cc5@test.com, cc6@test.com';
        update c;
        Test.stopTest();

        // Assert
        List<Ticket_Contact_Role__c> roles = [
            SELECT Email__c, Relationship_Type__c
            FROM Ticket_Contact_Role__c
            WHERE Ticket__c = :c.Id
        ];

        Integer secondaryCount = 0;

        for (Ticket_Contact_Role__c r : roles) {
            if (r.Relationship_Type__c == 'Secondary') {
                secondaryCount++;
            }
        }

        System.assertEquals(2, secondaryCount, 'Two Secondary roles should be created');
    }

    @IsTest
    static void testNullValuesDoNotCreateRoles() {

        // Arrange
        Case c = new Case(
            Subject = 'Test Ticket Null Emails',
            Status = 'New',
            Origin = 'Email'
        );

        // Act
        Test.startTest();
        insert c;
        Test.stopTest();

        // Assert
        Integer countCCR = [
            SELECT COUNT()
            FROM Ticket_Contact_Role__c
            WHERE Ticket__c = :c.Id
        ];

        System.assertEquals(0, countCCR, 'No CCR records should be created');
    }
}