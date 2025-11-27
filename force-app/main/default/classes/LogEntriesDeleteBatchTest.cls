@isTest
public class LogEntriesDeleteBatchTest {
    @isTest
    static void testBatchProcess(){
        //Create a test log entry
        Log_Entry__c logEntry = new Log_Entry__c(Payload__c = 'Entry 1');
        insert logEntry;
        
        //Set a pastDate for deletion
        Datetime pastDatetime = system.now().addDays(-31);
        test.setCreatedDate(logEntry.Id, pastDatetime);
        update logEntry;

        //Execute batch class
        test.startTest();
        LogEntriesDeleteBatch batch = new LogEntriesDeleteBatch();
        Id BatchId = Database.executeBatch(batch, 200);
        test.stopTest();

        //Query the log entry after deletion was completed
        List<Log_Entry__c> logEntries = [SELECT Id FROM Log_Entry__c WHERE Id =:logEntry.Id];
        system.Assert.areEqual(0, logEntries.size());
    }
}