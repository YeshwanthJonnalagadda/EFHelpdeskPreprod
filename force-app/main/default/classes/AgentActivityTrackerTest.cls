@isTest
public class AgentActivityTrackerTest {
    @isTest
    public static void updateActivityDateTest() {

        Id itProfileId = [SELECT Id FROM Profile WHERE Name = 'IT Agent' Limit 1].Id;
        Id systemAdminProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' Limit 1].Id;

        User agentUser = new User(
            LastName = 'agent',
            Alias = 'ageUser',
            ProfileId = itProfileId,
            Email = 'agent.User@ef.com',
            Username = 'agent.User@helpdesk.ef.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles'
        );
        insert agentUser;

        User systemAdminUser = new User(
            LastName = 'admin',
            Alias = 'admUser',
            ProfileId = systemAdminProfileId,
            Email = 'Admin.User@ef.com',
            Username = 'Admin.User@helpdesk.ef.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles'
        );
        insert systemAdminUser;

        Id itRecordTypeId = [SELECT Id FROM RecordType WHERE developername = 'EF_Helpdesk_IT' Limit 1].Id;

        Case tCase1 = new Case();
        tCase1.Origin = 'Bot';
        tCase1.Status = 'New';
        tCase1.Priority = 'Medium';
        tCase1.RecordTypeId = itRecordTypeId;
        tCase1.OwnerId = agentUser.Id;
        insert tCase1;

        EmailMessage eMessage = new EmailMessage();
        eMessage.RelatedToId = tCase1.Id;
        eMessage.Subject = 'test';
        eMessage.TextBody = 'test';
        eMessage.ToAddress = 'test.example@ef.com';
        eMessage.FromAddress = 'noreply@ef.com';
        eMessage.Status = '3';

        FeedItem feedItem1 = new FeedItem();
        feedItem1.ParentId = tCase1.Id;
        feedItem1.Body = 'test';


        System.runAs(agentUser){
            test.startTest();
            insert eMessage;
            insert feedItem1;

            tCase1.Priority = 'Low';
            update tCase1;
            test.stopTest();
        }

        Case updatedCase = [SELECT Id, Last_activity_by__c, Last_activity_date__c FROM Case WHERE Id=:tCase1.Id];
        System.assertEquals(agentUser.Id, updatedCase.Last_activity_by__c, 'Last activity by is not updated');

        System.runAs(systemAdminUser){
            updatedCase.Priority = 'Medium';
            update updatedCase;
        }
        
    }
}