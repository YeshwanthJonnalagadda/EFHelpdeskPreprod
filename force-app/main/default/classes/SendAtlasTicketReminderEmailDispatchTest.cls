@isTest
public class SendAtlasTicketReminderEmailDispatchTest {
    @isTest
    public static void dispatchTest() {
        string testCron = '0 0 0 1 * ?';
        test.startTest();
        SendAtlasTicketReminderEmailDispatch newdispatch = new SendAtlasTicketReminderEmailDispatch();
        system.schedule('ScheduledApexTest', testCron, newdispatch);
        test.stopTest();
    }
}