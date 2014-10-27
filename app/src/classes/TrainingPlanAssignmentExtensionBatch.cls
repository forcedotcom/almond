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
public with sharing class TrainingPlanAssignmentExtensionBatch{

    private String trainingPlanId;
    public Boolean hasMessages{get{return ApexPages.hasMessages();}}

    public TrainingPlanAssignmentExtensionBatch(ApexPages.StandardController cont){
        trainingPlanId = cont.getRecord().Id;
        init();
    }

    private void init(){
        //Nothing to do here for now...
    }

    public PageReference updateAllAssignments(){

        checkBatchOperationAccess();

        Training_Plan_Batch_Operation__c tpbo;
        try{

            tpbo = new Training_Plan_Batch_Operation__c();
            tpbo.Training_Plan__c = trainingPlanId;
            tpbo.Type__c = 'Update Assignments';
            tpbo.Successes__c = 0;
            tpbo.Status__c = 'New';
            tpbo.Errors__c = 0;
            tpbo.Additional_Information__c = null;
            insert tpbo;

            Id batchInstanceId = Database.executeBatch(new TrainingPlanAssignmentsUpdateBatch(trainingPlanId,tpbo.Id),20);
            LMSUtils.addSuccessMessage('Batch update process has been queued successfully');
        }catch(Exception e){
            tpbo.Status__c = 'Failed';
            tpbo.Additional_Information__c = e.getMessage();
            update tpbo;
            ApexPages.addMessages(e);
        }
        return null;
    }

    public PageReference deleteAllAssignments(){

        checkBatchOperationAccess();

        Training_Plan_Batch_Operation__c tpbo;
        try{

            tpbo = new Training_Plan_Batch_Operation__c();
            tpbo.Training_Plan__c = trainingPlanId;
            tpbo.Type__c = 'Delete Assignments';
            tpbo.Successes__c = 0;
            tpbo.Status__c = 'New';
            tpbo.Errors__c = 0;
            tpbo.Additional_Information__c = null;
            insert tpbo;

            Id batchInstanceId = Database.executeBatch(new TrainingPlanAssignmentsDeleteBatch(trainingPlanId,tpbo.Id),20);
            LMSUtils.addSuccessMessage('Batch delete process has been queued successfully');
        }catch(Exception e){
            tpbo.Status__c = 'Failed';
            tpbo.Additional_Information__c = e.getMessage();
            update tpbo;
            ApexPages.addMessages(e);
        }
        return null;
    }

    //TODO : DRY up these access checks, move them to a base class
    private void checkBatchOperationAccess(){
        //BEGIN Access Check
        Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
        relatedFieldsObjects.put(Training_Plan_Batch_Operation__c.sObjectType,new List<String>{
            'Type__c'
            ,'Successes__c'
            ,'Status__c'
            ,'Errors__c'
            ,'Additional_Information__c'
        });
        LMS_ESAPI.isAuthorizedToUpdate(relatedFieldsObjects);
        //END Access Check
    }

}
