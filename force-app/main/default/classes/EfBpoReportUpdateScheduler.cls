global class EfBpoReportUpdateScheduler implements Schedulable {
    private Integer minutesToAdd; 
    // Constructor to accept minutes parameter
    public EfBpoReportUpdateScheduler(Integer minutes) {
        this.minutesToAdd = minutes; 
    }
    global void execute(SchedulableContext sc) {
        // Execute the batch
        Database.executeBatch(new EfBpoReportUpdateBatch(), 50);
        
        // Find and delete the previous scheduled job
        List<CronTrigger> cronJobs = [SELECT Id, CronJobDetail.Name FROM CronTrigger WHERE CronJobDetail.Name = 'EfBpoReportUpdateScheduler - Next Run' OR CronJobDetail.Name = 'EfBpoReportUpdateScheduler - Initial Run'];
        for (CronTrigger cronJob : cronJobs) {
            System.abortJob(cronJob.Id);
        }
        
        // Schedule itself to run again after defined minutes
        String cronExpression = System.now().addMinutes(this.minutesToAdd).format('ss mm HH dd MM ? yyyy');
        System.schedule('EfBpoReportUpdateScheduler - Next Run', cronExpression, new EfBpoReportUpdateScheduler(this.minutesToAdd));
    }
}


/*
global class EfBpoReportUpdateScheduler implements Schedulable {


global void execute(SchedulableContext sc) {
BusinessHours bh = [SELECT Id FROM BusinessHours WHERE Name = 'EF BPO Business Hours' LIMIT 1];
List<TicketHistoryHandler__c> histories = [SELECT Id, Start_Date__c, Duration_Milliseconds__c,Duration_Calculated_For_Status__c
FROM TicketHistoryHandler__c
WHERE End_Date__c = NULL AND Duration_Calculated_For_Status__c!='Closed'];
for (TicketHistoryHandler__c history : histories) {
Long diffMilliseconds = BusinessHours.diff(bh.Id, history.Start_Date__c, system.now());
history.Duration_Milliseconds__c = diffMilliseconds;
}
update histories;
}
}*/