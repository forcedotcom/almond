/*
Copyright (c) 2014, salesforce.com, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
    this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.
    * Neither the name of the salesforce.com, Inc. nor the names of its contributors
    may be used to endorse or promote products derived from this software
    without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
OF THE POSSIBILITY OF SUCH DAMAGE.

*/
public with sharing class TrainingPlanSectionAssignmentHelper{

    public static Set<Id> deletedTrainingPlanAssignments;

    public static void processBeforeDelete(List<Training_Plan_Section_Assignment__c> assignments){
        deleteAssociatedLearningAssignments(assignments);
    }

    public static void processAfterDelete(List<Training_Plan_Section_Assignment__c> assignments){
        updateRelatedTrainingPlanAssignments(assignments);
    }

    public static void processAfterUpdate(Map<Id,Training_Plan_Section_Assignment__c> oldAssignmentsMap,Map<Id,Training_Plan_Section_Assignment__c> newAssignmentsMap){
        processAchievementRulesForAssignments(oldAssignmentsMap,newAssignmentsMap);
    }

    //This method deletes all learning assignments associated to the specified section assignments
    public static void deleteAssociatedLearningAssignments(List<Training_Plan_Section_Assignment__c> assignments){
        TrainingPlanSectionAssignmentHelper.WithoutSharingOps wosHelper = new TrainingPlanSectionAssignmentHelper.WithoutSharingOps();
        wosHelper.deleteAssociatedLearningAssignmentsWOS(assignments);
    }

    //This method recalculates progress at the training plan level for the users related to the specified assignments
    public static void updateRelatedTrainingPlanAssignments(List<Training_Plan_Section_Assignment__c> assignments){

        Set<Id> relatedTPlanSections = new Set<Id>();
        Set<Id> relatedTPlans = new Set<Id>();
        Set<Id> relatedUsers = new Set<Id>();

        //Create a set with related sections and user info
        for(Training_Plan_Section_Assignment__c tpsa : assignments){
            if(tpsa.Training_Plan_Section__c != null && tpsa.User__c != null){

                if(deletedTrainingPlanAssignments == null || (deletedTrainingPlanAssignments != null && !deletedTrainingPlanAssignments.contains(tpsa.Training_Plan_Assignment__c))){
                    relatedTPlanSections.add(tpsa.Training_Plan_Section__c);
                    relatedUsers.add(tpsa.User__c);
                }
            }
        }

        //Filter inactive users
        Set<Id> activeUserIds = new Set<Id>();
        for(User u : [select id from User where id in :relatedUsers and IsActive = true]){
            activeUserIds.add(u.Id);
        }
        relatedUsers = activeUserIds;

        if(relatedTPlanSections.size()>0){
            //Fetch additional information for the related training plan sections
            for(Training_Plan_Section__c tps : [select id
                                                        ,Training_Plan__c
                                                        from Training_Plan_Section__c
                                                        where id in :relatedTPlanSections]){
                if(tps.Training_Plan__c  != null){
                    relatedTPlans.add(tps.Training_Plan__c);
                }
            }
        }

        if(relatedTPlans.size()>0 && relatedUsers.size()>0){
            // Will update progress using without sharing
            LearningAssignmentsHelper.updateTrainingPlanAssignments(relatedTPlans,relatedUsers);
        }

    }

    //This method evaluates completed section assignments and updates related AA records status
    private static void processAchievementRulesForAssignments(Map<Id,Training_Plan_Section_Assignment__c> oldAssignmentsMap,Map<Id,Training_Plan_Section_Assignment__c> newAssignmentsMap){

        TrainingPlanSectionAssignmentHelper.WithoutSharingOps wosHelper = new TrainingPlanSectionAssignmentHelper.WithoutSharingOps();

        //Auxiliary collections
        Set<Id> sectionIds = new Set<Id>();
        Set<Id> trainingPlanAchievementIds = new Set<Id>();
        List<Achievement_Assignment__c> achievementAssignmentsToUpdate = new List<Achievement_Assignment__c>();

        List<Training_Plan_Section_Assignment__c> completedAssignments = new List<Training_Plan_Section_Assignment__c>();
        Map<Id,List<Training_Plan_Section_Assignment__c>> completedAssignmentsPerUser = new Map<Id,List<Training_Plan_Section_Assignment__c>>();

        //Get section ids for assignments and separate completed assignments
        for(Training_Plan_Section_Assignment__c tpsa : newAssignmentsMap.values()){

            Training_Plan_Section_Assignment__c oldTpsa = oldAssignmentsMap.get(tpsa.Id);
            if(tpsa.User__c != null && tpsa.Training_Plan_Section__c != null){
                if(oldTpsa.Status__c != LMSConstants.ASSIGNMENT_STATUS_COMPLETED && tpsa.Status__c == LMSConstants.ASSIGNMENT_STATUS_COMPLETED){

                    if(!completedAssignmentsPerUser.containsKey(tpsa.User__c)){
                        completedAssignmentsPerUser.put(tpsa.User__c,new List<Training_Plan_Section_Assignment__c>());
                    }

                    completedAssignmentsPerUser.get(tpsa.User__c).add(tpsa);
                    sectionIds.add(tpsa.Training_Plan_Section__c);
                    completedAssignments.add(tpsa);
                }
            }
        }

        //Continue only if there are completed assignments
        if(completedAssignments.size()>0){

            //Get training plan achievements for the sections
            Map<Id,List<Training_Plan_Achievement__c>> sectionAchievementsMap = wosHelper.getTrainingPlanSectionAchievementsWOS(sectionIds);

            for(Id sId : sectionAchievementsMap.keySet()){
                for(Training_Plan_Achievement__c tpa : sectionAchievementsMap.get(sId)){
                    trainingPlanAchievementIds.add(tpa.Id);
                }
            }

            //We have achievements related to the completed sections, continue analysis
            if(trainingPlanAchievementIds != null && trainingPlanAchievementIds.size()>0){

                //Get AA records for the users + training plan achievements
                Map<String,List<Achievement_Assignment__c>> userSectionAchievementAssignments = LMSService.getAchievementAssignmentforTrainingPlanAchievements(completedAssignmentsPerUser.keySet(),trainingPlanAchievementIds);

                //Iterate over completed assignments and update corresponding achievement assignment records
                for(Training_Plan_Section_Assignment__c tpsa : completedAssignments){
                    List<Achievement_Assignment__c> aas = userSectionAchievementAssignments.get(tpsa.User__c+'_'+tpsa.Training_Plan_Section__c);
                    if(aas != null){
                        for(Achievement_Assignment__c aa : aas){
                            if(aa.Achievement__r.Override_Completed_Status__c != null){
                                aa.Status__c = aa.Achievement__r.Override_Completed_Status__c;
                            }else{
                                aa.Status__c = LMSConstants.AA_ACQUIRED_STATUS;
                            }
                            achievementAssignmentsToUpdate.add(aa);
                        }
                    }
                }
            }

            //Update AA records
            if(achievementAssignmentsToUpdate.size()>0){
                wosHelper.updateAchievementAssignmentRecordsWOS(achievementAssignmentsToUpdate);
            }

        }

    }

    public without sharing class WithoutSharingOps{

        // We want to make sure we don't leave flying records if the running user doesn't have access to the associated learning assingments
        public void deleteAssociatedLearningAssignmentsWOS(List<Training_Plan_Section_Assignment__c> assignments){

            //BEGIN Access Check
            List<Schema.sObjectType> objectTypesToDelete = new List<Schema.sObjectType>();
            objectTypesToDelete.add(Learning_Assignment__c.sObjectType);
            LMS_ESAPI.isAuthorizedToDelete(objectTypesToDelete);
            //END Access Check

            Set<Id> trainingPlanSectionAssignments = new Set<Id>();
            Set<Id> trainingPlanSectionAssignmentUIds = new Set<Id>();
            Set<String> validTPSAKeys = new Set<String>();
            List<Learning_Assignment__c> learningAssignmentsToDelete = new List<Learning_Assignment__c>();

            //Extract training plan section ids
            for(Training_Plan_Section_Assignment__c tpsa : assignments){
                if(tpsa.Training_Plan_Section__c != null && tpsa.User__c != null){
                    trainingPlanSectionAssignments.add(tpsa.Training_Plan_Section__c);
                    trainingPlanSectionAssignmentUIds.add(tpsa.User__c);
                    validTPSAKeys.add(tpsa.User__c+'_'+tpsa.Training_Plan_Section__c);
                }
            }

            //Fetch learning assignments for related training plan sections
            for(Learning_Assignment__c la : [select id
                                                ,User__c
                                                ,Training_Plan_Section__c
                                                from Learning_Assignment__c
                                                where Training_Plan_Section__c in :trainingPlanSectionAssignments
                                                and User__c in :trainingPlanSectionAssignmentUIds]){

                if(validTPSAKeys.contains(la.User__c+'_'+la.Training_Plan_Section__c)){
                    learningAssignmentsToDelete.add(la);
                }
            }

            //Execute delete operation
            if(learningAssignmentsToDelete.size()>0){
                delete learningAssignmentsToDelete;
            }
        }

        // We want to make sure the running user has access to update the AA records even if these are public read only
        public void updateAchievementAssignmentRecordsWOS(List<Achievement_Assignment__c> achievementAssignmentsToUpdate){
            update achievementAssignmentsToUpdate;
        }

        // We want to make sure the running user has access to the training plan records even if the training plan hasn't been shared with the user
        public Map<Id,List<Training_Plan_Achievement__c>> getTrainingPlanSectionAchievementsWOS(Set<Id> trainingPlanSectionIds){

            Map<Id,List<Training_Plan_Achievement__c>> results = new Map<Id,List<Training_Plan_Achievement__c>>();
            //Create local scope vars for Dynamic SOQL binding
            Set<Id> tpsIds = trainingPlanSectionIds;
            List<String> listSOQLFields = new List<String>{
                'Id'
                ,'Name'
                ,'Training_Plan__c'
                ,'Training_Plan_Section__c'
                ,'Type__c'
                ,'Main_Achievement__c'
                ,'Achievement__c'
                ,'Achievement__r.Id'
                ,'Achievement__r.Acquired_Image__c'
                ,'Achievement__r.Eligible_Image__c'
                ,'Achievement__r.Work_Badge_Id__c'
                ,'Achievement__r.Work_Badge_Image_URL__c'
            };

            String soqlQuery = 'select '+String.join(listSOQLFields,',')+' from Training_Plan_Achievement__c where Training_Plan_Section__c in :tpsIds and Type__c = \'Section\'';
            soqlQuery += ' order by CreatedDate desc';

            List<Training_Plan_Achievement__c> tplanAchievements = (List<Training_Plan_Achievement__c>)Database.query(soqlQuery);
            for(Training_Plan_Achievement__c tpa : tplanAchievements){
                if(!results.containsKey(tpa.Training_Plan_Section__c)){
                    results.put(tpa.Training_Plan_Section__c, new List<Training_Plan_Achievement__c>());
                }
                results.get(tpa.Training_Plan_Section__c).add(tpa);
            }

            return results;
        }

    }

}
