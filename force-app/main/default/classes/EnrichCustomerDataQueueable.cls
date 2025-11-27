public class EnrichCustomerDataQueueable implements Queueable {
    @InvocableMethod(label='Invoke Enrich Customer Data Queueable')
    public static void invokeQueueable(List<String>newStrings){
        EnrichCustomerDataQueueable newQueueableJob = new EnrichCustomerDataQueueable(newStrings);
        System.enqueueJob(newQueueableJob);
    }
    private List<String> newStrings;
    public EnrichCustomerDataQueueable(List<String> ticketIdToContactIdString){
        this.newStrings = ticketIdToContactIdString;
    }

    public void execute(QueueableContext context){
        Map<String, String> ticketIdToContactIdMap = new Map<String, String>();
        for(String eachString: newStrings){
            ticketIdToContactIdMap.put(eachString.split('-')[0], eachString.split('-')[1]);
        }
        List<Case> casesToUpdate = new List<Case>();
        for(Case eachCase:[SELECT Id, contactId FROM Case WHERE Id IN:ticketIdToContactIdMap.keySet()]){
            eachCase.ContactId = ticketIdToContactIdMap.get(eachCase.Id);
            casesToUpdate.add(eachCase);
        }
        if(!casesToUpdate.isEmpty()){
            update casesToUpdate;
        }
    }
}