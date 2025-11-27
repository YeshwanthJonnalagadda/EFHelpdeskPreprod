@isTest
public class CloseRejectedTicketsBatchTest {
    @isTest
    public static void testBatchProcess(){
        // Set up test data for Cases
        // Create Contact record
        Contact testContact = new Contact(FirstName = 'Test', LastName = 'User', Email = 'testuser@example.com');
        insert testContact;

        //Query BPO case RecordTypeId
        Id BPOcaseRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'EF_BPO_Ticket' LIMIT 1].Id;

        //Query the Rejected BPO Queue;
        Group RejectedBPOQueue = [SELECT Id FROM Group WHERE DeveloperName = 'Rejected_BPO_Tickets' LIMIT 1];

        //Create case
        Case testCase1 = new Case();
        testCase1.Status = 'New';
        testCase1.Origin = 'Email';
        testCase1.ContactId = testContact.Id;
        testCase1.RecordTypeId = BPOcaseRecordTypeId;
        testCase1.OwnerId = RejectedBPOQueue.Id;

        insert testCase1;

        //Execute the batch class
        Test.startTest();
        CloseRejectedTicktesBatch batch = new CloseRejectedTicktesBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        //Retrieve the update case
        Case updatedCase = [SELECT Id, Status FROM Case WHERE Id =: testCase1.Id LIMIT 1];

        //Assert the case has been closed
        system.assertEquals('Closed', updatedCase.Status, 'Case is not closed');

        }
}