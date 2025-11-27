@isTest
public class InvokeCaseAssignmentRulesTest {
    @isTest
    public static void invokeRuleTest(){
        
        //Fetch AMS Support Record Type
        RecordType amsSupport = [SELECT Id from RecordType where DeveloperName = 'AMS_Ticket' Limit 1];
        //Create test data
        Case newCase = new Case();
        newCase.RecordTypeId = amsSupport.Id;
        newCase.SuppliedEmail = 'test@example.com';
        newCase.Origin = 'Email';
        newCase.Priority = 'Low';
        newCase.Subject = 'test';
        newCase.Module__c = 'Access';
        newCase.Case_Description__c = 'test';
        
        insert newCase;
        
        //Fetch Inserted case
        List<Id> caseIds = new List<Id>();
        caseIds.add(newCase.Id);
        
        //Invoke the class
        test.startTest();
        InvokeCaseAssignmentRules.invokeRule(caseIds);
        test.stopTest();
        
        Case updatedCase = [Select Id,Owner_Full_Name__c from Case where Id=:newCase.Id];
        
        //Assert the Owner
        system.assertEquals('Oracle AMS', updatedCase.Owner_Full_Name__c);
        
    }

}