public class CloseRejectedTicktesBatch implements Database.Batchable<SObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id, Status FROM Case WHERE IsClosed = false AND Origin = 'Email' AND Owner_Full_Name__c LIKE 'Rejected%']);
    }

    public void execute(Database.BatchableContext bc, List<Case> scope) {
        for (Case eachCase : scope) {
            eachCase.Status = 'Closed';
        }

        if(!scope.isEmpty()){
            update(scope);
        }
    }

    public void finish(Database.BatchableContext bc){
        //execute any post-processing operations
    }
}