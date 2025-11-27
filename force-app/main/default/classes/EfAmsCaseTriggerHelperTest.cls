@isTest
public class EfAmsCaseTriggerHelperTest {
    
    @testSetup
    static void setup() {
         // Create a user to own the cases
        User testUser = new User(
            Alias = 'user20',
            Email = 'testuser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser2099@test.com'
        );
        insert testUser;
        
        // Create profiles
        Profile agentProfile = [SELECT Id FROM Profile WHERE Name = 'AMS Agent' LIMIT 1];
        //Profile endUserProfile = [SELECT Id FROM Profile WHERE Name = 'End User Profile' LIMIT 1];
        
        // Create test users
        User agentUser = new User(
            Alias = 'agent',
            Email = 'agent2099@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Agent',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = agentProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'agent2099@test.com'
        );
        insert agentUser;
        /*
        User endUser = new User(
            Alias = 'enduser',
            Email = 'enduser2099@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'EndUser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = endUserProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'enduser2099@test.com'
        );
        insert endUser;
        */
    }

    @isTest
    static void testHandleAfterInsert() {
        User testUser = [SELECT Id FROM User WHERE UserName = 'testuser2099@test.com' LIMIT 1];
        RecordType defaultRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'AMS_Ticket' AND SObjectType = 'Case' LIMIT 1];

        Case newCase = new Case(
            Subject = 'Test Case After Insert',
            Case_Description__c = 'Test Description',
            Status = 'New',
            Module__c = 'HCM: Recruiting Cloud',
            CC__c = 'test124@test.com, test234@test.com',
            SuppliedEmail = 'test124@test.com',
            OwnerId = testUser.Id,
            RecordTypeId = defaultRecordType.Id
        );
        insert newCase;

        Test.startTest();
        
        Case insertedCase = [SELECT Id, Status FROM Case WHERE Id = :newCase.Id];
        System.assertEquals('New', insertedCase.Status, 'Status should be New after insert.');

        List<Service_Level_Agreement__c> slaRecords = [SELECT Id, Case_Id__c, IsCurrent__c FROM Service_Level_Agreement__c WHERE Case_Id__c = :newCase.Id];
        System.assertEquals(1, slaRecords.size(), 'One SLA record should be created.');
        System.assertEquals(true, slaRecords[0].IsCurrent__c, 'SLA record should be current.');

        Test.stopTest();
    }
    
    
    @isTest
    static void testHandleAfterUpdate() {
        User testUser = [SELECT Id FROM User WHERE UserName = 'testuser2099@test.com' LIMIT 1];
        User agentUser = [SELECT Id FROM User WHERE UserName = 'agent2099@test.com' LIMIT 1];
        RecordType defaultRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'AMS_Ticket' AND SObjectType = 'Case' LIMIT 1];

        Case newCase = new Case(
            Subject = 'Test Case After Update',
            Status = 'New',
            Case_Description__c = 'Test Description',
            Module__c = 'HCM: Recruiting Cloud',
            CC__c = 'test124@test.com, test234@test.com',
            SuppliedEmail = 'test124@test.com',
            OwnerId = testUser.Id,
            RecordTypeId = defaultRecordType.Id
        );
        insert newCase;

        // Update the case to change status
        newCase.Status = 'In Progress';
        newCase.Agent__c = agentUser.Id;
        update newCase;

        Test.startTest();
        // Assertions to verify the expected behavior
        Case updatedCase = [SELECT Id, Status FROM Case WHERE Id = :newCase.Id];
        System.assertEquals('In Progress', updatedCase.Status, 'Status should be In Progress after update.');

        List<Service_Level_Agreement__c> slaRecords = [SELECT Id, Case_Id__c, IsCurrent__c FROM Service_Level_Agreement__c WHERE Case_Id__c = :newCase.Id];
        System.assertEquals(2, slaRecords.size(), 'Two SLA records should be present.');
        System.assertEquals(false, slaRecords[0].IsCurrent__c, 'First SLA record should not be current.');
        System.assertEquals(true, slaRecords[1].IsCurrent__c, 'Second SLA record should be current.');

        Test.stopTest();
    }

    @isTest
    static void testHandleAfterUpdateERType() {
        User testUser = [SELECT Id FROM User WHERE UserName = 'testuser2099@test.com' LIMIT 1];
        RecordType defaultRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Enhancement_Request' AND SObjectType = 'Case' LIMIT 1];

        Case newCase = new Case(
            Subject = 'Test Case After Phase Update',
            Status = 'New',
            Case_Description__c = 'Test Description',
            Module__c = 'HCM: Recruiting Cloud',
            CC__c = 'test124@test.com, test234@test.com',
            SuppliedEmail = 'test124@test.com',
            Phase__c = 'SIT',
            OwnerId = testUser.Id,
            RecordTypeId = defaultRecordType.Id
        );
        insert newCase;

        // Update the case to change status
        newCase.Phase__c = 'UAT';
        update newCase;

        Test.startTest();
        // Assertions to verify the expected behavior
        Case updatedCase = [SELECT Id, Phase__c FROM Case WHERE Id = :newCase.Id];
        System.assertEquals('UAT', updatedCase.Phase__c, 'Phase should be UAT after update.');

        List<Service_Level_Agreement__c> slaRecords = [SELECT Id, Case_Id__c, IsCurrent__c FROM Service_Level_Agreement__c WHERE Case_Id__c = :newCase.Id];
        System.assertEquals(1, slaRecords.size(), 'One SLA records should be present.');

        Test.stopTest();
    }


    
    @isTest
    static void testHandleBeforeUpdate() {
        User testUser = [SELECT Id FROM User WHERE UserName = 'testuser2099@test.com' LIMIT 1];
        RecordType defaultRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'AMS_Ticket' AND SObjectType = 'Case' LIMIT 1];
        Id erRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Enhancement_Request' AND SObjectType = 'Case' LIMIT 1].Id;

        Case newCase = new Case(
            Subject = 'Test Case Before Update',
            Status = 'New',
            Case_Description__c = 'Test Description',
            Module__c = 'HCM: Recruiting Cloud',
            SuppliedEmail = 'test124@test.com',
            OwnerId = testUser.Id,
            RecordTypeId = defaultRecordType.Id
        );
        insert newCase;

        // Update the case to change record type
        /*
        newCase.RecordTypeId = erRecordTypeId;

        Test.startTest();
        try {
            update newCase;
            System.assert(false, 'Expected an exception when changing record type to Enhancement Request.');
        } catch (DmlException e) {
            System.assertEquals(true, e.getMessage().contains('Agents are only allowed to change the record type between AMS Ticket and AMS Service Request.'));
        }
        Test.stopTest();
        */
    }
    /*
     @isTest
    static void testShareCaseWithCreator() {
        // Get test users
        User agentUser = [SELECT Id FROM User WHERE Email = 'agent2099@test.com' LIMIT 1];
        User endUser = [SELECT Id FROM User WHERE Email = 'enduser2099@test.com' LIMIT 1];
        
        // Create a test case owned by the End User
        Case testCase = new Case(
            Subject = 'Test Case',
            Status = 'New',
            Case_Description__c = 'Test Description',
            Module__c = 'HCM: Recruiting Cloud',
            OwnerId = endUser.Id
        );
        insert testCase;
        
        // Update the case owner to the Agent user to trigger sharing logic
        testCase.OwnerId = agentUser.Id;
        update testCase;
    }
        */
    
}