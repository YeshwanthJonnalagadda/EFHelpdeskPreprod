public class EfBpoCaseAssignment{
    @InvocableMethod(label='Initiate Case Assignment Rules' description='Performs case assignment - calling it from screen flow - EF BPO Form Selection') 
    public static void caseAssignmentRules(List<Id> caseIds)
    {
        Database.DMLOptions dmlOption = new Database.DMLOptions();
        dmlOption.assignmentRuleHeader.useDefaultRule= true;         
        Case caseCreated=[select id from Case where id in :caseIds];
        caseCreated.setOptions(dmlOption);
        update caseCreated;
    }
    
    
    /*@AuraEnabled
public static void callApprovalProcess(Id caseId) {
try {
// Fetch Case record
Case caseRecord = [
SELECT Id, EF_BPO_Product__c, EF_BPO_Business_Unit__c
FROM Case
WHERE Id = :caseId
LIMIT 1
];
if (caseRecord == null) {
System.debug('No Case found with the specified ID.');
}

// Get dynamic mappings
EF_BPO_BU_Product_Mapping__c mappingRecord = [
SELECT Business_Unit__c, Product__c, Finance_Manager_Name__c
FROM EF_BPO_BU_Product_Mapping__c
WHERE Business_Unit__c = :caseRecord.EF_BPO_Business_Unit__c
AND Product__c = :caseRecord.EF_BPO_Product__c
LIMIT 1
];
if (mappingRecord == null) {
System.debug('No mapping record found for the specified Business Unit and Product.');
}
if (String.isEmpty(mappingRecord.Finance_Manager_Name__c)) {
System.debug('Finance Manager Name is empty in the mapping record.');
}

// Find Financial Manager
User userRecord = [
SELECT Id, Name
FROM User
WHERE Name = :mappingRecord.Finance_Manager_Name__c
LIMIT 1
];
if (userRecord == null) {
System.debug('No User found with the name: ' + mappingRecord.Finance_Manager_Name__c);
}

// Submit for Approval
Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
req.setObjectId(caseId);
req.setNextApproverIds(new Id[] { userRecord.Id });
req.setComments('Submitting for Approval from Apex');
Approval.ProcessResult result = Approval.process(req);

if (!result.isSuccess()) {
for (Database.Error err : result.getErrors()) {
System.debug('Approval Error: ' + err.getMessage());
}
System.debug('Approval submission failed.');
}
} catch (Exception e) {
System.debug('Error in Approval Process: ' + e.getMessage());
throw e;
}
}
*/    
}