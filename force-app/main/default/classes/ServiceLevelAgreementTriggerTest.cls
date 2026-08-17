@isTest
public class ServiceLevelAgreementTriggerTest {
    @TestSetup
    static void setUpDate(){
        // Create test Case
        Case newCase = new Case(Subject = 'Test Case 1',
                               Status = 'New', 
                               Case_Description__c = 'Test Description');
        insert newCase;

        // Create test SLA's
        Service_Level_Agreement__c sla = new Service_Level_Agreement__c(Case_Status__c = 'New',
                                                                        Start_Time__c = system.now().addHours(-2),
                                                                        Case_Id__c = newCase.Id,
                                                                        IsCurrent__c = true);
        Service_Level_Agreement__c sla2 = new Service_Level_Agreement__c(Case_Status__c = 'Open',
                                                                        Case_Id__c = newCase.Id,
                                                                        IsCurrent__c = true);                                                                
        insert sla;
        insert sla2; 
    }

    @isTest
    static void testTotalTime() {
        //Retrieve sla
        Service_Level_Agreement__c sla = [SELECT Id, End_Time__c FROM Service_Level_Agreement__c WHERE Case_Status__c = 'New'];
                                                                       
        //Update sla to verify total time is calculated.
        sla.End_Time__c = System.now();
        test.startTest();
        update sla;
        test.stopTest();

        // Verify total time hours
        List<Service_Level_Agreement__c> slaList = [SELECT Id, Total_time_hours__c FROM Service_Level_Agreement__c WHERE Id =: sla.Id];
        System.assertEquals(true, slaList[0].Total_time_hours__c != Null, 'End time is missing');

    }

    @isTest
    static void testElapsedTime(){
        //Retrieve sla
        Service_Level_Agreement__c sla = [SELECT Id, Last_trigger_to_calculate_elapsed_time__c FROM Service_Level_Agreement__c WHERE Case_Status__c = 'New'];
                                                                       
        //Update sla to verify Elapsed time is calculated.
        sla.Last_trigger_to_calculate_elapsed_time__c = System.now();
        test.startTest();
        update sla;
        test.stopTest();

        // Verify Elapsed time hours
        List<Service_Level_Agreement__c> slaList = [SELECT Id, Elapsed_time_hours__c FROM Service_Level_Agreement__c WHERE Id =: sla.Id];
        System.assertEquals(true, slaList[0].Elapsed_time_hours__c != Null, 'Elapsed time is missing');
    }

    @isTest
    static void testMissingStartTime(){
        //Retrieve sla2
        Service_Level_Agreement__c sla2 = [SELECT Id, Last_trigger_to_calculate_elapsed_time__c FROM Service_Level_Agreement__c WHERE Case_Status__c = 'Open'];
                                                                       
        //Update sla
        sla2.Last_trigger_to_calculate_elapsed_time__c = System.now();
        test.startTest();
        update sla2;
        test.stopTest();
    }

}