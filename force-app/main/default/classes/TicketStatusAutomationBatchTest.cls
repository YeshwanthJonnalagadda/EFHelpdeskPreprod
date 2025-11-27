@isTest
public class TicketStatusAutomationBatchTest {

    @isTest
    static void testBatchProcess() {
        // Set up test data for Cases
        // Create Contact record
        Contact testContact = new Contact(FirstName = 'Test', LastName = 'User', Email = 'testuser@example.com');
        insert testContact;
        Contact testContact2 = new Contact(FirstName = 'Test', LastName = 'User 2', Email = 'testuser2@ef.com');
        insert testContact2;

        //Get RecordType Id's for Helpdesk and AMS
        Id helpdeskRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'EF_Helpdesk_IT' LIMIT 1].Id;
        Id amsRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'AMS_Ticket' LIMIT 1].Id;

        //get Template Id's
        Id pendingChaserId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Pending_Chase_1730203608751' LIMIT 1].Id;
        Id caseResolvedId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Case_Resolved_Customer_Notification_1731937990245' LIMIT 1].Id;
        Id caseResolvedAMSId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Case_Resolved_Customer_Notification_AMS_1738771845968' LIMIT 1].Id;
        Id caseResolvedAMSWithSurveyId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Case_Resolved_Customer_Notification_AMS_with_survey_1744893104148' LIMIT 1].Id;

        // Org-wide email address Id's
        Id orgDefaultAddress = [SELECT Id FROM OrgWideEmailAddress WHERE address = 'ef.helpdesk.service.support@ef.com' LIMIT 1].Id;
        Id oracelAMSAddress = [SELECT Id FROM OrgWideEmailAddress WHERE address = 'oracle.ams@ef.com' LIMIT 1].Id;
        
        // Survey and Network Id's
        Id surveyId = [SELECT Id__c FROM customerSurveyRelatedIds__mdt WHERE DeveloperName = 'satisfactionSurveyId' LIMIT 1].Id__c;
        Id networkId = [SELECT Id__c FROM customerSurveyRelatedIds__mdt WHERE DeveloperName = 'networkId' LIMIT 1].Id__c;

        // Cases:
        // 1) Pending + Send Pending Chaser -> stays Pending, Next_Action__c -> 'Status To Resolved'
        Case testCase1 = new Case(
            ContactId = testContact.Id,
            Status = 'Pending',
            Next_Action__c = 'Send Pending Chaser',
            Next_Action_DateTime__c = Datetime.now() - 1,
            SuppliedEmail = 'testuser@example.com',
            RecordTypeId = amsRecordTypeId     
        );

        // 2) Pending + Status To Resolved (AMS) -> Resolved, Resolution_Notes__c = 'Auto Resolved', survey created & linked
        Case testCase2 = new Case(
            ContactId = testContact.Id,
            Status = 'Pending',
            Next_Action__c = 'Status To Resolved',
            Next_Action_DateTime__c = Datetime.now() - 1,
            SuppliedEmail = 'testuser@example.com',
            RecordTypeId = amsRecordTypeId
        );

        // 3) Pending + Status To Resolved (Helpdesk) -> Resolved, no survey, no auto notes
        Case testCase3 = new Case(
            ContactId = testContact.Id,
            Status = 'Pending',
            Next_Action__c = 'Status To Resolved',
            Next_Action_DateTime__c = Datetime.now() - 1,
            SuppliedEmail = 'testuser@example.com',
            RecordTypeId = helpdeskRecordTypeId
        );

        // 4) Resolved + Status To Closed -> Closed, clear Next_Action__c and Next_Action_DateTime__c
        Case testCase4 = new Case(
            ContactId = testContact.Id,
            Status = 'Resolved',
            Next_Action__c = 'Status To Closed',
            Next_Action_DateTime__c = Datetime.now() - 1,
            SuppliedEmail = 'testuser@example.com',
            RecordTypeId = amsRecordTypeId
        );

        List<Case> toInsert = new List<Case>{ testCase1, testCase2, testCase3, testCase4 };
        insert toInsert;

        // Set up batch instance
        Test.startTest();
        TicketStatusAutomationBatch batch = new TicketStatusAutomationBatch();
        Database.executeBatch(batch, 5);
        Test.stopTest();

        // Reload the cases with needed fields
        testCase1 = [
            SELECT Id, Status, Next_Action__c, Next_Action_DateTime__c,
                Survey_Invitation__c, Survey_Invitation_Link__c, Resolution_Notes__c,
                Is_an_EF_Helpdesk_Record_Type__c, Is_an_AMS_Ticket__c
            FROM Case WHERE Id = :testCase1.Id
        ];
        testCase2 = [
            SELECT Id, Status, Next_Action__c, Next_Action_DateTime__c,
                Survey_Invitation__c, Survey_Invitation_Link__c, Resolution_Notes__c,
                Is_an_EF_Helpdesk_Record_Type__c, Is_an_AMS_Ticket__c
            FROM Case WHERE Id = :testCase2.Id
        ];
        testCase3 = [
            SELECT Id, Status, Next_Action__c, Next_Action_DateTime__c,
                Survey_Invitation__c, Survey_Invitation_Link__c, Resolution_Notes__c,
                Is_an_EF_Helpdesk_Record_Type__c, Is_an_AMS_Ticket__c
            FROM Case WHERE Id = :testCase3.Id
        ];
        testCase4 = [
            SELECT Id, Status, Next_Action__c, Next_Action_DateTime__c,
                Survey_Invitation__c, Survey_Invitation_Link__c, Resolution_Notes__c,
                Is_an_EF_Helpdesk_Record_Type__c, Is_an_AMS_Ticket__c
            FROM Case WHERE Id = :testCase4.Id
        ];

        // Assertions

        //Case 1: Pending Chaser -> status stays Pending, next action advances
        System.assertEquals('Pending', testCase1.Status, 'Case 1 should remain Pending after sending chaser');
        System.assertEquals('Status To Resolved', testCase1.Next_Action__c, 'Case 1 Next_Action__c should be Status To Resolved');

        // Case 2: AMS -> Resolved, survey + notes
        System.assertEquals('Resolved', testCase2.Status, 'Case 2 (AMS) should be Resolved');
        System.assertEquals('Auto Resolved', testCase2.Resolution_Notes__c, 'Case 2 should have auto resolution notes');
        System.assertNotEquals(null, testCase2.Survey_Invitation__c, 'Case 2 should have Survey Invitation created');
        System.assertNotEquals(null, testCase2.Survey_Invitation_Link__c, 'Case 2 should have Survey Invitation link');

        // Case 3: Helpdesk -> Resolved, no survey, no auto notes
        System.assertEquals('Resolved', testCase3.Status, 'Case 3 (Helpdesk) should be Resolved');
        System.assertEquals(null, testCase3.Survey_Invitation__c, 'Case 3 should not have Survey Invitation');
        System.assertEquals(null, testCase3.Survey_Invitation_Link__c, 'Case 3 should not have Survey Invitation link');
        System.assertEquals(null, testCase3.Resolution_Notes__c, 'Case 3 should not set auto resolution notes');

        // Case 4: Resolved -> Closed, clears follow-up fields
        System.assertEquals('Closed', testCase4.Status, 'Case 4 should be Closed');
        System.assertEquals(null, testCase4.Next_Action__c, 'Case 4 Next_Action__c should be cleared');
        System.assertEquals(null, testCase4.Next_Action_DateTime__c, 'Case 4 Next_Action_DateTime__c should be cleared');
    }
}