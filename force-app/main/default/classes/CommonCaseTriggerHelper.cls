public with sharing class CommonCaseTriggerHelper {    
    public static void calculateNextActionDate(List<Case> newValues, Map<Id,Case> oldValues){
        
        Integer businessDays;
        String businessHoursId;
        Datetime startDate = Datetime.now();

        List<Ticket_Status_Setting__mdt> settings = [SELECT Id, DeveloperName,  RecordTypeId__c, No_of_days_in_Pending__c, No_of_days_in_resolved__c, Business_Hours_Id__c FROM Ticket_Status_Setting__mdt];
        Map<String, Ticket_Status_Setting__mdt> settingsMap = new Map<String, Ticket_Status_Setting__mdt>();

        for(Ticket_Status_Setting__mdt setting: settings){
            settingsMap.put(setting.RecordTypeId__c, setting);
        }
        
        for(Case eachCase: newValues){
            if(eachCase.Is_an_EF_Helpdesk_Record_Type__c || eachCase.Is_an_AMS_Ticket__c){

                businessHoursId = settingsMap.get(eachCase.RecordTypeId).Business_Hours_Id__c;         

                if(eachCase.Status == 'Pending' && oldValues.get(eachCase.Id).Status != 'Pending'){
                    businessDays = settingsMap.get(eachCase.RecordTypeId).No_of_days_in_Pending__c.intValue();
                    eachCase.Next_Action__c = 'Send Pending Chaser';
                    eachCase.Next_Action_DateTime__c = calculateNextActionDateHelper(businessHoursId, startDate, businessDays);
                }
                else if(eachCase.Next_Action__c == 'Status To Resolved' && oldValues.get(eachCase.Id).Next_Action__c != 'Status To Resolved' && eachCase.Status == 'Pending'){
                    businessDays = 1;
                    eachCase.Next_Action_DateTime__c = calculateNextActionDateHelper(businessHoursId, startDate, businessDays);
                } 
                else if(eachCase.Status == 'Resolved' && oldValues.get(eachCase.Id).Status != 'Resolved'){
                    businessDays = settingsMap.get(eachCase.RecordTypeId).No_of_days_in_resolved__c.intValue();
                    eachCase.Next_Action__c = 'Status To Closed';
                    eachCase.Next_Action_DateTime__c = calculateNextActionDateHelper(businessHoursId, startDate, businessDays);
                }
            }
        }
    } 

private static Datetime calculateNextActionDateHelper(String id, Datetime start, Integer days){
    Datetime nextReminderDate = BusinessHours.add(Id, start, days*24*60*60*1000);
    return nextReminderDate;
}

}