public class InvokeCaseAssignmentRules {
    @InvocableMethod(Label='Invoke Case Assignment Rule')
    public static void invokeRule(List<Id> caseIds){
        List<Case> createdCases = [SELECT Id FROM Case WHERE Id in:caseIds];
        
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule= true;
        
        List<Case> listToUpdate = new List<Case>();
        
        for(Case eachCase: createdCases){
            eachCase.setOptions(dmo);
            listToUpdate.add(eachCase);                 
        }
        
        update listToUpdate;        
    }

}