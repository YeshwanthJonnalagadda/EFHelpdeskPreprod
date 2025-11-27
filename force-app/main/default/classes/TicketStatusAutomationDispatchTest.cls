@isTest
public class TicketStatusAutomationDispatchTest {

    @isTest
    public static void test1(){
        TicketStatusAutomationDispatch t1 = new TicketStatusAutomationDispatch();
        String cronExp = '0 0 12 1 * ?';

        test.StartTest();
        String jobID = system.schedule('Testing TicketStatusAutomationDispatch', cronExp, t1);
        test.StopTest();

        System.assert(jobID <> Null, 'The scheduled job ID is null.  No scheduled Job was created.');
    }
}