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
global with sharing class TrainingPlanSectionItAssigmtsDeleteBatch implements Database.Batchable<sObject>, Database.Stateful{

    global final String trainingPlanSectionItemId;

    global TrainingPlanSectionItAssigmtsDeleteBatch(String tPlanSectionItemId){
        this.trainingPlanSectionItemId = tPlanSectionItemId;
    }

    global Database.QueryLocator start(Database.BatchableContext BC){

        //BEGIN Access Check
        Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
        relatedFieldsObjects.put(Learning_Assignment__c.sObjectType,new List<String>{
            'Id'
            ,'User__c'
            ,'Training_Plan_Section_Item__c'
            ,'Progress__c'
        });
        LMS_ESAPI.isAuthorizedToView(relatedFieldsObjects);
        //END Access Check

        String currentTPlanSectionItem = trainingPlanSectionItemId;
        String soql = 'select id,User__c,Training_Plan_Section_Item__c,Progress__c from Learning_Assignment__c where Training_Plan_Section_Item__c = :currentTPlanSectionItem';
        return Database.getQueryLocator(soql);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope){

        //BEGIN Access Check
        List<Schema.sObjectType> objectTypesToDelete = new List<Schema.sObjectType>();
        objectTypesToDelete.add(Learning_Assignment__c.sObjectType);
        LMS_ESAPI.isAuthorizedToDelete(objectTypesToDelete);
        //END Access Check

        if(scope != null && scope.size()>0){
            delete scope;
        }
    }

    global void finish(Database.BatchableContext BC){

    }
}
