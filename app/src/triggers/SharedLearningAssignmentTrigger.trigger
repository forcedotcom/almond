trigger SharedLearningAssignmentTrigger on Shared_Learning_Assignment__c (after update) {

    if(Trigger.isAfter && Trigger.isUpdate){
        SharedLearningAssignmentsHelper.processAfterUpdate(Trigger.oldMap,Trigger.newMap);
    }
}