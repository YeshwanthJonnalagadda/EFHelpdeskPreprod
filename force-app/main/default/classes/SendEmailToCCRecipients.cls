public class SendEmailToCCRecipients {
    @InvocableMethod(Label='Send Email to CC Recipients')
    public static void sendEmail(List<String>caseIds){
        //Get cases from the Ids provided
        List<Case> cases = [SELECT Id, CaseNumber, Subject, Description, Case_Description__c, Owner_Full_Name__c, CC__c, Is_an_AMS_Ticket__c, Is_an_BPO_Ticket__c, Is_an_EF_Helpdesk_Record_Type__c  FROM Case WHERE Id in:caseIds];

        //Get owd email address
        OrgWideEmailAddress orgDefaultAddress = [SELECT Id FROM OrgWideEmailAddress WHERE address = 'ef.helpdesk.service.support@ef.com' LIMIT 1];
        OrgWideEmailAddress oracelAMSAddress = [SELECT Id FROM OrgWideEmailAddress WHERE address = 'oracle.ams@ef.com' LIMIT 1];
        OrgWideEmailAddress bpoAddress = [SELECT Id FROM OrgWideEmailAddress WHERE address = 'ef.bpo.service.support@ef.com' LIMIT 1];

        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        
        for(Case eachCase: cases){
            List<String>ccAddresses = eachCase.CC__c.split(',');
            String ownerFullName;
            if(eachCase.Is_an_EF_Helpdesk_Record_Type__c){
                ownerFullName = 'EF Helpdesk';
            } else if(eachCase.Is_an_AMS_Ticket__c){
                ownerFullName = 'Oracle AMS';
            } else if(eachCase.Is_an_BPO_Ticket__c){
                ownerFullName = 'GEC Support Team';
            }

            system.debug('Owner Name :'+ownerFullName);
            String formattedToken = EmailMessages.getFormattedThreadingToken(eachCase.Id);
            String emailSubject = 'Added as CC - '+eachCase.CaseNumber+' - '+eachCase.Subject;

            String emailHTMLBody = 'Hello,<br><br>' +
            'This is to inform you that a new ticket '+eachCase.CaseNumber+' has been created and you have been CC’d for visibility.<br><br>' +
            'Description:<br>' +
            eachCase.Case_Description__c + '<br><br>' +
            'Best Regards,<br>'+ 
            ownerFullName +'<br><br>' + 
            formattedToken;
            system.debug('Body :'+emailHTMLBody); 

            if(eachCase.Is_an_EF_Helpdesk_Record_Type__c){
                emailsToSend.add(emailHelperMethodHtmlBody(eachCase.Id, ccAddresses, orgDefaultAddress.Id, emailSubject, emailHTMLBody));
            } else if(eachCase.Is_an_AMS_Ticket__c){
                emailsToSend.add(emailHelperMethodHtmlBody(eachCase.Id, ccAddresses, oracelAMSAddress.Id, emailSubject, emailHTMLBody));
            } else if(eachCase.Is_an_BPO_Ticket__c){
                emailsToSend.add(emailHelperMethodHtmlBody(eachCase.Id, ccAddresses, bpoAddress.Id, emailSubject, emailHTMLBody));
            }
        }
        system.debug('Number of Emails to Send :'+emailsToSend.size());
        if(emailsToSend.size() > 0){
            Messaging.sendEmail(emailsToSend);
        }
    }   
    //Helper method to create SingleEmailMessage html body.
    private static Messaging.SingleEmailMessage emailHelperMethodHtmlBody(string caseId, List<String> ccAddresses, string fromAddressId, String sub, string body){
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setWhatId(caseId);
        email.setOrgWideEmailAddressId(fromAddressId);
        email.setToAddresses(ccAddresses);
        email.setSaveAsActivity(false);
        email.setSubject(sub);
        email.setHtmlBody(body);

        return email;
    }

}