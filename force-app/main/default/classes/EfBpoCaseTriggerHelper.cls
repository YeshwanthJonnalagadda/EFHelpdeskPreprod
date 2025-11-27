public class EfBpoCaseTriggerHelper {
    public static void handleAfterInsert(List<Case> caseRecordList) {
        List<TicketHistoryHandler__c> historyRecords = new List<TicketHistoryHandler__c>(); 
        for(Case caseRecord : caseRecordList){
            // Handle new ticket history record 
            TicketHistoryHandler__c history = new TicketHistoryHandler__c();
            history.Ticket__c = caseRecord.Id;
            history.Start_Date__c = System.now(); 
            history.Duration_Calculated_For_Status__c = caseRecord.Status;
            history.Time_at_IBM__c = true;
            //Placeholder for initial status 
            historyRecords.add(history); 
        }
        if (!historyRecords.isEmpty()) { 
            insert historyRecords; 
            System.debug('History Record Inserted');
        } 
    }
    
    public static void handleAfterUpdate(List<Case> caseRecordList, Map<Id, Case> oldCaseMap) {
        List<TicketHistoryHandler__c> historyRecords = new List<TicketHistoryHandler__c>();
        List<String> timeAtIbmStatus = new List<String>{'New', 'In Progress', 'Approved', 'Reopened'};
        List<String> timeAtEfStatus = new List<String>{'Pending', 'In Approval'};
 		// Retrieve Business Hours record
        List<BusinessHours> bhList = [SELECT Id FROM BusinessHours WHERE Name = 'EF BPO Business Hours' LIMIT 1];
        if(!bhList.isEmpty()){
            BusinessHours bh = bhList[0];
            // Collect case IDs to query related TicketHistoryHandler__c records
            Set<Id> caseIds = new Set<Id>();
            for (Case caseRecord : caseRecordList) {
                caseIds.add(caseRecord.Id);
            }
            
            // Query all relevant TicketHistoryHandler__c records in one query
            Map<Id, TicketHistoryHandler__c> oldHistoryMap = new Map<Id, TicketHistoryHandler__c>();
            for (TicketHistoryHandler__c history : [
                SELECT Id, Start_Date__c, Duration_Calculated_For_Status__c, End_Date__c, Ticket__c 
                FROM TicketHistoryHandler__c 
                WHERE Ticket__c IN :caseIds AND End_Date__c = null
                ORDER BY CreatedDate DESC
            ]) {
                if (!oldHistoryMap.containsKey(history.Ticket__c)) {
                    oldHistoryMap.put(history.Ticket__c, history);
                }
            }
            
            // Process each case record
            for (Case caseRecord : caseRecordList) {
                Case oldCase = oldCaseMap.get(caseRecord.Id);
                if (caseRecord.Status != oldCase.Status) {
                    // Close the old status
                    TicketHistoryHandler__c oldHistory = oldHistoryMap.get(oldCase.Id);
                    if (oldHistory != null && oldHistory.Duration_Calculated_For_Status__c == oldCase.Status) {
                        oldHistory.End_Date__c = System.now();
                        Long durationMilli = calculateDurationStringExcludingWeekends(oldHistory.Start_Date__c, System.now(), bh);
                        System.debug('XX durationMilli: ' + durationMilli);
                        oldHistory.Duration_Milliseconds__c = durationMilli;
                        historyRecords.add(oldHistory);
                    }
                    
                    // Start a new status record
                    TicketHistoryHandler__c newHistory = new TicketHistoryHandler__c();
                    newHistory.Ticket__c = caseRecord.Id;
                    newHistory.Start_Date__c = System.now();
                    newHistory.Duration_Calculated_For_Status__c = caseRecord.Status;
                    if (timeAtIbmStatus.contains(caseRecord.Status)) {
                        newHistory.Time_at_IBM__c = true;
                    }
                    if (timeAtEfStatus.contains(caseRecord.Status)) {
                        newHistory.Time_at_EF__c = true;
                    }
                    historyRecords.add(newHistory);
                }
            }
            
            // Upsert the TicketHistoryHandler records
            if (!historyRecords.isEmpty()) {
                upsert historyRecords;
            }
        }
    }
    
    public static Long calculateDurationStringExcludingWeekends(DateTime startDate, DateTime endDate, BusinessHours bh) {
        // Get the difference in milliseconds using BusinessHours
        Long diffMilliseconds = BusinessHours.diff(bh.Id, startDate, endDate);
        System.debug(diffMilliseconds);
        return diffMilliseconds;
    }  
}