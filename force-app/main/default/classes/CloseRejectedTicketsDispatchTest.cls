@isTest
public class CloseRejectedTicketsDispatchTest{

    @isTest
    public static void test1(){
        CloseRejectedTicketsDispatch t1 = new CloseRejectedTicketsDispatch();
        String cronExp = '0 0 12 1 * ?';

        test.StartTest();
        String jobID = system.schedule('Testing CloseRejectedTickestDispatch', cronExp, t1);
        test.StopTest();

        System.assert(jobID <> Null, 'The scheduled job ID is null.  No scheduled Job was created.');
    }
}