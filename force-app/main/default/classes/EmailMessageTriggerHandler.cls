public class EmailMessageTriggerHandler extends TriggerHandler {
    public override void afterInsert() {
        AgentActivityTracker.updateActivityDate(Trigger.new);
    }
}