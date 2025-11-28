public class CaseTriggerHandler {
    
    private static List<RecordType> getAMSrecordTypeIds(){
        List<RecordType> amsRecordTypes = [Select Id from RecordType where DeveloperName IN('AMS_Ticket','AMS_Service_Request','Enhancement_Request')];
        return amsRecordTypes;
    }
    
    public static void handleAfterInsert(List<Case> caseRecordList) {
        RecordType bpoRecordType = [Select Id from RecordType where DeveloperName='EF_BPO_Ticket'];
        Set<Id>amsRecordTypeIds = (new Map<Id, SObject>(getAMSrecordTypeIds())).keySet();

        List<Case> efBpoCases = new List<Case>();
        List<Case> efAmsCases = new List<Case>();

        for(Case eachCase:caseRecordList){
            //EF BPO
            if(eachCase.RecordTypeId != null && eachCase.RecordTypeId == bpoRecordType.Id){
                efBpoCases.add(eachCase);
            }
            //EF AMS
            if(eachCase.RecordTypeId != null && amsRecordTypeIds.contains(eachCase.RecordTypeId)){
                efAmsCases.add(eachCase);
            }
        }
        if(efBpoCases.size() > 0){
            EfBpoCaseTriggerHelper.handleAfterInsert(efBpoCases);
        }
        if(efAmsCases.size() > 0){
            EfAmsCaseTriggerHelper.handleSLARecords(efAmsCases, null);
        }
    }
    
    public static void handleAfterUpdate(List<Case> caseRecordList, Map<Id, Case> oldCaseMap) {
        RecordType bpoRecordType = [Select Id from RecordType where DeveloperName='EF_BPO_Ticket'];
        Set<Id>amsRecordTypeIds = (new Map<Id, SObject>(getAMSrecordTypeIds())).keySet();
        
        List<Case> efBpoCases = new List<Case>();
        List<Case> efAmsCases = new List<Case>();

        for(Case eachCase:caseRecordList){
            //EF BPO
            if(eachCase.RecordTypeId != null && eachCase.RecordTypeId == bpoRecordType.Id){
                efBpoCases.add(eachCase);
            }
            //EF AMS
            if(eachCase.RecordTypeId != null && amsRecordTypeIds.contains(eachCase.RecordTypeId)){
                efAmsCases.add(eachCase);
            }
        }
        if(efBpoCases.size() > 0){
            EfBpoCaseTriggerHelper.handleAfterUpdate(efBpoCases,oldCaseMap);
        }
        if(efAmsCases.size() > 0){
            EfAmsCaseTriggerHelper.handleSLARecords(efAmsCases, oldCaseMap);
        }
    }
    
    public static void handleBeforeInsert(List<Case> caseRecordList) {
        Set<Id>amsRecordTypeIds = (new Map<Id, SObject>(getAMSrecordTypeIds())).keySet();
        List<Case> efAmsCases = new List<Case>();

        AgentActivityTracker.updateActivityDate(caseRecordList);
        
        for(Case eachCase:caseRecordList){
            //EF AMS
            if(eachCase.RecordTypeId != null && amsRecordTypeIds.contains(eachCase.RecordTypeId)){
                efAmsCases.add(eachCase);
            }
        }
        if(efAmsCases.size() > 0){
            EfAmsCaseTriggerHelper.calculateSLORemainingTime(efAmsCases);
        }
    }
    
    public static void handleBeforeUpdate(List<Case> caseRecordList, Map<Id, Case> oldCaseMap) {
        Set<Id>amsRecordTypeIds = (new Map<Id, SObject>(getAMSrecordTypeIds())).keySet();
        List<Case> efAmsCases = new List<Case>();

        CommonCaseTriggerHelper.calculateNextActionDate(caseRecordList, oldCaseMap);
        AgentActivityTracker.updateActivityDate(caseRecordList);

        for(Case eachCase:caseRecordList){
            //EF AMS
            if(eachCase.RecordTypeId != null && amsRecordTypeIds.contains(eachCase.RecordTypeId)){
                efAmsCases.add(eachCase);
            }
        }
        if(efAmsCases.size() > 0){
            EfAmsCaseTriggerHelper.calculateSLORemainingTime(efAmsCases);
            EfAmsCaseTriggerHelper.updateStatusChangedDate(efAmsCases, oldCaseMap);
            TicketHistoryHandler.trackTicketFieldChanges(efAmsCases, oldCaseMap);
        }
    }
    
}