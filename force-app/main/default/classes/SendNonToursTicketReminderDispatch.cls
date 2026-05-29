public class SendNonToursTicketReminderDispatch implements Schedulable {
    public void execute(SchedulableContext sc) {
        SendNonToursTicketReminderEmail newBatch = new SendNonToursTicketReminderEmail();
        Database.executeBatch(newBatch, 2);
    }
}