public class CaseTriggerHandler extends TriggerHandler {
    
    private static List<RecordType> getAMSrecordTypeIds(){
        List<RecordType> amsRecordTypes = [Select Id from RecordType where DeveloperName IN('AMS_Ticket','AMS_Service_Request','Enhancement_Request')];
        return amsRecordTypes;
    }
    
    //Handle before insert
    public override void beforeInsert() {
        Set<Id>amsRecordTypeIds = (new Map<Id, SObject>(getAMSrecordTypeIds())).keySet();
        List<Case> efAmsCases = new List<Case>();

        AgentActivityTracker.updateActivityDate(Trigger.new);
        
        for(Case eachCase:(List<Case>)Trigger.new){
            //EF AMS
            if(eachCase.RecordTypeId != null && amsRecordTypeIds.contains(eachCase.RecordTypeId)){
                efAmsCases.add(eachCase);
            }
        }
        if(efAmsCases.size() > 0){
            EfAmsCaseTriggerHelper.calculateSLORemainingTime(efAmsCases);
        }
    }

    //Handle after insert
    public override void afterInsert() {
        RecordType bpoRecordType = [Select Id from RecordType where DeveloperName='EF_BPO_Ticket'];
        Set<Id>amsRecordTypeIds = (new Map<Id, SObject>(getAMSrecordTypeIds())).keySet();

        List<Case> efBpoCases = new List<Case>();
        List<Case> efAmsCases = new List<Case>();

        CommonCaseTriggerHelper.handleTicketContactRoles((List<Case>)Trigger.new, null);

        for(Case eachCase:(List<Case>)Trigger.new){
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

    //Handle before update
    public override void beforeUpdate() {
        Set<Id>amsRecordTypeIds = (new Map<Id, SObject>(getAMSrecordTypeIds())).keySet();
        List<Case> efAmsCases = new List<Case>();

        CommonCaseTriggerHelper.calculateNextActionDate((List<Case>)Trigger.new, (Map<Id,Case>)Trigger.oldMap);
        AgentActivityTracker.updateActivityDate(Trigger.new);

        for(Case eachCase:(List<Case>)Trigger.new){
            //EF AMS
            if(eachCase.RecordTypeId != null && amsRecordTypeIds.contains(eachCase.RecordTypeId)){
                efAmsCases.add(eachCase);
            }
        }
        if(efAmsCases.size() > 0){
            EfAmsCaseTriggerHelper.calculateSLORemainingTime(efAmsCases);
            EfAmsCaseTriggerHelper.updateStatusChangedDate(efAmsCases, (Map<Id,Case>)Trigger.oldMap);
            TicketHistoryHandler.trackTicketFieldChanges(efAmsCases, (Map<Id,Case>)Trigger.oldMap);
        }
    }
    
    //handle after update
    public override void afterUpdate() {
        RecordType bpoRecordType = [Select Id from RecordType where DeveloperName='EF_BPO_Ticket'];
        Set<Id>amsRecordTypeIds = (new Map<Id, SObject>(getAMSrecordTypeIds())).keySet();
        
        List<Case> efBpoCases = new List<Case>();
        List<Case> efAmsCases = new List<Case>();

        CommonCaseTriggerHelper.handleTicketContactRoles((List<Case>)Trigger.new, (Map<Id,Case>)Trigger.oldMap);

        for(Case eachCase:(List<Case>)Trigger.new){
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
            EfBpoCaseTriggerHelper.handleAfterUpdate(efBpoCases, (Map<Id,Case>)Trigger.oldMap);
        }
        if(efAmsCases.size() > 0){
            EfAmsCaseTriggerHelper.handleSLARecords(efAmsCases, (Map<Id,Case>)Trigger.oldMap);
        }
    }

}