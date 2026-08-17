trigger ServiceLevelAgreementTrigger on Service_Level_Agreement__c (before insert, before update, after insert, after update, before delete, after delete, after undelete) {
    new ServiceLevelAgreementTriggerHandler().run();
}