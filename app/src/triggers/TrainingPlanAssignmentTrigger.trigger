trigger TrainingPlanAssignmentTrigger on Training_Plan_Assignment__c (after insert,before delete,after update) {
    
    if(Trigger.isBefore){
        if(Trigger.isDelete){
            TrainingPlanAssignmentHelper.processBeforeDelete(Trigger.old);
        }
    }else if(Trigger.isAfter){
    	if(Trigger.isInsert){
    		TrainingPlanAssignmentHelper.processAfterInsert(Trigger.new);
    	}else if(Trigger.isUpdate){
            TrainingPlanAssignmentHelper.processAfterUpdate(Trigger.oldMap,Trigger.newMap);
        }
    }

}