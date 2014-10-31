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
public with sharing class TrainingCatalogDetailController {

    private transient List<Training_Plan__c> trainingPlans{get;private set;}
    public transient List<TrainingPlanWithAchievement> tPlans{get;private set;}

    public Learning_Category__c learningcategory {get; private set;}

    public TrainingCatalogDetailController(){
        learningcategory = new Learning_Category__c();
        init();
    }

    private void init(){
        trainingPlans = new List<Training_Plan__c>();

        //Fetch categoryId from url
        String categoryId = Apexpages.currentPage().getParameters().get('id');
        if(String.isBlank(categoryId)){
            tPlans = new List<TrainingPlanWithAchievement>();
            LMSUtils.addErrorMessage(System.Label.ALMS_Invalid_Category_Id);
        }else{
            List<Learning_Category__c> lcats = LMSService.getLearningCategories(categoryId);
            if(lcats.size()>0){
                learningcategory = lcats.get(0);

                List<Id> sortedTPlanIds = LMSService.getTrainingPlanIdsForCategory(new Set<Id>{categoryId});
                if(sortedTPlanIds.size()>0){
                    //Return a sorted list of training plans
                    Map<Id,Training_Plan__c> trainingPlansMap = new Map<Id,Training_Plan__c>();

                    List<Training_Plan__c> unsortedTrainingPlans = LMSService.getTrainingPlansWithItems(UserInfo.getUserId(),new Set<Id>(sortedTPlanIds),false);
                    for(Training_Plan__c tplan : unsortedTrainingPlans){
                        trainingPlansMap.put(tplan.Id,tplan);
                    }
                    // Add training plans to list in sorted order
                    for(Id tplanId : sortedTPlanIds){
                        if(trainingPlansMap.containsKey(tplanId)){
                            trainingPlans.add(trainingPlansMap.get(tplanId));
                        }
                    }
                }
                createWrapperObjects(trainingPlans);
            }
        }
    }

    private void createWrapperObjects(List<Training_Plan__c> trainingPlans){

        tPlans = new List<TrainingPlanWithAchievement>();

        //Create wrapper objects that include main reward information
        if(trainingPlans.size()>0){

            //Get assignments for existing training plans
            Map<Id,Training_Plan_Assignment__c> assignedTrainingPlanIds = new Map<Id,Training_Plan_Assignment__c>();
            for(Training_Plan_Assignment__c tpa : [select id
                                                        ,Status__c
                                                        ,Training_Plan__c
                                                        from Training_Plan_Assignment__c
                                                        where User__c = :UserInfo.getUserId()
                                                        and Training_Plan__c in :trainingPlans]){
                assignedTrainingPlanIds.put(tpa.Training_Plan__c,tpa);
            }

            Map<Id,Achievement__c> tmp = LMSService.getTrainingMainAchievements(LMSUtils.ObjectListToIdSet(trainingPlans));

            for(Training_Plan__c tp : trainingPlans){

                Boolean hasAssignment = false;
                Training_Plan_Assignment__c tpAssignment = null;
                if(assignedTrainingPlanIds.containsKey(tp.Id)){
                    hasAssignment = true;
                    tpAssignment = assignedTrainingPlanIds.get(tp.Id);
                }

                TrainingPlanWithAchievement tplach = new TrainingPlanWithAchievement(tp, tmp.get(tp.Id),null,hasAssignment);
                if(tpAssignment != null){
                    tplach.assignmentStatus = tpAssignment.Status__c;
                }
                tPlans.add(tplach);
            }
        }
    }

}
