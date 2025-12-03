trigger EmailMessageTrigger on EmailMessage (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    new EmailMessageTriggerHandler().run();
}