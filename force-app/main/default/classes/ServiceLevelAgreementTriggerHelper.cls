/*
 * @Purpose: ServiceLevelAgreementTriggerHelper to calculate total time hours
 * */
public class ServiceLevelAgreementTriggerHelper {
    
    public static void timeSpent(List<Service_Level_Agreement__c> slaList){
        // Fetch Business Hours ID once and reuse
        Id businessHoursId = [SELECT Id FROM BusinessHours WHERE Name = 'New Business Hours' LIMIT 1].Id;
        for (Service_Level_Agreement__c sla : slaList) {
            if(sla.Start_Time__c == null){
                continue;
            }
            if(sla.End_Time__c != null) {
                sla.Total_time_hours__c = calculateTime(sla.Start_Time__c, sla.End_Time__c, businessHoursId);
            } else {
                sla.Elapsed_time_hours__c = calculateTime(sla.Start_Time__c, System.now(), businessHoursId);
                sla.Total_time_hours__c = sla.Elapsed_time_hours__c;
                
            }
        }
    }

    // Method to calculate time considering business hours
    public static Decimal calculateTime(Datetime startTime, Datetime endTime, Id businessHoursId) {        
        // Calculate the time difference in milliseconds considering business hours
        Long milliseconds = BusinessHours.diff(businessHoursId, startTime, endTime);
        
        // Convert to hours
        Decimal totalMinutes = milliseconds / (1000 * 60);
        Decimal hours = totalMinutes / 60;
        
        //Trim decimal to 2 digits after dot
        Decimal formattedHours = hours.setScale(2);
        return formattedHours;
    }
    
}