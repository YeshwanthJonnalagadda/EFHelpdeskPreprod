@isTest
public class SendNonToursTicketReminderDispatchTest {
    @isTest
    public static void dispatchTest() {
        string testCron = '0 0 0 1 * ?';
        test.startTest();
        SendNonToursTicketReminderDispatch newdispatch = new SendNonToursTicketReminderDispatch();
        system.schedule('ScheduledApexTest', testCron, newdispatch);
        test.stopTest();
    }
}