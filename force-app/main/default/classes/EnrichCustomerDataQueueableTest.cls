@isTest
public class EnrichCustomerDataQueueableTest {

    @TestSetup
    static void makeData(){
        //Create test data for case, contact and account
        Case testCase = new Case(
            Subject = 'Test Case',
            Status = 'New',
            Origin = 'Email',
            Priority = 'Medium',
            SuppliedEmail = 'demo.test@yahoo.com',
            SuppliedName = 'Demo Test'
        );
        insert testCase;

        Account acc = new Account(Name = 'EF Education First');
        insert acc;

        Contact testContact = new Contact(LastName = 'Demo Test', UUID__c = 'wprocndsdjiuwqyriubcasd', accountId = acc.Id);
        insert testContact;
    }
    @isTest
    public static void enrichCustomerDataQueueableTest(){
        //get the inserted case and contact
        Contact insertedTestContact = [SELECT Id FROM Contact WHERE UUID__c = 'wprocndsdjiuwqyriubcasd' LIMIT 1];
        Case insertedTestCase = [SELECT Id, ContactId FROM Case WHERE SuppliedEmail = 'demo.test@yahoo.com' LIMIT 1];

        String caseIdToContactId = insertedTestCase.Id + '-' + insertedTestContact.Id;

        //invoke EnrichCustomerDataQueueable
        test.startTest();
        EnrichCustomerDataQueueable.invokeQueueable(new List<String>{caseIdToContactId});
        EnrichCustomerDataQueueable newJob = new EnrichCustomerDataQueueable(new List<String>{caseIdToContactId});
        system.enqueueJob(newJob);
        test.stopTest();

        Case updatedTestCase = [SELECT Id, ContactId FROM Case WHERE SuppliedEmail = 'demo.test@yahoo.com' LIMIT 1];

        //Assertion
        system.assert.areNotEqual(Null, updatedTestCase.ContactId, 'ContactId on case is missing');
        system.assertEquals(insertedTestContact.Id, updatedTestCase.ContactId, 'ContactId on case does not match or case not updated');
    }
}