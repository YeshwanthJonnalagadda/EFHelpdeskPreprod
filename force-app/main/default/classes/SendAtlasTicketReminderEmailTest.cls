@isTest
public class SendAtlasTicketReminderEmailTest {
    @TestSetup
    static void makeData(){
        Id bpoRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'EF_BPO_Ticket' LIMIT 1].Id;
        //Create test data for case
        Case testCase1 = new Case(
            Subject = 'Test Case1',
            Description = 'Test Case1',
            Status = 'On Hold',
            Origin = 'Email',
            SuppliedEmail = 'demo.test1@yahoo.com',
            RecordTypeId = bpoRecordTypeId,
            EF_BPO_Reminder_Number__c = 1,
            EF_BPO_Reminder_Date__c = Datetime.now().addHours(-1),
            EF_BPO_Business_Segment__c = 'Supplier Related',
            EF_BPO_Request_Type__c = 'Supplier Invoice Request/Query',
            EF_BPO_Request_Details__c = 'Tours - Atlas invoice receipt'
        );
        insert testCase1;

        Case testCase2 = new Case(
            Subject = 'Test Case2',
            Description = 'Test Case2',
            Status = 'on Hold',
            Origin = 'Email',
            SuppliedEmail = 'demo.test1@ef.com',
            RecordTypeId = bpoRecordTypeId,
            EF_BPO_Reminder_Number__c = 1,
            EF_BPO_Reminder_Date__c = Datetime.now().addHours(-1),
            EF_BPO_Business_Segment__c = 'Supplier Related',
            EF_BPO_Request_Type__c = 'Supplier Invoice Request/Query',
            EF_BPO_Request_Details__c = 'Tours - Atlas invoice receipt'
        );
        insert testCase2;

        //Create emailMessages
        Datetime setCreatedDate = Datetime.now().addHours(-2);
        EmailMessage emailMsg1 = new EmailMessage();
         emailMsg1.ParentId = testCase1.Id;
         emailMsg1.TextBody = 'Hello, \n\n'+'This is a test1 email.\n\n'+'Thanks,\n\n'+'GEC Support Team';
         emailMsg1.ToAddress = 'demo.test1@yahoo.com;demo.test2@yahoo.com';
         emailMsg1.CcAddress = 'demo.test3@yahoo.com;demo.test4@yahoo.com';
         emailMsg1.Subject = 'Test Email 1';
         insert emailMsg1;
         Test.setCreatedDate(emailMsg1.Id, setCreatedDate);
         update emailMsg1;

        EmailMessage emailMsg2 = new EmailMessage();
         emailMsg2.ParentId = testCase1.Id;
         emailMsg2.TextBody = 'Hello, \n\n'+'This is a test2 email.\n\n'+'Thanks,\n\n'+'GEC Support Team';
         emailMsg2.ToAddress = 'demo.test1@yahoo.com;demo.test2@yahoo.com';
         emailMsg2.CcAddress = 'demo.test3@yahoo.com;demo.test4@yahoo.com';
         emailMsg2.Subject = 'Test Email 2';
         insert emailMsg2;
        //Create an email message for testCase2
         EmailMessage emailMsg3 = new EmailMessage();
         emailMsg3.ParentId = testCase2.Id;
         emailMsg3.TextBody = 'Hello, \n\n'+'This is a test1 email for test case 2.\n\n'+'Thanks,\n\n'+'GEC Support Team';
         emailMsg3.ToAddress = 'demo.test1@ef.com;demo.test2@ef.com';
         emailMsg3.CcAddress = 'demo.test3@ef.com;demo.test4@ef.com';
         emailMsg3.Subject = 'Test Email 1';
         insert emailMsg3;
    }

    @isTest
    static void sendReminderTest(){
        Id insertedCaseId = [SELECT Id FROM Case WHERE SuppliedEmail = 'demo.test1@yahoo.com'].Id;
        Id insertedCase2Id = [SELECT Id FROM Case WHERE SuppliedEmail = 'demo.test1@ef.com'].Id;
        List<EmailMessage> insertedEmailMessages = [SELECT Id, ParentId, Subject, createdDate FROM EmailMessage WHERE ParentId =: insertedCaseId];
        test.startTest();
        SendAtlasTicketReminderEmail batch = new SendAtlasTicketReminderEmail();
        Database.executeBatch(batch, 2);
        SendAtlasTicketReminderEmail.EmailMessageCreatedDateComparator emComparator = new SendAtlasTicketReminderEmail.EmailMessageCreatedDateComparator();
        insertedEmailMessages.sort(emComparator);
        test.stopTest();

        //Assertion to check sorted email messages list
        system.assertEquals('Test Email 1', insertedEmailMessages[0].Subject, 'subject of first email message should be Test Email 1');

        EmailMessage em2 = [SELECT Id, CreatedDate, subject FROM EmailMessage WHERE Subject = 'Test Email 2'];
        Test.setCreatedDate(em2.Id, Datetime.now().addHours(-4));
        update em2;

        List<EmailMessage> udpdatedEmailMessages = [SELECT Id, ParentId, Subject, createdDate FROM EmailMessage WHERE ParentId =: insertedCaseId];
        SendAtlasTicketReminderEmail.EmailMessageCreatedDateComparator emc = new SendAtlasTicketReminderEmail.EmailMessageCreatedDateComparator();
        udpdatedEmailMessages.sort(emc);

        System.assertEquals('Test Email 2', udpdatedEmailMessages[0].Subject, 'subject of first email message should be Test Email 2');

        //Assertion to check reminder date and reminder number are update on case
        Case updatedCase = [SELECT Id, EF_BPO_Reminder_Date__c, EF_BPO_Reminder_Number__c FROM Case Where Id =: insertedCaseId];
        system.assertEquals(2, updatedCase.EF_BPO_Reminder_Number__c, 'Reminder number should be incremeneted to 2');
        system.assertEquals(Datetime.now().date() + 7, updatedCase.EF_BPO_Reminder_Date__c.date(), 'Reminder date should be updated to today + 7 days');
    }
}