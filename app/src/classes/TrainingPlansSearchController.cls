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
public with sharing class TrainingPlansSearchController {

    @TestVisible
    private ApexPages.StandardSetController setCon;
    public Boolean hasMessages{get{return ApexPages.hasMessages();}}
    public String currentSearchTerm{get;private set;}

    public TrainingPlansSearchController(){
        init();
    }

    private void init(){
        try{

            //BEGIN Access Check
            Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
                relatedFieldsObjects.put(Training_Plan__c.sObjectType,new List<String>{
                'Name'
                ,'Description__c'
                ,'Self_Registration_Access__c'
                ,'Enable_Self_Registration__c'
                });
            LMS_ESAPI.isAuthorizedToView(relatedFieldsObjects);
            //END Access Check

            String searchTerm = ApexPages.currentPage().getParameters().get('q');
            currentSearchTerm = searchTerm;

            if(searchTerm != null && !String.isBlank(searchTerm) && searchTerm.trim().length() > 2){
                System.debug('serchTerm ' +searchTerm);
                searchTerm = '%'+searchTerm+'%';

                if(LMSUtils.isPortalUser()){
                    TrainingPlansSearchController.WithoutSharingOps wsops = new TrainingPlansSearchController.WithoutSharingOps();
                    this.setCon = wsops.getSetCon(searchTerm);
                }else{
                    this.setCon= new ApexPages.StandardSetController(Database.getQueryLocator(
                        [SELECT Id
                                ,Name
                                ,Description__c
                                ,Enable_Self_Registration__c
                                ,Self_Registration_Access__c
                                FROM Training_Plan__c
                                WHERE Name LIKE :searchTerm
                                ORDER BY CreatedDate desc
                                LIMIT 200]
                    ));
                }
                this.setCon.setpageNumber(1);
                this.setCon.setPageSize(10);
            }else{
                LMSUtils.addErrorMessage(System.Label.ALMS_Search_Minimum_Characters);
            }
        }catch(Exception e){
            LMSUtils.logException(e,'TrainingPlansSearchController');
            LMSUtils.addGenericUnknownErrorMessage('TrainingPlansSearchController - init (1)');
        }
    }

    public List<TrainingPlanWithAchievement> getSearchResults() {
        return createWrapperObjects();
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

    public Integer getTotalPages(){
        Decimal totalSize = this.setCon.getResultSize();
        Decimal pageSize = this.setCon.getPageSize();

        Decimal pages = totalSize/pageSize;

        return (Integer)pages.round(System.RoundingMode.CEILING);
    }

    private List<TrainingPlanWithAchievement> createWrapperObjects(){

        List<TrainingPlanWithAchievement> tPlans = new List<TrainingPlanWithAchievement>();
        List<Training_Plan__c> trainingPlans = new List<Training_Plan__c>();
        if(this.setCon != null){
            trainingPlans = (List<Training_Plan__c>) this.setCon.getRecords();
        }

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

        return tPlans;

    }

    private without sharing class WithoutSharingOps{
        public ApexPages.StandardSetController getSetCon(String searchTerm){
            LMSCommunitiesService.WithoutSharingOps wsops = new LMSCommunitiesService.WithoutSharingOps();
            Set<Id> accountTPlanIds = wsops.getTrainingPlanIdsForAccount(LMSUtils.getUserAccountId());
            ApexPages.StandardSetController setCon = new ApexPages.StandardSetController(Database.getQueryLocator([SELECT Id
                            ,Name
                            ,Description__c
                            ,Enable_Self_Registration__c
                            ,Self_Registration_Access__c
                            FROM Training_Plan__c
                            WHERE Name LIKE :searchTerm
                            AND (Self_Registration_Access__c = :LMSConstants.TPLAN_PUBLIC_EXTERNAL
                              OR id in :accountTPlanIds
                            )
                            ORDER BY CreatedDate desc
                            LIMIT 200]
            ));
            return setCon;
        }
    }

}
