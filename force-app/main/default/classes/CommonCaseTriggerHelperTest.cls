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
}