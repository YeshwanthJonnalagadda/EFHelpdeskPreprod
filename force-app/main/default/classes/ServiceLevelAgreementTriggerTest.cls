@isTest
public class ServiceLevelAgreementTriggerTest {
    
    @testSetup
    static void setupTestData() {
        // Create test Cases
        List<Case> cases = new List<Case>();
        for (Integer i = 0; i < 3; i++) {
            cases.add(new Case(Subject = 'Test Case ' + i,
                               Status = 'Open', 
                               Case_Description__c = 'Test Description',
                               Module__c = 'HCM: Recruiting Cloud'));
        }
        insert cases;
    }
    
    @isTest
    static void testRemoveCaseSLATimes() {
        // Retrieve the test Cases
        List<Case> cases = [SELECT Id FROM Case];
        
        // Simulate SLA records creation for removal test
        List<Service_Level_Agreement__c> slas = new List<Service_Level_Agreement__c>();
        for (Case c : cases) {
            // Insert SLAs with dummy times; actual TimeSpent__c will be calculated by the formula
            slas.add(new Service_Level_Agreement__c(Case_Id__c = c.Id, Case_Status__c = 'In Progress', 
                                                     Start_Time__c = System.now().addHours(-2), 
                                                     End_Time__c = System.now()));
            slas.add(new Service_Level_Agreement__c(Case_Id__c = c.Id, Case_Status__c = 'Open', 
                                                     Start_Time__c = System.now().addHours(-1), 
                                                     End_Time__c = System.now()));
        }
        insert slas;
        
        // Add debug statements to inspect the inserted SLAs
        for (Service_Level_Agreement__c sla : slas) {
            System.debug('Inserted SLA Record: ' + sla);
        }
        
        // Delete the SLA records to trigger the removal logic
        delete slas;
        
        // Verify updated SLA times after deletion
        List<Case> updatedCases = [SELECT Id, SLA_Resolution_Time__c, SLA_Response_Time__c FROM Case];
        for (Case c : updatedCases) {
            System.assertEquals(0, c.SLA_Resolution_Time__c, 'SLA_Resolution_Time__c should be 0 after SLA deletion.');
            System.assertEquals(0, c.SLA_Response_Time__c, 'SLA_Response_Time__c should be 0 after SLA deletion.');
        }
    }
}