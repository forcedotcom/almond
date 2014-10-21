trigger LearningAssignmentTrigger on Learning_Assignment__c (before insert,before update,before delete,after insert,after update,after undelete, after delete) {

    //Only execute assignments triggers is preview Mode is Off
    if(!LearningAssignmentsHelper.previewMode){
        
        LearningAssignmentsHelper helper = new LearningAssignmentsHelper();
        
        if(Trigger.isBefore){
            if(Trigger.isInsert){
                helper.processBeforeInserts(Trigger.new);
            }else if(Trigger.isUpdate){
                helper.processBeforeUpdates(Trigger.oldMap,Trigger.newMap);
            }else if(Trigger.isDelete){
                helper.processBeforeDeletes(Trigger.old);
            }
        }else if(Trigger.isAfter){
            if(Trigger.isInsert){
                helper.processAfterInserts(Trigger.new);
            }else if(Trigger.isUpdate){
                helper.processAfterUpdates(Trigger.oldMap,Trigger.newMap);
            }else if(Trigger.isUndelete){
                helper.processAfterUnDeletes(Trigger.new);
            }else if(Trigger.isDelete){
                helper.processAfterDeletes(Trigger.old);
            }
        }
    }

}