trigger FeedItemTrigger on FeedItem (after insert) {
    if(trigger.isAfter && trigger.isInsert){
        AgentActivityTracker.updateActivityDate(trigger.new);
    }
}