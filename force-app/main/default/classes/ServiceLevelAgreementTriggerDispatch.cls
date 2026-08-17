public class ServiceLevelAgreementTriggerDispatch implements Database.Batchable<SObject>, Schedulable {
    // Schedulable execute method
    public void execute(SchedulableContext sc) {
        ServiceLevelAgreementTriggerDispatch b = new ServiceLevelAgreementTriggerDispatch();
        Database.executeBatch(b, 200);
    }
    // Batchable start method
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id, Last_trigger_to_calculate_elapsed_time__c FROM Service_Level_Agreement__c
                                                    WHERE End_Time__c = null AND IsCurrent__c = true AND Case_Status__c <> 'Closed']);
    }
    // Batchable execute method
    public void execute(Database.BatchableContext bc, List<Service_Level_Agreement__c> scope) {
        for( Service_Level_Agreement__c eachSLA : scope) {
            eachSLA.Last_trigger_to_calculate_elapsed_time__c = System.now();
       }

       update scope;
    }
    // Batchable finish method
    public void finish(Database.BatchableContext bc){
        system.debug('Job finished');
    }
}