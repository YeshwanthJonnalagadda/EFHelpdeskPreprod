/*
 * @Purpose: ServiceLevelAgreementTrigger handler to calculate Time Spent, Ticket SLO Response and Resolution Time 
 * */

public class ServiceLevelAgreementTriggerHandler {

    // Fetch Business Hours ID once and reuse
    private static final Id businessHoursId = getBusinessHoursId('New Business Hours');

    public static void handleBeforeInsertUpdate(List<Service_Level_Agreement__c> slaList){
        for (Service_Level_Agreement__c sla : slaList) {
            if(sla.Start_Time__c != null && sla.End_Time__c != null) {
                sla.Time_Spent__c = calculateTimeSpent(sla.Start_Time__c, sla.End_Time__c, businessHoursId);
            } else {
                sla.Time_Spent__c = '0.00';
            }
        }
    }
    
    // Method to calculate time spent considering business hours
    public static String calculateTimeSpent(Datetime startTime, Datetime endTime, Id businessHoursId) {        
        // Calculate the time difference in milliseconds considering business hours
        Long milliseconds = BusinessHours.diff(businessHoursId, startTime, endTime);
        
        // Convert to hours and minutes
        Long totalMinutes = milliseconds / (1000 * 60);
        Long hours = totalMinutes / 60;
        Long minutes = Math.mod(totalMinutes, 60);
        
        // Manually pad minutes with leading zero if needed
        String formattedMinutes = minutes < 10 ? '0' + String.valueOf(minutes) : String.valueOf(minutes);
        
        // Format the result as hh.mm
        String formattedTime = String.valueOf(hours) + '.' + formattedMinutes;
        
        return formattedTime;
    }
    
    // Method to get the Business Hours ID by name
    public static Id getBusinessHoursId(String businessHoursName) {
        BusinessHours businessHours = [SELECT Id FROM BusinessHours WHERE Name = :businessHoursName LIMIT 1];
        return businessHours.Id;
    }
    
    // Method to update SLA times on Cases based on the provided SLA list
    public static void updateCaseSLATimes(List<Service_Level_Agreement__c> slaList) {
        Set<Id> caseIdsToUpdate = getCaseIdSet(slaList);
        Map<Id, List<Service_Level_Agreement__c>> caseIdToSLARecordsMap = retrieveAllRelatedSLAs(caseIdsToUpdate);
        Map<Id, Case> caseMap = getCaseList(caseIdsToUpdate);
        List<Case> casesToUpdate = accumulateSLAUpdates(caseMap, caseIdToSLARecordsMap, slaList);
        
        updateCases(casesToUpdate);
    }

    // Method to remove SLA times from Cases based on the provided SLA list
    public static void removeCaseSLATimes(List<Service_Level_Agreement__c> slaList) {
        Set<Id> caseIdsToUpdate = getCaseIdSet(slaList);
        Map<Id, List<Service_Level_Agreement__c>> caseIdToSLARecordsMap = retrieveAllRelatedSLAs(caseIdsToUpdate);
        Map<Id, Case> caseMap = getCaseList(caseIdsToUpdate);
        List<Case> casesToUpdate = adjustSLAUpdates(caseMap, caseIdToSLARecordsMap, slaList);

        updateCases(casesToUpdate);
    }

    // Method to get the set of Case IDs from the provided SLA list
    private static Set<Id> getCaseIdSet(List<Service_Level_Agreement__c> slaList) {
        Set<Id> caseIdSet = new Set<Id>();
        for (Service_Level_Agreement__c sla : slaList) {
            if (sla.Case_Id__c != null) {
                caseIdSet.add(sla.Case_Id__c);
            }
        }
        return caseIdSet;
    }

    // Method to retrieve all related SLA records for the given Case IDs
    private static Map<Id, List<Service_Level_Agreement__c>> retrieveAllRelatedSLAs(Set<Id> caseIds) {
        List<Service_Level_Agreement__c> slaRecords = [
            SELECT Id, Case_Id__c, Case_Status__c, Time_Spent__c 
            FROM Service_Level_Agreement__c 
            WHERE Case_Id__c IN :caseIds
        ];

        // Organize the retrieved SLA records by Case ID
        Map<Id, List<Service_Level_Agreement__c>> caseIdToSLARecordsMap = new Map<Id, List<Service_Level_Agreement__c>>();
        for (Service_Level_Agreement__c sla : slaRecords) {
            if (!caseIdToSLARecordsMap.containsKey(sla.Case_Id__c)) {
                caseIdToSLARecordsMap.put(sla.Case_Id__c, new List<Service_Level_Agreement__c>());
            }
            caseIdToSLARecordsMap.get(sla.Case_Id__c).add(sla);
        }
        return caseIdToSLARecordsMap;
    }

    // Method to get the list of Case records that need to be updated
    private static Map<Id, Case> getCaseList(Set<Id> caseIdsToUpdate) {
        return new Map<Id, Case>([
            SELECT Id, SLA_Resolution_Time__c, SLA_Response_Time__c 
            FROM Case 
            WHERE Id IN :caseIdsToUpdate
        ]);
    }

