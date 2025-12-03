@isTest
private class TriggerHandlerTest {

    private static TriggerHandler handler = new TriggerHandler();

    @isTest
    static void testBeforeInsert() {
        handler.setTriggerContext('BEFORE_INSERT', true);
        handler.run();
    }

    @isTest
    static void testAfterInsert() {
        handler.setTriggerContext('AFTER_INSERT', true);
        handler.run();
    }

    @isTest
    static void testBeforeUpdate() {
        handler.setTriggerContext('BEFORE_UPDATE', true);
        handler.run();
    }

    @isTest
    static void testAfterUpdate() {
        handler.setTriggerContext('AFTER_UPDATE', true);
        handler.run();
    }

    @isTest
    static void testBeforeDelete() {
        handler.setTriggerContext('BEFORE_DELETE', true);
        handler.run();
    }

    @isTest
    static void testAfterDelete() {
        handler.setTriggerContext('AFTER_DELETE', true);
        handler.run();
    }

    @isTest
    static void testAfterUndelete() {
        handler.setTriggerContext('AFTER_UNDELETE', true);
        handler.run();
    }

    //test method for simulating real trigger
    @isTest
    static void simulatingRealTrigger() {

        Case case1 = new Case();
        case1.Origin = 'Bot';
        case1.Status = 'New';
        case1.Priority = 'Medium';
        insert case1;

        FeedItem feedItem1 = new FeedItem();
        feedItem1.ParentId = case1.Id;
        feedItem1.Body = 'test';
        insert feedItem1;
    }
        
}