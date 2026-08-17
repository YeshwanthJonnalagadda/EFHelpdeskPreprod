@isTest
public class ServiceLevelAgreementTriggerDispatchTest {

    @testSetup
    static void dataSetup(){
        // Create test Case
        Case newCase = new Case(Subject = 'Test Case 1',
                               Status = 'New', 
                               Case_Description__c = 'Test Description');
        insert newCase;

        //create test sla
        Service_Level_Agreement__c sla = new Service_Level_Agreement__c(Case_Status__c = 'New',
                                                                        Start_Time__c = system.now(),
                                                                        Case_Id__c = newCase.Id,
                                                                        IsCurrent__c = true);

        insert sla;
    }

    @isTest
    static void dispatchTest(){
        string testCron = '0 0 0 1 * ?';
        test.startTest();
        ServiceLevelAgreementTriggerDispatch newdispatch = new ServiceLevelAgreementTriggerDispatch();
        system.schedule('ScheduledApexTest', testCron, newdispatch);
        test.stopTest();
    }

    @isTest
    static void batchTest(){
        //retrieve sla
        Service_Level_Agreement__c sla = [SELECT Id FROM Service_Level_Agreement__c];
        test.startTest();
        ServiceLevelAgreementTriggerDispatch newBatch = new ServiceLevelAgreementTriggerDispatch();
        Database.executeBatch(newBatch, 200);
        test.stopTest();
    }
}