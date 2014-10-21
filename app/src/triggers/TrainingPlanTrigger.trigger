trigger TrainingPlanTrigger on Training_Plan__c (after insert,after update) {

	if(Trigger.isAfter){

		if(Trigger.isInsert){
			TrainingPlansHelper.processAfterInsert(Trigger.newMap);
		}else if(Trigger.isUpdate){
			TrainingPlansHelper.processAfterUpdate(Trigger.oldMap,Trigger.newMap);
		}

	}

}
