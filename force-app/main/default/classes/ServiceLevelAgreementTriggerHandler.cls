
public class ServiceLevelAgreementTriggerHandler extends TriggerHandler{

    public override void beforeUpdate() {
        ServiceLevelAgreementTriggerHelper.timeSpent((List<Service_Level_Agreement__c>)Trigger.new);
    }
    
}