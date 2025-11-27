public class CloseRejectedTicketsDispatch implements system.Schedulable {
    public void execute(system.SchedulableContext sc) {
        CloseRejectedTicktesBatch batch = new CloseRejectedTicktesBatch();
        database.executeBatch(batch, 2);
}
}