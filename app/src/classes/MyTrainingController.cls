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
public with sharing class MyTrainingController extends LMSBaseController{

    private transient List<Training_Plan__c> trainingPlans{get;private set;}
    public transient List<TrainingPlanWithAchievement> tPlans{get;private set;}
    public String selectedType{get;set;}

    public MyTrainingController(){
        init();
    }

    private void init(){
        tPlans = new List<TrainingPlanWithAchievement>();
        selectedType = LMSConstants.TPLAN_STATUS_NOT_STARTED;

        String urlStatus = Apexpages.currentPage().getParameters().get('status');
        if(!String.isBlank(urlStatus)){
            selectedType = urlStatus;
        }

        loadTrainingPlans();
    }

    public void loadTrainingPlans(){

        Boolean includeAssignmentData = false;
        if(selectedType == LMSConstants.TPLAN_STATUS_COMPLETED){
            trainingPlans = LMSService.getCompletedTrainingPlans(UserInfo.getUserId(),LMSUtils.isPortalUser());
            includeAssignmentData = true;
        }else if(selectedType == LMSConstants.TPLAN_STATUS_IN_PROGRESS){
            trainingPlans = LMSService.getInProgressTrainingPlans(UserInfo.getUserId(),LMSUtils.isPortalUser());
        }else if(selectedType == LMSConstants.TPLAN_STATUS_NOT_STARTED){
            trainingPlans = LMSService.getNewTrainingPlans(UserInfo.getUserId(),LMSUtils.isPortalUser());
        }else{
            trainingPlans = new List<Training_Plan__c>();
        }

        createWrapperObjects(trainingPlans, includeAssignmentData);

    }

    private void createWrapperObjects(List<Training_Plan__c> trainingPlans, Boolean includeAssignmentData){

        //Get assignments for existing training plans
        Map<Id,Training_Plan_Assignment__c> assignedTrainingPlanIds = new Map<Id,Training_Plan_Assignment__c>();

        if(includeAssignmentData){
            //This query should always run with sharing as the end-user should be the full owner of the assignment
            for(Training_Plan_Assignment__c tpa : [select id
                                                        ,Status__c
                                                        ,Completed_On__c
                                                        ,Training_Plan__c
                                                        from Training_Plan_Assignment__c
                                                        where User__c = :UserInfo.getUserId()
                                                        and Training_Plan__c in :trainingPlans]){
                assignedTrainingPlanIds.put(tpa.Training_Plan__c,tpa);
            }
        }

        tPlans = new List<TrainingPlanWithAchievement>();

        //Create wrapper objects that include main reward information
        if(trainingPlans.size()>0){

            PageReference tempRef = Page.TrainingPlanDetail;

            Map<Id,Achievement__c> tmp = LMSService.getTrainingMainAchievements(LMSUtils.objectListToIdSet(trainingPlans));

            for(Training_Plan__c tp : trainingPlans){

                Training_Plan_Assignment__c tpAssignment = null;
                if(assignedTrainingPlanIds.containsKey(tp.Id)){
                    tpAssignment = assignedTrainingPlanIds.get(tp.Id);
                }

                if(LMSService.isActiveTrainingPlan(tp)){

                    TrainingPlanWithAchievement tplach = new TrainingPlanWithAchievement(tp, tmp.get(tp.Id),LMSUtils.updateURLCommunityPath(tempRef.getUrl()), true);
                    if(tpAssignment != null){
                        if(tpAssignment.Completed_On__c != null){
                            tplach.planCompletedDate = (tpAssignment.Completed_On__c).format();
                        }
                        tplach.assignmentStatus = tpAssignment.Status__c;
                    }

                    tPlans.add(tplach);
                }

            }

        }

    }


}
