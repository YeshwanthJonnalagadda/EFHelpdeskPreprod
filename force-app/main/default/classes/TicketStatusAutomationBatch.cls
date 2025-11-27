public class TicketStatusAutomationBatch implements database.Batchable<sObject>{
    private Id pendingChaserId;
    private Id caseResolvedId;
    private Id caseResolvedAMSId;
    private Id caseResolvedAMSWithSurveyId;
    private Id orgDefaultAddress;
    private Id oracelAMSAddress;
    private Id surveyId;
    private Id networkId;

    public TicketStatusAutomationBatch(){
        //Fetch the email template Id's used for both AMS and Helpdesk tickets
        this.pendingChaserId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Pending_Chase_1730203608751' LIMIT 1].Id;
        this.caseResolvedId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Case_Resolved_Customer_Notification_1731937990245' LIMIT 1].Id;
        this.caseResolvedAMSId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Case_Resolved_Customer_Notification_AMS_1738771845968' LIMIT 1].Id;
        this.caseResolvedAMSWithSurveyId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Case_Resolved_Customer_Notification_AMS_with_survey_1744893104148' LIMIT 1].Id;
        //Fetch Org Wide Email Addresses needed to set FROM address for each template
        this.orgDefaultAddress = [SELECT Id FROM OrgWideEmailAddress WHERE address = 'ef.helpdesk.service.support@ef.com' LIMIT 1].Id;
        this.oracelAMSAddress = [SELECT Id FROM OrgWideEmailAddress WHERE address = 'oracle.ams@ef.com' LIMIT 1].Id;
        //Fetch Survey Id and Network Id
        this.surveyId = [SELECT Id__c FROM customerSurveyRelatedIds__mdt WHERE DeveloperName = 'satisfactionSurveyId' LIMIT 1].Id__c;
        this.networkId = [SELECT Id__c FROM customerSurveyRelatedIds__mdt WHERE DeveloperName = 'networkId' LIMIT 1].Id__c;
    }

    public database.QueryLocator start(database.BatchableContext bc){
        return database.getQueryLocator([SELECT Id, CaseNumber, Subject, ContactId, Status, Next_Action__c, Next_Action_DateTime__c, 
        SuppliedEmail, Is_an_internal_requestor__c, Is_an_EF_Helpdesk_Record_Type__c, Is_an_AMS_Ticket__c, Resolution_Notes__c FROM Case 
        WHERE Is_eligible_for_Ticket_Status_Automation__c = true AND ContactId != Null]);
    }

    public void execute(database.BatchableContext bc, List<Case> scope){
        Map<Id, Case> casesToUpdateMap = new Map<Id, Case>();
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        List<SurveyInvitation> surveyToInsert = new List<SurveyInvitation>();

        for(Case eachCase:scope){
            if(eachCase.Next_Action__c == 'Send Pending Chaser' && eachCase.Status == 'Pending'){                
                emailsToSend.add(emailHelperMethod(eachCase.ContactId, eachCase.Id, pendingChaserId, orgDefaultAddress));
                eachCase.Next_Action__c = 'Status To Resolved';
                casesToUpdateMap.put(eachCase.Id, eachCase);

            } else if(eachCase.Next_Action__c == 'Status To Resolved' && eachCase.Status == 'Pending'){
                if(eachCase.Is_an_EF_Helpdesk_Record_Type__c){
                    emailsToSend.add(emailHelperMethod(eachCase.ContactId, eachCase.Id, caseResolvedId, orgDefaultAddress));
                    eachCase.Status = 'Resolved';
                    casesToUpdateMap.put(eachCase.Id, eachCase);

                } else if(eachCase.Is_an_AMS_Ticket__c){
                    surveyToInsert.add(createSurveyInvitation(eachCase, surveyId, networkId));
                    emailsToSend.add(emailHelperMethod(eachCase.ContactId, eachCase.Id, caseResolvedAMSWithSurveyId, oracelAMSAddress));
                    eachCase.Status = 'Resolved';
                    eachCase.Resolution_Notes__c = 'Auto Resolved';
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