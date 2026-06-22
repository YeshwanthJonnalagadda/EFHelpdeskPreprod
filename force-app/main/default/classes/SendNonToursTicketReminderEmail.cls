/*
*   AIM: To send the reminder to on Pending non Tours tickets.
*/

public class SendNonToursTicketReminderEmail implements Database.Batchable<SObject> {
    private Map<string, OrgWideEmailAddress> orgWideEmailAddressesMap = new Map<string, OrgWideEmailAddress>();
    private Map<string, string> companyCodeFMEmailMap = new Map<string, string>();
    //private string gpoEmailAddress;

    public SendNonToursTicketReminderEmail(){
        for(OrgWideEmailAddress eachAddress: [SELECT Id, Address FROM OrgWideEmailAddress]){
            this.orgWideEmailAddressesMap.put(eachAddress.Address, eachAddress);
        }
        for(EF_BPO_BU_Product_Mapping__c eachBUMapping: [SELECT Id, Business_Unit__c, Finance_Manager_Email__c FROM EF_BPO_BU_Product_Mapping__c WHERE Business_Unit__c != NULL]){
            this.companyCodeFMEmailMap.put(eachBUMapping.Business_Unit__c, eachBUMapping.Finance_Manager_Email__c);
        }
        /* commented out as they no longer GPO in reminders
        S2P_GPO_Setting__mdt gpo = 	S2P_GPO_Setting__mdt.getInstance('Default');
        this.gpoEmailAddress = gpo.Email__c;
        */

    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id, SuppliedEmail, ContactId, Subject, CaseNumber, First_Name_Auto_Response__c, Agents_First_Name__c,
                                        EF_BPO_Reminder_Date__c, EF_BPO_Reminder_Number__c, ContactEmail, Approver__r.Email, EF_BPO_Business_Unit__c
                                        FROM Case WHERE EF_BPO_Is_eligible_for_nontours_reminder__c = true]);
    }

    public void execute(Database.BatchableContext bContext, List<Case>cases){
        //Construct caseIds List from case List
        List<String>caseIds = new List<String>();
        for(Case c:cases){
            caseIds.add(c.Id);
        }
        List<EmailMessage> allEmailMessages = [SELECT Id, ParentId, CcAddress, ToAddress, FromAddress, 
                                                CreatedDate, HtmlBody, TextBody, Subject FROM EmailMessage 
                                                WHERE ParentId IN:caseIds];

        //Construct caseIdToEmailListMap
        Map<String, List<EmailMessage>> caseIdToEmailListMap = new Map<String, List<EmailMessage>>();
        if(allEmailMessages.size()>0){
            for(EmailMessage eachEmailMessage: allEmailMessages){
                if(!caseIdToEmailListMap.containsKey(eachEmailMessage.ParentId)){
                    caseIdToEmailListMap.put(eachEmailMessage.ParentId, new List<EmailMessage>{eachEmailMessage});
                }
                caseIdToEmailListMap.get(eachEmailMessage.ParentId).add(eachEmailMessage);
            }
        }

        //Sort the emailList by createdDate
        Map<String, List<EmailMessage>> sortedcaseIdToEmailListMap = new Map<String, List<EmailMessage>>();
        for(String caseId:caseIdToEmailListMap.keySet()){
            List<EmailMessage> emailList = caseIdToEmailListMap.get(caseId);
            emailList.sort(new EmailMessageCreatedDateComparator());
            sortedcaseIdToEmailListMap.put(caseId, emailList);
        }
        
        List<String> ccAddressList = new List<String>();
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        List<Case> casesToUpdate = new List<Case>();
        for(Case eachCase: cases){
            Id fromAddressId = orgWideEmailAddressesMap.get('ef.bpo.service.support@ef.com').Id;
            String fmEamilAddress = companyCodeFMEmailMap.get(eachCase.EF_BPO_Business_Unit__c);
            string agentsName = eachCase.Agents_First_Name__c <> Null ? eachCase.Agents_First_Name__c : 'GEC Support Team';
            ccAddressList.add(fmEamilAddress);
            /* commented out as they no longer GPO in reminders
            if(eachCase.EF_BPO_Reminder_Number__c == 3){
                ccAddressList.add(gpoEmailAddress);
            }
            */
            String threadToken = EmailMessages.getFormattedThreadingToken(eachCase.Id);
            EmailMessage latestEmail = sortedcaseIdToEmailListMap.get(eachCase.Id)[sortedcaseIdToEmailListMap.get(eachCase.Id).size()-1];
            String subject  =   'Auto reminder '+eachCase.EF_BPO_Reminder_Number__c+': '+eachCase.CaseNumber+' - '+eachCase.Subject;
            String htmlBody =   '<br/>Dear '+eachCase.First_Name_Auto_Response__c+',<br/>' + 
                                '<br/>We are writing to following up on request '+eachCase.CaseNumber+'.<br/>' +
                                '<br/>We would appreciate if you could provide an update or let us know if any further information is needed from our side to assist with resolution.<br/>' +
                                '<br/>Looking forward to your response.<br/><br/>' +
                                'Thanks,<br/>' +
                                +agentsName+'<br/>' +
                                '<br/>' +
                                '--------------------------------------------------Original Email -----------------------------------------------------------<br/><br/>' +
                                '<b>From: </b>'+latestEmail.FromAddress+'<br/>' +
                                '<b>Sent: </b>'+latestEmail.CreatedDate+'<br/>' +
                                '<b>To: </b>'+latestEmail.ToAddress+'<br/>' +
                                '<b>Subject: </b>'+latestEmail.Subject+'<br /><br/>' +
                                +latestEmail.HtmlBody+'<br/>'+
                                +threadToken;
            
            //Contrust Email Message
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.setWhatId(eachCase.Id);
            message.setOrgWideEmailAddressId(fromAddressId);
            message.setToAddresses(new List<String>{eachCase.ContactEmail});
            if(ccAddressList.size()>0){
                message.setCcAddresses(ccAddressList);
            }
            message.setSaveAsActivity(true);
            message.setHtmlBody(htmlBody);
            message.setSubject(subject);
            message.setTargetObjectId(eachCase.ContactId);

            emailList.add(message);

            if(eachCase.EF_BPO_Reminder_Number__c == 3){
                eachCase.EF_BPO_Reminders_Complete__c = true;
            }

            eachCase.EF_BPO_Reminder_Number__c = eachCase.EF_BPO_Reminder_Number__c < 3 ? eachCase.EF_BPO_Reminder_Number__c + 1 : Null;
            eachCase.EF_BPO_Reminder_Date__c = eachCase.EF_BPO_Reminder_Number__c <= 3 ? Datetime.now() + 3 : Null;
            
            casesToUpdate.add(eachCase);
        }

        //Send Email messages
        if(emailList.size() > 0){
            Messaging.sendEmail(emailList);
        }
        //Update Cases
        if(casesToUpdate.size()>0){
            update casesToUpdate;
        }
    }

    public void finish(Database.BatchableContext bc){
        system.debug('execute any post-processing operations');
    }

    //InnerClass
    public class EmailMessageCreatedDateComparator implements Comparator<EmailMessage> {
        public Integer compare(EmailMessage em1, EmailMessage em2) {
            if(em1.CreatedDate < em2.CreatedDate){
                return -1;
            }if(em1.CreatedDate > em2.CreatedDate){
                return 1;
            }
            return 0;
        }
    }
}