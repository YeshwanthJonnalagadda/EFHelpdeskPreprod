@isTest
public  class TicketTransferTest {
    @isTest
    public static void testTransfer(){

        // Set mock callout class
        Test.setMock(HttpCalloutMock.class, new TicketTransferMock());

        //setup the argument for method
        List<TicketTransferFields> fields = new List<TicketTransferFields>();
        TicketTransferFields ttf = new TicketTransferFields();
        ttf.subject = 'test subject';
        ttf.description = 'test description';
        ttf.groupId = 50000000000L;
        ttf.priority = 1;
        ttf.source = 2;
        ttf.status = 2;
        ttf.email = 'test@gmail.com';
        ttf.serviceTeam = 'test service team';
        ttf.tags = 'test tag';
        ttf.type = 'test type';
        fields.add(ttf);

        List<Integer> resCodes = TicketTransfer.transfer(fields);

        // Verify that the response received contains fake values
        System.assertEquals(201, resCodes[0], 'The status code is not 201');
    }
}