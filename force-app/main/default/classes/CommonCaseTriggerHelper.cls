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
    
    public static void handleTicketContactRoles(List<Case> newValues, Map<Id,Case> oldValues){

        List<Ticket_Contact_Role__c> newTCRs = new List<Ticket_Contact_Role__c>();
        Set<String> oldTCRNames = new Set<String>();

        for(Case eachCase: newValues){
            if(oldValues == Null){
                if(eachCase.SuppliedEmail != Null){
                    Ticket_Contact_Role__c tcr = new Ticket_Contact_Role__c();
                    tcr.Name = (eachCase.CaseNumber + '-' + eachCase.SuppliedEmail).left(80);
                    tcr.Email__c = eachCase.SuppliedEmail;
                    tcr.Ticket__c = eachCase.Id;
                    tcr.Relationship_Type__c = 'Primary';

                    newTCRs.add(tcr);
                }
                if(eachCase.CC__c != null){
                    Set<String> setCCEmails = new Set<String>();
                    for(String eachEmail : eachCase.CC__c.split(',')){
                        setCCEmails.add(eachEmail.trim());
                    }
                    for(String eachCCEmail:setCCEmails){
                        Ticket_Contact_Role__c tcr = new Ticket_Contact_Role__c();
                        tcr.Name = (eachCase.CaseNumber + '-' + eachCCEmail).left(80);
                        tcr.Email__c = eachCCEmail;
                        tcr.Ticket__c = eachCase.Id;
                        tcr.Relationship_Type__c = 'Secondary';

                        newTCRs.add(tcr);
                    }
                }
            } 
            else if(oldValues != Null){
                if(eachCase.SuppliedEmail != oldValues.get(eachCase.Id).SuppliedEmail){
                    oldTCRNames.add(eachCase.CaseNumber + '-' + oldValues.get(eachCase.Id).SuppliedEmail);

                    if(eachCase.SuppliedEmail != Null){
                        Ticket_Contact_Role__c tcr = new Ticket_Contact_Role__c();
                        tcr.Name = (eachCase.CaseNumber + '-' + eachCase.SuppliedEmail).left(80);
                        tcr.Email__c = eachCase.SuppliedEmail;
                        tcr.Ticket__c = eachCase.Id;
                        tcr.Relationship_Type__c = 'Primary'; 

                        newTCRs.add(tcr);
                    }
                }
                if(eachCase.CC__C != oldValues.get(eachCase.Id).CC__c){
                    if(oldValues.get(eachCase.Id).CC__c != Null){
                        for(String eachEmail : oldValues.get(eachCase.Id).CC__c.split(',')){
                            oldTCRNames.add(eachCase.CaseNumber + '-' + eachEmail.trim());
                        }
                    }
                    
                    if(eachCase.CC__c != Null){
                        Set<String> setCCEmails = new Set<String>();
                        for(String eachEmail : eachCase.CC__c.split(',')){
                            setCCEmails.add(eachEmail.trim());
                        }
                        for(String eachCCEmail:setCCEmails){
                            Ticket_Contact_Role__c tcr = new Ticket_Contact_Role__c();
                            tcr.Name = (eachCase.CaseNumber + '-' + eachCCEmail).left(80);
                            tcr.Email__c = eachCCEmail;
                            tcr.Ticket__c = eachCase.Id;
                            tcr.Relationship_Type__c = 'Secondary';

                            newTCRs.add(tcr);
                    }
                    }
                }
            }
        }

        List<Ticket_Contact_Role__c> oldTCRs = [SELECT Id FROM Ticket_Contact_Role__c WHERE Name IN:oldTCRNames];

        if(oldTCRs.size() > 0){
            delete oldTCRs;
        }

        if(newTCRs.size() > 0){
            insert newTCRs;
        }
    }
    
    //Helper method to calculate next action date
    private static Datetime calculateNextActionDateHelper(String id, Datetime start, Integer days){
        Datetime nextReminderDate = BusinessHours.add(Id, start, days*24*60*60*1000);
        return nextReminderDate;
    }

}