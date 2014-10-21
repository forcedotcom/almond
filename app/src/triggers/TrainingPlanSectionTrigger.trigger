trigger TrainingPlanSectionTrigger on Training_Plan_Section__c (before update) {

	if(Trigger.isBefore){
		
		if(Trigger.isUpdate){
			TrainingPlanSectionsHelper.processBeforeUpdate(Trigger.oldMap,Trigger.newMap);
		}
		
	}

}