global class EfBpoReportUpdateBatch implements Database.Batchable<SObject> {
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Start_Date__c, Duration_Milliseconds__c, Duration_Calculated_For_Status__c
            FROM TicketHistoryHandler__c
            WHERE End_Date__c = NULL AND Duration_Calculated_For_Status__c != 'Closed' AND Duration_Calculated_For_Status__c != 'Merged'
        ]);
    }
    
    global void execute(Database.BatchableContext bc, List<TicketHistoryHandler__c> scope) {
        try {
            BusinessHours bh = [SELECT Id FROM BusinessHours WHERE Name = 'EF BPO Business Hours' LIMIT 1];   
            for (TicketHistoryHandler__c history : scope) {
                Long diffMilliseconds = BusinessHours.diff(bh.Id, history.Start_Date__c, System.now());
                history.Duration_Milliseconds__c = diffMilliseconds;
            }
            update scope;
        } catch (Exception e) {
            // Log the error
            System.debug('Error processing batch: ' + e.getMessage());
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        
    }
}