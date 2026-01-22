public class TicketStatusAutomationBatch implements database.Batchable<sObject>{

    private Map<String, Ticket_Status_Template_Setting__mdt> recordTypeToNextActionTSTSMap = new Map<String, Ticket_Status_Template_Setting__mdt>();

    public TicketStatusAutomationBatch(){
        for(Ticket_Status_Template_Setting__mdt tsts: [SELECT Id, Record_Type__c, Next_Action__c, Org_Wide_Email_Address_Id__c, Template_Id__c, 
                                                                Network_Id__c, Survey_Id__c FROM Ticket_Status_Template_Setting__mdt]){
            this.recordTypeToNextActionTSTSMap.put(tsts.Record_Type__c+'-'+tsts.Next_Action__c, tsts);
        }
    }

    public database.QueryLocator start(database.BatchableContext bc){
       
        return database.getQueryLocator([SELECT Id, CaseNumber, Subject, ContactId, Status, Next_Action__c, Next_Action_DateTime__c, 
        SuppliedEmail, Is_an_EF_Helpdesk_Record_Type__c, Is_an_AMS_Ticket__c, Resolution_Notes__c, RecordType.DeveloperName FROM Case 
        WHERE Is_eligible_for_Ticket_Status_Automation__c = true]);
    }

    public void execute(database.BatchableContext bc, List<Case> scope){
        Map<Id, Case> casesToUpdateMap = new Map<Id, Case>();
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        List<SurveyInvitation> surveyToInsert = new List<SurveyInvitation>();

        for(Case eachCase:scope){
            if(eachCase.Next_Action__c == 'Send Pending Chaser' && eachCase.Status == 'Pending'){

                if(recordTypeToNextActionTSTSMap.containsKey(eachCase.RecordType.DeveloperName+'-'+eachCase.Next_Action__c)){
                    Ticket_Status_Template_Setting__mdt tsts = recordTypeToNextActionTSTSMap.get(eachCase.RecordType.DeveloperName+'-'+eachCase.Next_Action__c);
                    emailsToSend.add(emailHelperMethod(eachCase.ContactId, eachCase.Id, tsts.Template_Id__c, tsts.Org_Wide_Email_Address_Id__c));
                    eachCase.Next_Action__c = 'Status To Resolved';
                    casesToUpdateMap.put(eachCase.Id, eachCase);
                }                
                

            } else if(eachCase.Next_Action__c == 'Status To Resolved' && eachCase.Status == 'Pending'){
                
                if(recordTypeToNextActionTSTSMap.containsKey(eachCase.RecordType.DeveloperName+'-'+eachCase.Next_Action__c)){
                    Ticket_Status_Template_Setting__mdt tsts = recordTypeToNextActionTSTSMap.get(eachCase.RecordType.DeveloperName+'-'+eachCase.Next_Action__c);
                    if(tsts.Survey_Id__c != null && tsts.Network_Id__c != null){
                        surveyToInsert.add(createSurveyInvitation(eachCase, tsts.Survey_Id__c, tsts.Network_Id__c));
                    }
                    emailsToSend.add(emailHelperMethod(eachCase.ContactId, eachCase.Id, tsts.Template_Id__c, tsts.Org_Wide_Email_Address_Id__c));
                    eachCase.Status = 'Resolved';
                    eachCase.Resolution_Notes__c = eachCase.Is_an_AMS_Ticket__c ? 'Auto Resolved' : eachCase.Resolution_Notes__c;
                    casesToUpdateMap.put(eachCase.Id, eachCase);
                }

            } else if(eachCase.Next_Action__c == 'Status To Closed' && eachCase.Status == 'Resolved'){
                eachCase.Status = 'Closed';
                eachCase.Next_Action__c = Null;
                eachCase.Next_Action_DateTime__c = Null;
                casesToUpdateMap.put(eachCase.Id, eachCase);
            }
        }

        if(surveyToInsert.size() >0){
            insert surveyToInsert;

            Map<String, SurveyInvitation> insertedSurveyMap = new Map<String, SurveyInvitation>();
            for(SurveyInvitation es:surveyToInsert){
                insertedSurveyMap.put(es.Id, es);
            }
            //InvitationLink field is a formula field that is populated asynchronously
            //So retrieve the inserted survey invitations
            List<SurveyInvitation> insertedSurveys = [SELECT Id, InvitationLink, Ticket__c FROM SurveyInvitation WHERE Id IN:insertedSurveyMap.keySet()];

            for(SurveyInvitation eachSurvey: insertedSurveys){
                if(casesToUpdateMap.containsKey(eachSurvey.Ticket__c)){
                    casesToUpdateMap.get(eachSurvey.Ticket__c).Survey_Invitation__c = eachSurvey.Id;
                    casesToUpdateMap.get(eachSurvey.Ticket__c).Survey_Invitation_Link__c = eachSurvey.InvitationLink;
                }
            }
        }

        if(casesToUpdateMap.size() > 0){
            update casesToUpdateMap.values();
        }

        if(emailsToSend.size() > 0){
            Messaging.sendEmail(emailsToSend);
        }
    }

    //Helper methods
    public static Messaging.SingleEmailMessage emailHelperMethod(string conId, string caseId, string tempId, string fromAddressId){
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setTargetObjectId(conId);
        email.setWhatId(caseId);
        email.setTemplateId(tempId);
        email.setOrgWideEmailAddressId(fromAddressId);
        email.setSaveAsActivity(false);

        return email;
    }

    public static SurveyInvitation createSurveyInvitation(Case c, String surveyId, String networkId){
        SurveyInvitation newSV = new SurveyInvitation();
        newSV.SurveyId = surveyId;
        newSV.CommunityId = networkId;
        newSV.ParticipantId = c.ContactId;
        newSV.OptionsAllowGuestUserResponse = true;
        newSV.Ticket__c = c.Id;
        newSV.Name = c.CaseNumber + ' - ' + c.Subject;
        
        return newSV;
    }

    public void finish(Database.BatchableContext bc){
        system.debug('execute any post-processing operation');
    }
}