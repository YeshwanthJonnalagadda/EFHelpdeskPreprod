@isTest
public class SendEmailToCCRecipientsTest {
    @TestSetup
    static void makeData(){
        //Get RecordType Id's
        Id helpdeskRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'EF_Helpdesk_IT' LIMIT 1].Id;
        Id amsRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'AMS_Ticket' LIMIT 1].Id;
        Id bpoRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'EF_BPO_Ticket' LIMIT 1].Id;

        //Create test data for case
        Case testCase1 = new Case(
            Subject = 'Test Case1',
            Description = 'Test Case1',
            Status = 'New',
            Origin = 'Form',
            Priority = 'Medium',
            SuppliedEmail = 'demo.test1@yahoo.com',
            CC__c = 'demo.test@yahoo.com',
            SuppliedName = 'Demo Test1',
            RecordTypeId = helpdeskRecordTypeId
        );
        insert testCase1;

        Case testCase2 = new Case(
            Subject = 'Test Case2',
            Description = 'Test Case2',
            Status = 'New',
            Origin = 'Form',
            Priority = 'Medium',
            SuppliedEmail = 'demo.test2@yahoo.com',
            CC__c = 'demo.test@yahoo.com',
            SuppliedName = 'Demo Test2',
            RecordTypeId = amsRecordTypeId
        );
        insert testCase2;

        Case testCase3 = new Case(
            Subject = 'Test Case3',
            Description = 'Test Case3',
            Status = 'New',
            Origin = 'Form',
            Priority = 'Medium',
            SuppliedEmail = 'demo.test3@yahoo.com',
            CC__c = 'demo.test@yahoo.com',
            SuppliedName = 'Demo Test3',
            RecordTypeId = bpoRecordTypeId
        );
        insert testCase3;

    }
    @isTest
    public static void sendEamilTest(){
        //get the inserted cases
        Case insertedCase1 = [SELECT Id FROM Case WHERE SuppliedEmail = 'demo.test1@yahoo.com'];
        Case insertedCase2 = [SELECT Id FROM Case WHERE SuppliedEmail = 'demo.test2@yahoo.com'];
        Case insertedCase3 = [SELECT Id FROM Case WHERE SuppliedEmail = 'demo.test3@yahoo.com']; 

        test.startTest();
        SendEmailToCCRecipients.sendEmail(new List<String>{insertedCase1.Id});
        SendEmailToCCRecipients.sendEmail(new List<String>{insertedCase2.Id});
        SendEmailToCCRecipients.sendEmail(new List<String>{insertedCase3.Id});
        integer invocations = Limits.getEmailInvocations();
        test.stopTest();

        //assertion
        System.Assert.areEqual(3, invocations, 'There should be 3 sendemail method invocations');
    }

}