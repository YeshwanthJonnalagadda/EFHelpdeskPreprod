public class EfAmsCaseTriggerHelper {
    
    //Method to update Status_Changed_Date__c 
    public static void updateStatusChangedDate(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
        for (Case caseRecord : newCaseList) {
            
            // Check if the status has changed
            if (caseRecord.Status != oldCaseMap.get(caseRecord.Id).Status) {
                caseRecord.Status_Changed_Date__c = System.now(); 
            }
        }
    }
    
    //Method to insert/update SLA records
    public static void handleSLARecords(List<Case> caseRecordList, Map<Id, Case> oldCaseMap) {
        Set<Id> caseIdSet = new Set<Id>();
        Map<Id, Case> caseRecordMap = new Map<Id, Case>(caseRecordList);
        
        for (Case caseRecord : caseRecordList) {
            if (oldCaseMap != null && caseRecord.Status != oldCaseMap.get(caseRecord.Id).Status) {
                caseIdSet.add(caseRecord.Id);
            }
        }
        
        Map<Id, Service_Level_Agreement__c> currentSLARecords = new Map<Id, Service_Level_Agreement__c>();
        
        if (!caseIdSet.isEmpty()) {
            for (Service_Level_Agreement__c slaRec : [SELECT Id, Case_Id__c, End_Time__c, IsCurrent__c 
                                                      FROM Service_Level_Agreement__c 
                                                      WHERE Case_Id__c IN :caseIdSet 
                                                      AND IsCurrent__c = true])
            {
                currentSLARecords.put(slaRec.Case_Id__c, slaRec);
            }
        }
        
        List<Service_Level_Agreement__c> newSlaRecords = new List<Service_Level_Agreement__c>();
        List<Service_Level_Agreement__c> updateSlaRecords = new List<Service_Level_Agreement__c>();
        
        for (Case caseRecord : caseRecordList) {
            if (oldCaseMap == null || caseRecord.Status != oldCaseMap.get(caseRecord.Id).Status) {

                if (oldCaseMap != null && currentSLARecords.containsKey(caseRecord.Id)) {
                    // Update the previous SLA record's End_Time__c and IsCurrent__c
                    Service_Level_Agreement__c oldSla = currentSLARecords.get(caseRecord.Id);
                    oldSla.End_Time__c = caseRecord.LastModifiedDate;
                    oldSla.IsCurrent__c = false;
                    updateSlaRecords.add(oldSla);
                } 
                if(caseRecord.Status == 'New' || caseRecord.Status == 'Open' || caseRecord.Status == 'In Progress') {
                    // Create a new SLA record
                    Service_Level_Agreement__c newSla = new Service_Level_Agreement__c();
                    newSla.Case_Id__c = caseRecord.Id;
                    newSla.Start_Time__c = (oldCaseMap == null) ? caseRecord.CreatedDate : caseRecord.LastModifiedDate;
                    newSla.IsCurrent__c = true;
                    newSla.Case_Status__c = caseRecord.Status;
                    newSlaRecords.add(newSla);
                } 

            }
        }
        if (!updateSlaRecords.isEmpty()) {
            UPDATE updateSlaRecords;
        }
        if (!newSlaRecords.isEmpty()) {
            INSERT newSlaRecords;
        }
    }
}