    // Method to accumulate SLA updates for the Cases
    private static List<Case> accumulateSLAUpdates(Map<Id, Case> caseMap, Map<Id, List<Service_Level_Agreement__c>> caseIdToSLARecordsMap, List<Service_Level_Agreement__c> slaList) {
        List<Case> casesToUpdate = new List<Case>();

        // Iterate through each Case to update
        for (Case caseToUpdate : caseMap.values()) {
            Decimal slaResolutionTime = 0;
            Decimal slaResponseTime = 0;

            // Check if there are any related SLA records for the current Case
            if (caseIdToSLARecordsMap.containsKey(caseToUpdate.Id)) {
                // Accumulate the SLA times based on the Case status
                for (Service_Level_Agreement__c sla : caseIdToSLARecordsMap.get(caseToUpdate.Id)) {
                    if (sla.Case_Status__c == 'In Progress') {
                        if (sla.Time_Spent__c != null && String.isNotBlank(String.valueOf(sla.Time_Spent__c))) {
                            slaResolutionTime += Decimal.valueOf(sla.Time_Spent__c);
                        }
                    } else if (sla.Case_Status__c == 'Open') {
                        if (sla.Time_Spent__c != null && String.isNotBlank(String.valueOf(sla.Time_Spent__c))) {
                            
                            System.debug('Time Spent ::'+sla.Time_Spent__c);
                            slaResponseTime += Decimal.valueOf(sla.Time_Spent__c);
                        }
                    }
                }
            }

            // Set the accumulated SLA times on the Case
            caseToUpdate.SLA_Resolution_Time__c = slaResolutionTime;
            caseToUpdate.SLA_Response_Time__c = slaResponseTime;

            casesToUpdate.add(caseToUpdate);
        }

        return casesToUpdate;
    }

    // Method to adjust SLA updates for the Cases
    private static List<Case> adjustSLAUpdates(Map<Id, Case> caseMap, Map<Id, List<Service_Level_Agreement__c>> caseIdToSLARecordsMap, List<Service_Level_Agreement__c> slaList) {
        List<Case> casesToUpdate = new List<Case>();

        // Create maps to track the time to remove for each Case
        Map<Id, Decimal> resolutionTimeToRemove = new Map<Id, Decimal>();
        Map<Id, Decimal> responseTimeToRemove = new Map<Id, Decimal>();

        // Iterate through the provided SLA list to determine the time to remove
        for (Service_Level_Agreement__c sla : slaList) {
            if (sla.Case_Id__c != null) {
                if (sla.Case_Status__c == 'In Progress') {
                    if (!resolutionTimeToRemove.containsKey(sla.Case_Id__c)) {
                        resolutionTimeToRemove.put(sla.Case_Id__c, 0);
                    }
                    if (sla.Time_Spent__c != null && String.isNotBlank(String.valueOf(sla.Time_Spent__c))) {
                        resolutionTimeToRemove.put(sla.Case_Id__c, resolutionTimeToRemove.get(sla.Case_Id__c) + Decimal.valueOf(sla.Time_Spent__c));
                    }
                } else if (sla.Case_Status__c == 'Open') {
                    if (!responseTimeToRemove.containsKey(sla.Case_Id__c)) {
                        responseTimeToRemove.put(sla.Case_Id__c, 0);
                    }
                    if (sla.Time_Spent__c != null && String.isNotBlank(String.valueOf(sla.Time_Spent__c))) {
                        responseTimeToRemove.put(sla.Case_Id__c, responseTimeToRemove.get(sla.Case_Id__c) + Decimal.valueOf(sla.Time_Spent__c));
                    }
                }
            }
        }

        // Iterate through each Case to update
        for (Case caseToUpdate : caseMap.values()) {
            Decimal slaResolutionTime = caseToUpdate.SLA_Resolution_Time__c;
            Decimal slaResponseTime = caseToUpdate.SLA_Response_Time__c;

            // Subtract the time to remove from the Case's SLA times
            if (resolutionTimeToRemove.containsKey(caseToUpdate.Id)) {
                slaResolutionTime -= resolutionTimeToRemove.get(caseToUpdate.Id);
            }
            if (responseTimeToRemove.containsKey(caseToUpdate.Id)) {
                slaResponseTime -= responseTimeToRemove.get(caseToUpdate.Id);
            }

            // Set the adjusted SLA times on the Case
            caseToUpdate.SLA_Resolution_Time__c = slaResolutionTime;
            caseToUpdate.SLA_Response_Time__c = slaResponseTime;

            casesToUpdate.add(caseToUpdate);
        }

        return casesToUpdate;
    }

    // Method to update the Cases in the database
    private static void updateCases(List<Case> casesToUpdate) {
        if (!casesToUpdate.isEmpty()) {
            update casesToUpdate;
            System.debug('casesToUpdate ::' +casesToUpdate);
        }
    }
}