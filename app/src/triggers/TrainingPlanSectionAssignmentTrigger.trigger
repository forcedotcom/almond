trigger TrainingPlanSectionAssignmentTrigger on Training_Plan_Section_Assignment__c (before delete,after delete,after update) {

    if(Trigger.isBefore){
        if(Trigger.isDelete){
            TrainingPlanSectionAssignmentHelper.processBeforeDelete(Trigger.old);   
        }
    }else if(Trigger.isAfter){
        
        if(Trigger.isUpdate){
            TrainingPlanSectionAssignmentHelper.processAfterUpdate(Trigger.oldMap,Trigger.newMap);
        }else if(Trigger.isDelete){
            TrainingPlanSectionAssignmentHelper.processAfterDelete(Trigger.old);   
        }
    }

}