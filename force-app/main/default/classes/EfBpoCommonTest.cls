//EfBpoCommonTest - used to cover - EfBpoCaseAssignment, EfBpoReportUpdateBatch and EfBpoReportUpdateScheduler classes
@isTest
public class EfBpoCommonTest {

    @isTest
    static void testCaseAssignmentRules() {
        // Start test context
        Test.startTest();
        // Create a test case
        Case testCase = new Case(
            Subject = 'Test Case',
            Status = 'New',
            Origin = 'Email',
            Priority = 'Medium',
            SuppliedEmail = 'Demo.Test@yahoo.com'
        );
        insert testCase;
        // List to hold case IDs
        List<Id> caseIds = new List<Id>{testCase.Id};
        // Call the method to be tested
        EfBpoCaseAssignment.caseAssignmentRules(caseIds);
        // Query the case to verify assignment rules were applied
        Case updatedCase = [SELECT Id, OwnerId, CreatedById FROM Case WHERE Id = :testCase.Id];
        // Assertions to verify that the assignment rule was applied
        System.assertNotEquals(null, updatedCase.OwnerId, 'OwnerId should be set by assignment rules');
        System.assertNotEquals(testCase.CreatedById, updatedCase.OwnerId, 'OwnerId should be different from CreatedById');
        // End test context
        Test.stopTest();
    }

    @testSetup
    static void setup() {
        Case newCase = new Case();
        newCase.Subject = 'Demo Test';
        newCase.SuppliedEmail = 'Demo.Test@yahoo.com';
        insert newCase;
        // Create test TicketHistoryHandler__c records
        List<TicketHistoryHandler__c> histories = new List<TicketHistoryHandler__c>();
        for (Integer i = 0; i < 5; i++) {
            histories.add(new TicketHistoryHandler__c(
                Start_Date__c = System.now().addHours(-i),
                End_Date__c = null,  // End_Date should be null for the records to be processed in the batch
                Duration_Calculated_For_Status__c = 'Open',Ticket__c = newCase.Id
            ));
        }
        insert histories;
        
    }
    
    @isTest
    static void testWithExistingBusinessHours() { 
        Test.startTest(); 
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsActive = true LIMIT 1];
        System.debug('Using existing BusinessHours Id: ' + bh.Id); 
        // Ensure that BusinessHours.diff method is working in the test context
        Datetime testDatetime = System.now().addHours(1);
        Long diffMilliseconds = BusinessHours.diff(bh.Id, System.now(), testDatetime);
        System.debug('BusinessHours diff in milliseconds: ' + diffMilliseconds);
        Test.stopTest(); 
    }
    
    @isTest
    static void testScheduler() {
        // Schedule the job (run after 1 minute)
        String cronExpression = System.now().addMinutes(1).format('ss mm HH dd MM ? yyyy');
        String jobId = System.schedule('Test - EfBpoReportUpdateScheduler', cronExpression, new EfBpoReportUpdateScheduler(1));
        
        // Verify the job has been scheduled
        CronTrigger ct = [SELECT Id, CronJobDetail.Name, State FROM CronTrigger WHERE Id = :jobId LIMIT 1];
        System.assertEquals('WAITING', ct.State, 'The scheduled job should be in WAITING state');
        
        // Execute the scheduled job
        Test.startTest();
        Database.executeBatch(new EfBpoReportUpdateBatch(), 50);
        /* Verify that the batch was executed and records updated
        List<TicketHistoryHandler__c> updatedHistories = [SELECT Id, Duration_Milliseconds__c FROM TicketHistoryHandler__c WHERE Duration_Milliseconds__c != NULL];
        System.assert(updatedHistories.size() > 0, 'The Duration_Milliseconds__c field should be updated for the records');
        
        // Verify that the previous scheduled job was aborted (check state of old cron jobs)
        List<CronTrigger> cronJobs = [SELECT Id, State FROM CronTrigger WHERE  CronJobDetail.Name = 'EfBpoReportUpdateScheduler - Initial'];
        for (CronTrigger cronJob : cronJobs) {
            System.assertEquals('DELETED', cronJob.State, 'Previous scheduled jobs should have been deleted after the new one runs');
        }*/
        Test.stopTest();
    }
    
    @isTest
    static void testHandleAfterInsert() {
        // Start test context
        Test.startTest();
        RecordType recordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'EF_BPO_Ticket' AND SObjectType = 'Case' LIMIT 1];
        // Create test case
        Case testCase = new Case(
            Subject = 'Test Case',
            Status = 'New',
            Origin = 'SF',
            Priority = 'High',
            RecordTypeId = recordType.Id,
            SuppliedEmail = 'Demo.Test@yahoo.com'
        );
        insert testCase; 
        testCase.Status = 'In Progress';
        testCase.Priority = 'Urgent';
        update testCase;
        Test.stopTest();
    }
    
}