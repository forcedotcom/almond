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
public with sharing class TrainingPlanPreviewController{

    public TrainingPlan tPlan{get;private set;}
    public List<User> lUsersWithAchievement {get;private set;}
    private Id trainingPlanId;
    public Training_Plan_Access_Request__c dummyRequest{get;set;}
    public Training_Plan_Access_Request__c existingRequest{get;set;}
    public Boolean isApprovalRequired{get;private set;}
    public String redirectURL{get;set;}
    public Boolean hasMessages{get{return ApexPages.hasMessages();}}

    //It's important to keep this as a custom controller so that we can bypass sharing restrictions for preview purposes
    public TrainingPlanPreviewController(){
        trainingPlanId = ApexPages.currentPage().getParameters().get('id');
        init();
    }

    private void init(){
        try{
            loadTrainingPlanInfo();
            isApprovalRequired = false;
            dummyRequest = new Training_Plan_Access_Request__c();
            existingRequest = null;

            if(tPlan != null){
                if(tPlan.trainingPlan.Self_Registration_Access__c == 'Requires Approval'){
                    isApprovalRequired = true;
                }

                if(tPlan.mainAchievement != null){
                    lUsersWithAchievement = LMSService.getUsersForAchievement(tPlan.mainAchievement.Id, LMSConstants.AA_ACQUIRED_STATUS, 12);
                }
            }else{
                LMSUtils.addErrorMessage(System.Label.ALMS_Training_Plan_No_Access_Message);
            }
        }catch(Exception e){
            LMSUtils.logException(e,'TrainingPlanPreviewController');
            LMSUtils.addGenericUnknownErrorMessage('TrainingPlanPreviewController - init (1)');
        }
    }

    private void loadTrainingPlanInfo(){
        tPlan = LMSWrappersService.getTrainingPlanDetails(trainingPlanId,UserInfo.getUserId(),true, true);
    }

    public PageReference checkAssignment(){
        if(hasTrainingPlanAssignment()){
            return redirectToPlanDetailPage();
        }else{
            return null;
        }
    }

    //Create assignment is user doesn't have the assignment already
    public PageReference registerForTrainingPlan(){
        redirectURL = null;
        try{

            List<Training_Plan__c> selectedTPlans = LMSService.getTrainingPlans(new Set<Id>{trainingPlanId}, LMSUtils.isPortalUser());

            Training_Plan__c selectedPlan = selectedTPlans.get(0);
            if(selectedPlan.Self_Registration_Access__c != 'Requires Approval' && LMSService.isPublicTrainingPlanAvailable(trainingPlanId,UserInfo.getUserId(), LMSUtils.isPortalUser())){
                LMSService.upsertAssignments(new Set<Id>{UserInfo.getUserId()}, trainingPlanId);
            }else{
                LMSUtils.addErrorMessage(System.Label.ALMS_Public_Plan_Assignment_Error);
                return null;
            }

            PageReference ref = redirectToPlanDetailPage();
            redirectURL = ref.getUrl();
            return null;

        }catch(Exception e){
            LMSUtils.addErrorMessage(e.getStackTraceString());
            return null;
        }
    }

    public PageReference fetchTrainingPlanInfo(){
        existingRequest = null;
        List<Training_Plan__c> selectedTPlans= LMSService.getTrainingPlans(new Set<Id>{trainingPlanId}, LMSUtils.isPortalUser());
        List<Training_Plan_Access_Request__c> existingReqs = LMSService.fetchTrainingPlanAccessRequest(UserInfo.getUserId(),trainingPlanId,null,LMSUtils.isPortalUser());
        if(existingReqs.size()>0){
            existingRequest = existingReqs.get(0);
        }
        return null;
    }

    public PageReference requestAccessForTrainingPlan(){

        try{
            Training_Plan_Access_Request__c tpar = LMSService.createTrainingPlanAccessRequest(UserInfo.getUserId(),trainingPlanId,dummyRequest.Comments__c, LMSUtils.isPortalUser());
            dummyRequest = new Training_Plan_Access_Request__c();
            LMSUtils.addSuccessMessage(System.Label.ALMS_Public_Plan_Request_Submitted);
            return null;
        }catch(Exception e){
            LMSUtils.addErrorMessage(e.getStackTraceString());
            return null;
        }
    }

    private PageReference redirectToPlanDetailPage(){
        PageReference ref = new PageReference(LMSUtils.updateURLCommunityPath('/apex/TrainingPlanDetail'));
        ref.getParameters().put('id',trainingPlanId);
        ref.setRedirect(true);
        return ref;
    }

    private Boolean hasTrainingPlanAssignment(){
        if(String.isBlank(trainingPlanId)){
            return false;
        }
        //Get assignments for existing training plans
        List<Training_Plan_Assignment__c> tPlanAsgmts = [select id from Training_Plan_Assignment__c where User__c = :UserInfo.getUserId() and Training_Plan__c = :trainingPlanId];
        return tPlanAsgmts.size()>0;
    }
}
