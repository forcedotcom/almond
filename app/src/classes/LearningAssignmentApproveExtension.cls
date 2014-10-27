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
public with sharing class LearningAssignmentApproveExtension {

    private Learning_Assignment__c assignment;
    private Id laId;
    private Set<Id> taskApprovers;
    public String approverNotes{get;set;}

    public LearningAssignmentApproveExtension(ApexPages.StandardController cont){
        try{
            laId = cont.getRecord().Id;
            init();
        }catch(Exception e){
            LMSUtils.logException(e,'LearningAssignmentApproveExtension');
            LMSUtils.addGenericUnknownErrorMessage('LearningAssignmentApproveExtension - init (1)');
        }
    }

    private void init(){

        Id assignmentId = laId;
        taskApprovers = new Set<Id>();

        List<String> listSOQLFields = new List<String>{
            'Id'
            ,'Approved__c'
            ,'Approved_By__c'
            ,'Approver_Notes__c'
            ,'Learning_Version__c'
            ,'Learning_Version__r.Task__c'
            ,'Learning_Version__r.Task__r.Requires_Manager_Approval__c'
            ,'User__c'
            ,'User__r.ManagerId'
        };

        //BEGIN Access Check
        Map<Schema.sObjectType,List<String>> relatedFieldsObjectsView = new Map<Schema.sObjectType,List<String>>();
        relatedFieldsObjectsView.put(Learning_Assignment__c.sObjectType,new List<String>{
            'Approved__c'
            ,'Approved_By__c'
            ,'Approver_Notes__c'
            ,'Learning_Version__c'
            ,'User__c'
            });
            relatedFieldsObjectsView.put(Task__c.sObjectType,new List<String>{
                'Requires_Manager_Approval__c'
            });
            relatedFieldsObjectsView.put(Task_Approver__c.sObjectType,new List<String>{
                'User__c'
                ,'Task__c'
            });
        LMS_ESAPI.isAuthorizedToView(relatedFieldsObjectsView);
        //END Access Check

        String soqlQuery = 'select '+String.join(listSOQLFields,',')+' from Learning_Assignment__c where Id = :assignmentId';

        List<Learning_Assignment__c> assignments = (List<Learning_Assignment__c>)Database.query(soqlQuery);
        if(assignments.size()>0){
            assignment = assignments.get(0);
        }

        //Get a list of task approvers
        if(assignment.Learning_Version__r.Task__c != null){

            Id taskId = assignment.Learning_Version__r.Task__c;

            for(Task_Approver__c ta : [select id
                                            ,User__c
                                            ,Task__c
                                            from Task_Approver__c
                                            where Task__c = :taskId]){

                if(ta.User__c != null){
                    taskApprovers.add(ta.User__c);
                }
            }

        }

    }

    public PageReference approveAssignment(){

        try{

            if(approverNotes != null && approverNotes.length() > 255){
                LMSUtils.addErrorMessage('Only 255 characters are allowed for approver notes');
                return null;
            }

            if(LMSUtils.isAdminUser()){

                updateAssignment();

            }else{

                if(assignment.Learning_Version__r.Task__r != null){

                    Boolean requiresManagerAproval = assignment.Learning_Version__r.Task__r.Requires_Manager_Approval__c;

                    //Verify if the current user has access to approve the task
                    if((requiresManagerAproval == true && isRunningUserAManager())
                    || (taskApprovers.size()>0 && taskApprovers.contains(UserInfo.getUserId()))){

                        //Bypass FLS permissions in the extension and update the approved checkbox
                        //Learning assignment will take care of the rest
                        updateAssignment();

                    }else{
                        LMSUtils.addErrorMessage('You are not authorized to approve this task.');
                        return null;
                    }
                }

            }

            PageReference ref = new PageReference('/'+assignment.id);
            ref.setRedirect(true);
            return ref;

        }catch(Exception e){
            LMSUtils.logException(e,'LearningAssignmentApproveExtension');
            LMSUtils.addGenericUnknownErrorMessage('LearningAssignmentApproveExtension - approveAssignment (2)');
            return null;
        }

    }

    private Boolean isRunningUserAManager(){
        if(assignment != null && assignment.User__r.ManagerId == UserInfo.getUserId()){
            return true;
        }
        return false;
    }

    private void updateAssignment(){
        //We don't enforce CRUD/FLS here as we don't know what users can be assigned as task approvers
        //Thereforce, we can't assume all users will be admin and have permissions to update the Approved field
        assignment.approved__c = true;
        assignment.approver_notes__c = approverNotes;
        update assignment;
    }

}
