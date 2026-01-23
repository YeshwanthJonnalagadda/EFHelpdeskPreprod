/*
*   AIM: To send the reminder to on Hold Atlas tickets. 
*   include all the addresses from initial email on case. 
*   inaddition to supplied email.
*/


public class SendAtlasTicketReminderEmail implements Database.Batchable<Sobject> {

    private List<EmailRoutingAddress> emailRoutingAddresses = new List<EmailRoutingAddress>();
    private Id bpoAddress;
    private Id templateId;

    public SendAtlasTicketReminderEmail(){
        this.emailRoutingAddresses = [SELECT Id, address FROM EmailRoutingAddress];
        this.bpoAddress = [SELECT Id FROM OrgWideEmailAddress WHERE address = 'ef.bpo.service.support@ef.com' LIMIT 1].Id;
        this.templateId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'EF_BPO_reminder_for_On_Hold_tours_Tickets_1749555977479' LIMIT 1].Id;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id, SuppliedEmail, ContactId, Subject, CaseNumber, First_Name_Auto_Response__c, 
                                        Is_an_internal_requestor__c, EF_BPO_Reminder_Date__c, EF_BPO_Reminder_Number__c FROM Case 
                                        WHERE EF_BPO_Is_eligible_for_reminder__c = true]);
    }

    public void execute(Database.BatchableContext bContext, List<Case>cases){
        //Construct caseIds List from case List
        List<String>caseIds = new List<String>();
        for(Case c:cases){
            caseIds.add(c.Id);
        }
        List<EmailMessage> allEmailMessages = [SELECT Id, ParentId, CcAddress, ToAddress, CreatedDate FROM EmailMessage 
                                                WHERE ParentId IN:caseIds];
        
        //Contruct emailRoutingAddress Set
        Set<String> emailRoutingAddressesSet = new Set<String>();
        for(EmailRoutingAddress eachEmailRoutingAddress: emailRoutingAddresses){
            emailRoutingAddressesSet.add(eachEmailRoutingAddress.Address.toLowerCase());
        }
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

        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        List<Case> casesToUpdate = new List<Case>();
        for(Case eachCase: cases){
            Set<String> ccAddressSet = new Set<String>();
            Set<String> toAddressSet = new Set<String>();
            List<String> ccAddressList = new List<String>();
            List<String> toAddressList = new List<String>();
            if(eachCase.SuppliedEmail != Null && eachCase.ContactId != Null){                
                if(sortedcaseIdToEmailListMap.containsKey(eachCase.Id) && sortedcaseIdToEmailListMap.get(eachCase.Id).size()>0 && eachCase.Is_an_internal_requestor__c == 'TRUE'){
                    toAddressSet.addAll(sortedcaseIdToEmailListMap.get(eachCase.Id)[0].ToAddress != null ? new List<String>(sortedcaseIdToEmailListMap.get(eachCase.Id)[0].ToAddress.split(';')) : new List<String>());
                    ccAddressSet.addAll(sortedcaseIdToEmailListMap.get(eachCase.Id)[0].CcAddress != null ? new List<String>(sortedcaseIdToEmailListMap.get(eachCase.Id)[0].CcAddress.split(';')) : new List<String>());
                }else if(sortedcaseIdToEmailListMap.containsKey(eachCase.Id) && sortedcaseIdToEmailListMap.get(eachCase.Id).size()>0 && eachCase.Is_an_internal_requestor__c == 'FALSE'){
                    ccAddressSet.addAll(sortedcaseIdToEmailListMap.get(eachCase.Id)[0].ToAddress != null ? new List<String>(sortedcaseIdToEmailListMap.get(eachCase.Id)[0].ToAddress.split(';')) : new List<String>());
                    ccAddressSet.addAll(sortedcaseIdToEmailListMap.get(eachCase.Id)[0].CcAddress != null ? new List<String>(sortedcaseIdToEmailListMap.get(eachCase.Id)[0].CcAddress.split(';')) : new List<String>());
                }
                //remove routing address from set
                for(String eachCCAdress: ccAddressSet){
                    if(!emailRoutingAddressesSet.contains(eachCCAdress.trim().toLowerCase())){
                        ccAddressList.add(eachCCAdress.trim());
                    }
                }
                //remove routing address from set
                for(String eachToAdress: toAddressSet){
                    if(!emailRoutingAddressesSet.contains(eachToAdress.trim().toLowerCase())){
                        toAddressList.add(eachToAdress.trim());
                    }
                }
                
                //check for empty recipient list
                if(toAddressList.size()>0 || ccAddressList.size()>0){
                    //Contrust Email Message
                    Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                    message.setWhatId(eachCase.Id);
                    message.setOrgWideEmailAddressId(bpoAddress);
                    message.setToAddresses(toAddressList);
                    message.setCcAddresses(ccAddressList);
                    message.setSaveAsActivity(false);
                    message.setTemplateId(templateId);
                    message.setTargetObjectId(eachCase.ContactId);

                    emailList.add(message);
                }
                
                eachCase.EF_BPO_Reminder_Number__c = eachCase.EF_BPO_Reminder_Number__c < 3 ? eachCase.EF_BPO_Reminder_Number__c + 1 : Null;
                eachCase.EF_BPO_Reminder_Date__c = eachCase.EF_BPO_Reminder_Number__c < 3 ? Datetime.now() + 7 : Null;
            
                casesToUpdate.add(eachCase);
            }
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