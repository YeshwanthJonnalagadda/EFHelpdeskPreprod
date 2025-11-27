@isTest
public class LogEntriesDeleteDispatchTest {
    @isTest
    public static void testScheduleJOb(){
        string testCron = '0 0 0 1 * ?';
        test.startTest();
        LogEntriesDeleteDispatch dispatch = new LogEntriesDeleteDispatch();
        system.schedule('ScheduledApexTest', testCron, dispatch);
        test.stopTest();
    }
}