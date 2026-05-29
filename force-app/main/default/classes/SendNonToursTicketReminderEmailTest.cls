@isTest
public class SendNonToursTicketReminderEmailTest {
    @TestSetup
    static void makeData(){
        Id bpoRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'EF_BPO_Ticket' LIMIT 1].Id;
        //Create Contact
        Contact c1 = new contact(LastName = 'test1', Email='demo.test1@yahoo.com');
        insert c1;

        //Create test data for case
        Case testCase1 = new Case(
            Subject = 'Test Case1',
            Description = 'Test Case1',
            Status = 'Pending',
            Origin = 'Form',
            EF_BPO_Product__c = 'Central Finance',
            EF_BPO_Business_Unit__c = 'CH007',
            SuppliedEmail = 'demo.test1@yahoo.com',
            ContactId = c1.Id,
            RecordTypeId = bpoRecordTypeId,
            EF_BPO_Reminder_Number__c = 3,
            EF_BPO_Reminder_Date__c = Datetime.now().addHours(-1),
            EF_BPO_Business_Segment__c = 'Supplier Related',
            EF_BPO_Request_Type__c = 'Supplier Invoice Request/Query',
            EF_BPO_Request_Details__c = 'Missing PO'
        );
        insert testCase1;

        //Create BU Mapping Record
        EF_BPO_BU_Product_Mapping__c buMapping = new EF_BPO_BU_Product_Mapping__c();
        buMapping.Business_Unit__c = 'CH007';
        buMapping.Finance_Manager_Email__c = 'demo.test2@gmail.com';
        insert buMapping;

        //Create emailMessages
        EmailMessage emailMsg1 = new EmailMessage();
         emailMsg1.ParentId = testCase1.Id;
         emailMsg1.TextBody = 'Hello, \n\n'+'This is a test1 email.\n\n'+'Thanks,\n\n'+'GEC Support Team';
         emailMsg1.ToAddress = 'demo.test1@yahoo.com';
         emailMsg1.Subject = 'Test Email 1';
         insert emailMsg1;

        EmailMessage emailMsg2 = new EmailMessage();
         emailMsg2.ParentId = testCase1.Id;
         emailMsg2.TextBody = 'Hello, \n\n'+'This is a test2 email.\n\n'+'Thanks,\n\n'+'GEC Support Team';
         emailMsg2.ToAddress = 'demo.test1@yahoo.com';
         emailMsg2.Subject = 'Test Email 2';
         insert emailMsg2;
    }

    @isTest
    static void sendReminderTest(){
        Id insertedCaseId = [SELECT Id FROM Case WHERE SuppliedEmail = 'demo.test1@yahoo.com'].Id;

        test.startTest();
        SendNonToursTicketReminderEmail batch = new SendNonToursTicketReminderEmail();
        Database.executeBatch(batch, 2);
        test.stopTest();

        EmailMessage em1 = [SELECT Id, CreatedDate, subject FROM EmailMessage WHERE Subject = 'Test Email 1'];
        Test.setCreatedDate(em1.Id, Datetime.now().addHours(-2));
        update em1;
        
        List<EmailMessage> insertedEmailMessages = [SELECT Id, ParentId, Subject, createdDate FROM EmailMessage WHERE ParentId =: insertedCaseId];
        SendNonToursTicketReminderEmail.EmailMessageCreatedDateComparator emComparator = new SendNonToursTicketReminderEmail.EmailMessageCreatedDateComparator();
        insertedEmailMessages.sort(emComparator);
        
        EmailMessage em2 = [SELECT Id, CreatedDate, subject FROM EmailMessage WHERE Subject = 'Test Email 2'];
        Test.setCreatedDate(em2.Id, Datetime.now().addHours(-4));
        update em2;

        List<EmailMessage> updatedEmailMessages = [SELECT Id, ParentId, Subject, createdDate FROM EmailMessage WHERE ParentId =: insertedCaseId];
        SendNonToursTicketReminderEmail.EmailMessageCreatedDateComparator emc = new SendNonToursTicketReminderEmail.EmailMessageCreatedDateComparator();
        updatedEmailMessages.sort(emc);
        
        //Assertion to check reminder date and reminder number are update on case
        Case updatedCase = [SELECT Id, EF_BPO_Reminder_Date__c, EF_BPO_Reminder_Number__c, EF_BPO_Reminders_Complete__c FROM Case Where Id =: insertedCaseId];
        system.assertEquals(Null, updatedCase.EF_BPO_Reminder_Number__c, 'Reminder number should be Null');
        System.assertEquals(true, updatedCase.EF_BPO_Reminders_Complete__c, 'EF_BPO_Reminders_Complete__c should be true');
    }
}