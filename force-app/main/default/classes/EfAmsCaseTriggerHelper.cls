public class EfAmsCaseTriggerHelper {

    // Map to store response hours for each priority level
    private static final Map<String, Integer> PRIORITY_TO_RESPONSE_HOURS = new Map<String, Integer>{
        'Urgent' => 2,
        'High' => 4,
        'Medium' => 8,
        'Low' => 16
    };
    
    // Map to store resolution hours for each priority level
    private static final Map<String, Integer> PRIORITY_TO_RESOLUTION_HOURS = new Map<String, Integer>{
        'Urgent' => 4,
        'High' => 12,
        'Medium' => 24,
        'Low' => 120
    };

    //Method to calculate slo response and resolution remaining time
    public static void calculateSLORemainingTime(List<case> caseList){
        
        for (Case caseRecord : caseList) {
            // Get priority and time values
            String priority = caseRecord.Priority;
            Decimal responseTimeDecimal = caseRecord.SLA_Response_Time__c;
            Decimal resolutionTimeDecimal = caseRecord.SLA_Resolution_Time__c;
            
            // Calculate remaining times
            Decimal responseRemainingTime = calculateRemainingTime(priority, 'response', responseTimeDecimal);
            Decimal resolutionRemainingTime = calculateRemainingTime(priority, 'resolution', resolutionTimeDecimal);
            
            // Convert to 'hh:mm' format
            caseRecord.SLO_Response_Remaining_Time1__c = convertToHHMMFormat(responseRemainingTime);
            caseRecord.SLO_Resolution_Remaining_Time1__c = convertToHHMMFormat(resolutionRemainingTime);
        }
    }
    
    // Method to convert a decimal time value (in hh.mm format) to decimal hours
    public static Decimal convertToDecimalHours(Decimal timeDecimal) {
        if (timeDecimal == null) {
            return 0; // Return 0 if timeDecimal is null
        }
        
        Integer hours = timeDecimal.intValue(); // Extract integer hours
        Decimal minutes = (timeDecimal - hours) * 100; // Extract minutes as a decimal
        return hours + (minutes / 60); // Convert minutes to decimal hours and add to hours
    }

    // Method to calculate remaining time based on priority and type (response/resolution)
    public static Decimal calculateRemainingTime(String priority, String type, Decimal timeDecimal) {
        Map<String, Integer> priorityToHoursMap;

        if (type == 'response') {
            priorityToHoursMap = PRIORITY_TO_RESPONSE_HOURS;
        } else if (type == 'resolution') {
            priorityToHoursMap = PRIORITY_TO_RESOLUTION_HOURS;
        } else {
            return 0; // Return 0 if the type is invalid
        }

        if (priorityToHoursMap.containsKey(priority)) {
            Decimal totalHours = priorityToHoursMap.get(priority); // Get total hours for the priority
            Decimal elapsedHours = convertToDecimalHours(timeDecimal); // Convert elapsed time to decimal hours
            Decimal remainingHours = totalHours - elapsedHours; // Calculate remaining time
            return remainingHours < 0 ? 0 : remainingHours; // Ensure no negative time is returned
        }
        return 0; // Return 0 if priority is not found
    }

    // Method to convert decimal hours to 'hh:mm' format
    public static String convertToHHMMFormat(Decimal hoursDecimal) {
        if (hoursDecimal == null) {
            return '00:00'; // Return default '00:00' if hoursDecimal is null
        }

        Integer hours = hoursDecimal.intValue(); // Extract integer hours
        Integer minutes = ((hoursDecimal - hours) * 60).round().intValue(); // Convert remaining decimal to minutes and round
        return padZero(hours) + ':' + padZero(minutes); // Format as 'hh:mm'
    }

    // Helper method to pad single-digit numbers with a leading zero
    private static String padZero(Integer value) {
        return value < 10 ? '0' + String.valueOf(value) : String.valueOf(value); // Pad with zero if less than 10
    }
    
    //Method to update Status_Changed_Date__c 
    public static void updateStatusChangedDate(List<Case> newCaseList, Map<Id, Case> oldCaseMap){
        for (Case caseRecord : newCaseList) {
            
            // Check if the status has changed
            if (caseRecord.Status != oldCaseMap.get(caseRecord.Id).Status) {
                caseRecord.Status_Changed_Date__c = System.now(); 
            }
        }
    }

    //Method to insert/update SLA records
    public static void handleSLARecords(List<Case> caseRecordList, Map<Id, Case> oldCaseMap) {
        Set<Id> caseIdSet = new Set<Id>();
        Map<Id, Case> caseRecordMap = new Map<Id, Case>(caseRecordList);
        
        for (Case caseRecord : caseRecordList) {
            if (oldCaseMap != null && caseRecord.Status != oldCaseMap.get(caseRecord.Id).Status) {
                caseIdSet.add(caseRecord.Id);
            }
        }
        
        Map<Id, Service_Level_Agreement__c> currentSLARecords = new Map<Id, Service_Level_Agreement__c>();
        
        if (!caseIdSet.isEmpty()) {
            for (Service_Level_Agreement__c slaRec : [SELECT Id, Case_Id__c, End_Time__c, IsCurrent__c 
                                                      FROM Service_Level_Agreement__c 
                                                      WHERE Case_Id__c IN :caseIdSet 
                                                      AND IsCurrent__c = true])
            {
                currentSLARecords.put(slaRec.Case_Id__c, slaRec);
            }
        }
        
        List<Service_Level_Agreement__c> newSlaRecords = new List<Service_Level_Agreement__c>();
        List<Service_Level_Agreement__c> updateSlaRecords = new List<Service_Level_Agreement__c>();
        
        for (Case caseRecord : caseRecordList) {
            if (oldCaseMap == null || caseRecord.Status != oldCaseMap.get(caseRecord.Id).Status) {
                if (oldCaseMap != null && currentSLARecords.containsKey(caseRecord.Id)) {
                    // Update the previous SLA record's End_Time__c and IsCurrent__c
                    Service_Level_Agreement__c oldSla = currentSLARecords.get(caseRecord.Id);
                    oldSla.End_Time__c = caseRecord.LastModifiedDate;
                    oldSla.IsCurrent__c = false;
                    updateSlaRecords.add(oldSla);
                }
                
                // Create a new SLA record
                Service_Level_Agreement__c newSla = new Service_Level_Agreement__c();
                newSla.Case_Id__c = caseRecord.Id;
                newSla.Start_Time__c = (oldCaseMap == null) ? caseRecord.CreatedDate : caseRecord.LastModifiedDate;
                newSla.IsCurrent__c = true;
                newSla.Case_Status__c = caseRecord.Status;
                newSlaRecords.add(newSla);
            }
        }
        if (!updateSlaRecords.isEmpty()) {
            UPDATE updateSlaRecords;
        }
        if (!newSlaRecords.isEmpty()) {
            INSERT newSlaRecords;
        }
    }
}