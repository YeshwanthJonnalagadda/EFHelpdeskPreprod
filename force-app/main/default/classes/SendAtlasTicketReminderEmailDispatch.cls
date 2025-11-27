public class SendAtlasTicketReminderEmailDispatch implements Schedulable {
    public void execute(SchedulableContext sc) {
        SendAtlasTicketReminderEmail newBatch = new SendAtlasTicketReminderEmail();
        Database.executeBatch(newBatch, 2);
    }
}