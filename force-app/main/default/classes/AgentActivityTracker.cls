/*
    AIM: To update last agent activity date for a case.
    - When any field on case is updated by an agent.
    - When an email is sent by an agent.
    - When a feeditem is created by an agent.
*/
public class AgentActivityTracker {
    public static void updateActivityDate(List<SObject> newValues) {
        Id systemAdminProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' Limit 1].Id;
        List<Case> casesToUpdate = new List<Case>();
        Set<Id> caseIds = new Set<Id>();

        if(UserInfo.getProfileId() == systemAdminProfileId || UserInfo.getName() == 'Platform Integration User'){
            return;
        } else {
            for(SObject eachSObject : newValues){
                if(eachSObject.getSObjectType() == Case.getSObjectType()){
                    Case eachCase = (Case)eachSObject;
                    eachCase.Last_activity_date__c = DateTime.now();
                    eachCase.Last_activity_by__c = UserInfo.getUserId();
                } else

                if(eachSObject.getSObjectType() == EmailMessage.getSObjectType()){
                    EmailMessage eachEmailMessage = (EmailMessage)eachSObject;
                    if(eachEmailMessage.ParentId.getSobjectType() == Case.getSObjectType()){
                        caseIds.add(eachEmailMessage.ParentId);
                    }
                } else 

                if(eachSObject.getSObjectType() == FeedItem.getSObjectType()){
                    FeedItem eachFeedItem = (FeedItem)eachSObject;
                    if(eachFeedItem.ParentId.getSobjectType() == Case.getSObjectType()){
                        caseIds.add(eachFeedItem.ParentId);
                    }
                }
            }
        }

        if(!caseIds.isEmpty()){
            for(Case c: [SELECT Id, Last_activity_by__c, Last_activity_date__c FROM Case WHERE Id IN:caseIds]){
                c.Last_activity_by__c = UserInfo.getUserId();
                c.Last_activity_date__c = DateTime.now();
                casesToUpdate.add(c);
            }
        }

        if(casesToUpdate.size()>0){
            update casesToUpdate;
        }
    }
 }