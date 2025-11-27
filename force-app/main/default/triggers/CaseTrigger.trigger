trigger CaseTrigger on Case (before insert, before update, after insert, after update) {
    
    if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            CaseTriggerHandler.handleAfterInsert(Trigger.new);
        }
        if(Trigger.isUpdate) {
            CaseTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
    
    if(Trigger.isBefore) {
        if(Trigger.isInsert) {
            CaseTriggerHandler.handleBeforeInsert(Trigger.new);
        }
        if(Trigger.isUpdate){
            CaseTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
        }
    }
    
}