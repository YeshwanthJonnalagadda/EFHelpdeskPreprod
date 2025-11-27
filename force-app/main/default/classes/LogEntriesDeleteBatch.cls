public class LogEntriesDeleteBatch implements Database.Batchable<SObject>{
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id FROM Log_Entry__c WHERE Is_eligible_for_deletion__c = true]);
    }

    public void execute(Database.BatchableContext bc, List<Log_Entry__c> scope){
        if(!scope.isEmpty()){
            delete scope;
        }        
    }
    public void finish(Database.BatchableContext bc){
        system.debug('execute any post-processing operations'); 
    }
}