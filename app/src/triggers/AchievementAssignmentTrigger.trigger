trigger AchievementAssignmentTrigger on Achievement_Assignment__c (after update) {

    //Only execute assignments triggers is preview Mode is Off
    if(!LearningAssignmentsHelper.previewMode){

        AchievementAssignmentsHelper helper = new AchievementAssignmentsHelper();

        if(Trigger.isAfter){
            if(Trigger.isUpdate){
                helper.processAfterUpdates(Trigger.oldMap,Trigger.newMap);
            }
        }
    }

}
