trigger EmailMessageTrigger on EmailMessage (after insert) {
    if(trigger.isAfter && trigger.isInsert){
        AgentActivityTracker.updateActivityDate(trigger.new);
    }

}