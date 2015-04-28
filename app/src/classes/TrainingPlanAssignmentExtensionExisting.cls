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
public with sharing class TrainingPlanAssignmentExtensionExisting{

    private String trainingPlanId;
    @TestVisible
    private ApexPages.StandardSetController setCon;

    public List<TPlanAssignmentWrapper> rows{get;set;}

    public with sharing class TPlanAssignmentWrapper{
        public Boolean isSelected{get;set;}
        public Training_Plan_Assignment__c assignmentRecord{get;set;}
        public TPlanAssignmentWrapper(){}
    }

    public TrainingPlanAssignmentExtensionExisting(ApexPages.StandardController cont){
        trainingPlanId = cont.getRecord().Id;
        init();
    }

    private void init(){

        try{
            //BEGIN Access Check
            Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
            relatedFieldsObjects.put(Training_Plan_Assignment__c.sObjectType,new List<String>{
                'Name'
                ,'Status__c'
                ,'User__c'
                ,'Last_Updated__c'
            });
            LMS_ESAPI.isAuthorizedToView(relatedFieldsObjects);
            //END Access Check

            this.setCon= new ApexPages.StandardSetController(Database.getQueryLocator(
                [SELECT Id
                        ,Name
                        ,Status__c
                        ,User__c
                        ,User__r.ProfileId
                        ,User__r.UserRoleId
                        ,User__r.Email
                        ,Last_Updated__c
                        FROM Training_Plan_Assignment__c
                        WHERE Training_Plan__c = :trainingPlanId
                        LIMIT 10000]
            ));
            this.setCon.setpageNumber(1);
            this.setCon.setPageSize(20);
            setRows();
        }catch(Exception e){
            LMSUtils.logException(e,'TrainingPlanAssignmentExtensionExisting');
            LMSUtils.addGenericUnknownErrorMessage('TrainingPlanAssignmentExtensionExisting - init (1)');
        }
    }

    public List<TPlanAssignmentWrapper> setRows(){

        rows = new List<TPlanAssignmentWrapper>();

        for(sObject r : this.setCon.getRecords()){
            Training_Plan_Assignment__c a = (Training_Plan_Assignment__c)r;
            TPlanAssignmentWrapper row = new TPlanAssignmentWrapper();
            row.assignmentRecord = a;
            row.isSelected = false;
            rows.add(row);
        }

        return rows;

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
            ApexPages.currentPage().getParameters().put('stab','updatedeleteTab');
            this.setCon.next();
            setRows();
        }
    }

    public void doPrevious(){
        if(this.setCon.getHasPrevious()){
            ApexPages.currentPage().getParameters().put('stab','updatedeleteTab');
            this.setCon.previous();
            setRows();
        }
    }

    public Integer getTotalPages(){
        Decimal totalSize = this.setCon.getResultSize();
        Decimal pageSize = this.setCon.getPageSize();

        Decimal pages = totalSize/pageSize;

        return (Integer)pages.round(System.RoundingMode.CEILING);
    }

    public PageReference updateAssignments(){

        try{

            //BEGIN Access Check
            Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
            relatedFieldsObjects.put(Learning_Assignment__c.sObjectType,new List<String>{
                'Learning__c'
                ,'Learning_Version__c'
                ,'Training_Plan__c'
                ,'Training_Plan_Section__c'
                ,'Training_Plan_Section_Item__c'
            });
            LMS_ESAPI.isAuthorizedToCreate(relatedFieldsObjects);
            LMS_ESAPI.isAuthorizedToUpdate(relatedFieldsObjects);
            //END Access Check

            Set<Id> selectedUserIds = new Set<Id>();
            for(TPlanAssignmentWrapper cRow : rows){
                if(cRow.isSelected && cRow.assignmentRecord != null){
                    if(cRow.assignmentRecord.User__c != null){
                        selectedUserIds.add(cRow.assignmentRecord.User__c);
                    }
                }
            }

            if(trainingPlanId != null && selectedUserIds.size()>0){
                LMSService.upsertAssignments(selectedUserIds,trainingPlanId,null);
                init();
                LMSUtils.addSuccessMessage(System.Label.ALMS_Assignments_Updated_Success);
            }

        }catch(Exception e){
            LMSUtils.logException(e,'TrainingPlanAssignmentExtensionExisting');
            LMSUtils.addGenericUnknownErrorMessage('TrainingPlanAssignmentExtensionExisting - updateAssignments (1)');
        }

        return null;
    }

    public PageReference deleteAssignments(){

        try{

            //BEGIN Access Check
            List<Schema.sObjectType> objectTypesToDelete = new List<Schema.sObjectType>();
            objectTypesToDelete.add(Training_Plan_Assignment__c.sObjectType);
            LMS_ESAPI.isAuthorizedToDelete(objectTypesToDelete);
            //END Access Check

            List<Training_Plan_Assignment__c> selectedAssignments = new List<Training_Plan_Assignment__c> ();
            for(TPlanAssignmentWrapper cRow : rows){
                if(cRow.isSelected && cRow.assignmentRecord != null){
                    selectedAssignments.add(cRow.assignmentRecord);
                }
            }

            if(selectedAssignments.size()>0){
                delete selectedAssignments;
                init();
                LMSUtils.addSuccessMessage(System.Label.ALMS_Assignments_Deleted_Success);
            }

        }catch(Exception e){
            LMSUtils.logException(e,'TrainingPlanAssignmentExtensionExisting');
            LMSUtils.addGenericUnknownErrorMessage('TrainingPlanAssignmentExtensionExisting - deleteAssignments (1)');
        }

        return null;
    }

}
