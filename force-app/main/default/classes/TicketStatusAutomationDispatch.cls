public class TicketStatusAutomationDispatch implements system.Schedulable{
    public void execute(system.SchedulableContext sc) {
            TicketStatusAutomationBatch batch = new TicketStatusAutomationBatch();
            database.executeBatch(batch, 2);
    }
}