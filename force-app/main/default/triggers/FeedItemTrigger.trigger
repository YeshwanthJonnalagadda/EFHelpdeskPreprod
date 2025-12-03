trigger FeedItemTrigger on FeedItem (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    new FeedItemTriggerHandler().run();
}