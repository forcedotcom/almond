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
global with sharing class LearningDeleteSharedAsgmtsBatch implements Database.Batchable<sObject>, Database.Stateful{

    global final String learningId;

    global LearningDeleteSharedAsgmtsBatch(String learningId){
        this.learningId = learningId;
    }

    global Database.QueryLocator start(Database.BatchableContext BC){

        //BEGIN Access Check
        Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
        relatedFieldsObjects.put(Shared_Learning_Assignment__c.sObjectType,new List<String>{
            'Id'
            ,'User__c'
            ,'Learning__c'
            ,'Progress__c'
        });
        LMS_ESAPI.isAuthorizedToView(relatedFieldsObjects);
        //END Access Check

        String currentLearningId = learningId;
        String soql = 'select id,User__c,Learning__c,Progress__c from Shared_Learning_Assignment__c where Learning__c = :currentLearningId';
        return Database.getQueryLocator(soql);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope){

        //BEGIN Access Check
        List<Schema.sObjectType> objectTypesToDelete = new List<Schema.sObjectType>();
        objectTypesToDelete.add(Shared_Learning_Assignment__c.sObjectType);
        LMS_ESAPI.isAuthorizedToDelete(objectTypesToDelete);
        //END Access Check

        if(scope != null && scope.size()>0){

            List<Shared_Learning_Assignment__c> sharedAssignments = (List<Shared_Learning_Assignment__c>)scope;

            String ns = LMSUtils.getPackageNamespace();
            AggregateResult[] groupedResults = [select Shared_Learning_Assignment__c
                                                        ,count(Id) cnt
                                                        from Learning_Assignment__c
                                                        where Shared_Learning_Assignment__c in :sharedAssignments
                                                        group by Shared_Learning_Assignment__c];

    List<Shared_Learning_Assignment__c> sharedAssignmentsToBeDeleted = new List<Shared_Learning_Assignment__c>();
            Set<Id> sharedAssignmentsWithLearnings = new Set<Id>();

            for (AggregateResult ar : groupedResults)  {
                if((Integer)ar.get('cnt') > 0){
                    String sharedAssignmentId = (String)ar.get(ns+'Shared_Learning_Assignment__c');
                    sharedAssignmentsWithLearnings.add(sharedAssignmentId);
                }
            }

            for(Shared_Learning_Assignment__c sla : sharedAssignments){
                if(!sharedAssignmentsWithLearnings.contains(sla.Id)){
                    sharedAssignmentsToBeDeleted.add(sla);
                }
            }

            if(sharedAssignmentsToBeDeleted.size()>0){
               delete sharedAssignmentsToBeDeleted;
           }

        }
    }

    global void finish(Database.BatchableContext BC){

    }
}
