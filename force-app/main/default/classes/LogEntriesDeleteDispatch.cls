public class LogEntriesDeleteDispatch implements Schedulable {
    public void execute(SchedulableContext ctx){
        LogEntriesDeleteBatch batch = new LogEntriesDeleteBatch();
        Database.executeBatch(batch, 200);
    }
}