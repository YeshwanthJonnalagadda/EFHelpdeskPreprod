trigger ServiceLevelAgreementTrigger on Service_Level_Agreement__c (before insert, before update, after insert, after update, after delete, after undelete) {
    
    if(Trigger.isBefore) {
        if(Trigger.isInsert || Trigger.isUpdate) {
            ServiceLevelAgreementTriggerHandler.handleBeforeInsertUpdate(Trigger.new);
        }
    }
    
    if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
            ServiceLevelAgreementTriggerHandler.updateCaseSLATimes(Trigger.new);
        }
        if (Trigger.isDelete) {
            ServiceLevelAgreementTriggerHandler.removeCaseSLATimes(Trigger.old);
        }
    }
}