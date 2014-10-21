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
global with sharing class TrainingPlanAssignmentsUpdateBatch implements Database.Batchable<sObject>, Database.Stateful{

    global final String trainingplanId;
    global final String tPlanBatchOpId;

    global TrainingPlanAssignmentsUpdateBatch(String tplanId,String tpboId){
        trainingplanId = tplanId;
        tPlanBatchOpId = tpboId;
    }

    global Database.QueryLocator start(Database.BatchableContext BC){

		//BEGIN Access Check
			Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
	        relatedFieldsObjects.put(Training_Plan_Assignment__c.sObjectType,new List<String>{
	        	'Id'
				,'User__c'
				,'Training_Plan__c'
				,'Last_Updated__c'
				,'Status__c'
	        });
			LMS_ESAPI.isAuthorizedToView(relatedFieldsObjects);
		//END Access Check

		//BEGIN Access Check
			Map<Schema.sObjectType,List<String>> relatedFieldsObjectsUpdate = new Map<Schema.sObjectType,List<String>>();
	        relatedFieldsObjectsUpdate.put(Training_Plan_Batch_Operation__c.sObjectType,new List<String>{
				'Type__c'
				,'Successes__c'
				,'Status__c'
				,'Errors__c'
				,'Additional_Information__c'
	        });
			LMS_ESAPI.isAuthorizedToUpdate(relatedFieldsObjectsUpdate);
		//END Access Check

		Training_Plan_Batch_Operation__c tpbo = new Training_Plan_Batch_Operation__c(id=tPlanBatchOpId);
		tpbo.Status__c = 'In Progress';
		tpbo.Successes__c = 0;
		tpbo.Errors__c = 0;
		update tpbo;

        String currentTPlan = trainingplanId;
        String soql = 'select id,User__c,Training_Plan__c, Last_Updated__c,Status__c from Training_Plan_Assignment__c where Training_Plan__c = :currentTPlan';
        return Database.getQueryLocator(soql);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope){

		//BEGIN Access Check
			Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
	        relatedFieldsObjects.put(Learning_Assignment__c.sObjectType,new List<String>{
				'User__c'
				,'Contact__c'
				,'Learning__c'
				,'Learning_Version__c'
				,'Training_Plan__c'
				,'Training_Plan_Section__c'
				,'Training_Plan_Section_Item__c'
	        });
			LMS_ESAPI.isAuthorizedToCreate(relatedFieldsObjects);
			LMS_ESAPI.isAuthorizedToUpdate(relatedFieldsObjects);
		//END Access Check

        Set<Id> selectedUserIds = new Set<Id>();
        for(Training_Plan_Assignment__c a : (List<Training_Plan_Assignment__c>)scope){
            if(a.User__c != null){
                selectedUserIds.add(a.User__c);
            }
        }
        Boolean success = true;
       	String errorMessage = null;

        if(trainingplanId != null && selectedUserIds.size()>0){
        	try{
            	LMSService.upsertAssignments(selectedUserIds,trainingPlanId);
        	}catch(Exception e){
        		success = false;
        		errorMessage = e.getMessage();
        	}

        	if(tPlanBatchOpId != null){
				List<Training_Plan_Batch_Operation__c> tpbos = [select id
																,Training_Plan__c
																,Status__c
																,Successes__c
																,Errors__c
																,Additional_Information__c
																from Training_Plan_Batch_Operation__c
																where id = :tPlanBatchOpId limit 1];

				Training_Plan_Batch_Operation__c tpbo = tpbos.get(0);

				if(success){
					tpbo.Successes__c = tpbo.Successes__c + selectedUserIds.size();
				}else{
					tpbo.Errors__c = tpbo.Errors__c + selectedUserIds.size();
					tpbo.Additional_Information__c = errorMessage;
				}
				update tpbo;
        	}
        }
    }

    global void finish(Database.BatchableContext BC){
		if(tPlanBatchOpId !=  null){
			Training_Plan_Batch_Operation__c tpbo = new Training_Plan_Batch_Operation__c(Id=tPlanBatchOpId);
			tpbo.Status__c = 'Completed';
			update tpbo;
		}
    }

}
