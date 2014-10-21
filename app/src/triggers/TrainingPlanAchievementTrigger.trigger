trigger TrainingPlanAchievementTrigger on Training_Plan_Achievement__c (before insert,before update) {

    if(Trigger.isBefore){
        if(Trigger.isInsert){
            TrainingPlanAchievementsHelper.processBeforeInserts(Trigger.new);
        }else if(Trigger.isUpdate){
            TrainingPlanAchievementsHelper.processBeforeUpdates(Trigger.oldMap,Trigger.newMap);
        }
    }

}