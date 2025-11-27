public class TicketHistoryHandler {

    public static void trackTicketFieldChanges(List<Case> newCases, Map<Id, Case> oldCasesMap) {
        List<Ticket_History__c> ticketHistories = new List<Ticket_History__c>();

        for (Case newCase : newCases) {
            Case oldCase = oldCasesMap.get(newCase.Id);

            // Call method to get changed fields
            List<Ticket_History__c> histories = getFieldChanges(newCase, oldCase);
            ticketHistories.addAll(histories);
        }

        // Insert history records if any
        if (!ticketHistories.isEmpty()) {
            insert ticketHistories;
        }
    }

    private static List<Ticket_History__c> getFieldChanges(Case newCase, Case oldCase) {
        List<Ticket_History__c> histories = new List<Ticket_History__c>();

        // Iterate over all fields to compare old and new values
        Map<String, Schema.SObjectField> fields = Case.SObjectType.getDescribe().fields.getMap();
        for (Schema.SObjectField field : fields.values()) {
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
            String fieldName = fieldDescribe.getName();
            Object newValue = newCase.get(fieldName);
            Object oldValue = oldCase.get(fieldName);

            // Format field values
            String newValueStr = formatFieldValue(newValue);
            String oldValueStr = formatFieldValue(oldValue);

            // Add record to histories if there is a change
            if (hasFieldChanged(newValueStr, oldValueStr)) {
                histories.add(createHistoryRecord(newCase.Id, fieldDescribe.getLabel(), oldValueStr, newValueStr));
            }
        }
        return histories;
    }

    private static Boolean hasFieldChanged(String newValue, String oldValue) {
        // Check if values are different or if one of them is null
        return (newValue != null && !newValue.equals(oldValue)) || (oldValue != null && !oldValue.equals(newValue));
    }

    private static String formatFieldValue(Object value) {
        if (value == null) return null;

        // Convert value to string and strip HTML tags
        String stringValue = String.valueOf(value);
        return stripHtmlTags(stringValue);
    }

    private static String stripHtmlTags(String html) {
        // Use a regular expression to remove HTML tags
        return html.replaceAll('<[^>]*>', '');
    }

    private static Ticket_History__c createHistoryRecord(Id caseId, String fieldName, String oldValue, String newValue) {
        Ticket_History__c history = new Ticket_History__c();
        history.Ticket__c = caseId;
        history.Field_Name__c = fieldName;
        history.Old_Value__c = oldValue;
        history.New_Value__c = newValue;
        history.Changed_By__c = UserInfo.getUserId();
        history.Changed_Date__c = System.now();
        return history;
    }
}