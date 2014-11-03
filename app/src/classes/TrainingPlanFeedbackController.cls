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
public with sharing class TrainingPlanFeedbackController{

    public ApexPages.StandardSetController setCon;
    public Training_Plan_Feedback__c feedback{get;set;}
    public List<User> lUsersWithAchievement {get;set;}
    public User currentUser{get;private set;}
    public String tplanId{get;private set;}
    public TrainingPlan tPlan{get;private set;}
    public Boolean isPreview{get;private set;}
    public Training_Plan_Feedback__c existingFeedback{get;private set;}
    public Boolean isAllowedToView{get;private set;}

    public Boolean hasMessages{get{return ApexPages.hasMessages();}}

    public TrainingPlanFeedbackController(){
        tplanId = ApexPages.currentPage().getParameters().get('id');
        isPreview = false;
        if(!String.isBlank(ApexPages.currentPage().getParameters().get('preview'))){
            isPreview = true;
        }

        isAllowedToView = LMSService.isAllowedToViewTrainingPlan(tplanId,UserInfo.getUserId());

        if(isAllowedToView){
            init();
        }else{
            LMSUtils.addErrorMessage(System.Label.ALMS_Training_Plan_No_Access_Message);
        }
    }

    private void init(){
        loadTrainingPlanInfo();
        feedback = new Training_Plan_Feedback__c();
        existingFeedback = getExistingRating();
        feedback.Training_Plan__c = tplanId;
        feedback.User__c = UserInfo.getUserId();
        currentUser = [select id,Name,SmallPhotoUrl from User where id = :UserInfo.getUserId()];
        setCon = getSetCon(tplanId);
        if(tPlan != null){
            if(tPlan.mainAchievement != null){
                lUsersWithAchievement = LMSService.getUsersForAchievement(tPlan.mainAchievement.Id, LMSConstants.AA_ACQUIRED_STATUS, 12);
            }
        }
    }

    private void loadTrainingPlanInfo(){
        if(isPreview){
            this.tPlan = LMSWrappersService.getTrainingPlanDetails(tplanId,UserInfo.getUserId(),true);
        }else{
            this.tPlan = LMSWrappersService.getTrainingPlanDetails(tplanId,UserInfo.getUserId(),false);
        }
    }

    public PageReference submitFeedback(){
        if(String.isBlank(feedback.Comments__c)){
            LMSUtils.addErrorMessage(System.Label.ALMS_Feedback_Missing_Comments);
        }else if (feedback.Rating__c  != null && feedback.Rating__c != 0 && existingFeedback != null){
            LMSUtils.addErrorMessage(System.Label.ALMS_Feedback_Existing_Rating);
        }else{
            try{
                LMSService.insertTrainingPlanFeedback(feedback);
                init();
            }catch(Exception e){
                LMSUtils.addErrorMessage(e.getMessage());
            }
        }
        return null;
    }

    private Training_Plan_Feedback__c getExistingRating(){

        List<Training_Plan_Feedback__c> result =  LMSService.getTrainingPlanFeedback(UserInfo.getUserId(),tplanId,true);

        if(result.size()>0){
            return result.get(0);
        }else{
            return null;
        }
    }

    public List<Training_Plan_Feedback__c> getComments() {
        return (List<Training_Plan_Feedback__c>) setCon.getRecords();
    }

    public void doNext(){
        if(this.setCon.getHasNext()){
            this.setCon.next();
        }
    }

    public void doPrevious(){
        if(this.setCon.getHasPrevious()){
            this.setCon.previous();
        }
    }

    public Boolean getHasPrevious(){
        return this.setCon.getHasPrevious();
    }

    public Boolean getHasNext(){
        return this.setCon.getHasNext();
    }

    public Integer getPageNumber(){
        return this.setCon.getPageNumber();
    }

    public Integer getTotalPages(){
        Decimal totalSize = this.setCon.getResultSize();
        Decimal pageSize = this.setCon.getPageSize();
        Decimal pages = totalSize/pageSize;
        return (Integer)pages.round(System.RoundingMode.CEILING);
    }

    public Boolean getIsAssignedToTrainingPlan(){
        List<Training_Plan_Assignment__c> tplanAssignments = [select id
                                                                    ,name
                                                                    from Training_Plan_Assignment__c
                                                                    where User__c = :UserInfo.getUserId()
                                                                    and Training_Plan__c = :tplanId];
       return tplanAssignments.size()>0;
    }

    private ApexPages.StandardSetController getSetCon(Id tplanId){
        ApexPages.StandardSetController setCon = new ApexPages.StandardSetController(Database.getQueryLocator(
                [select Id
                        ,Name
                        ,Rating__c
                        ,Comments__c
                        ,User__c
                        ,User__r.Name
                        ,User__r.SmallPhotoUrl
                        from Training_Plan_Feedback__c
                        where Training_Plan__c = :tplanId
                        order by CreatedDate desc]));
        setCon.setPageSize(5);
        return setCon;
    }

}
