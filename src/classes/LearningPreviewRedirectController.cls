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
global with sharing class LearningPreviewRedirectController {
    
    @RemoteAction
    global static String previewContent(String selectedLearningId, String selectedContent){

        try{
            //Create or fetch preview learning version
            if(!String.isBlank(selectedContent)){

                Learning__c learning = LearningPreviewService.getLearningInfo(selectedLearningId);
                if(learning == null){
                    return null;
                }
                String currentRecordType = learning.recordType.developerName;
                currentRecordType = currentRecordType.toLowerCase();
                
                Learning_Version__c previewlVersion = new Learning_Version__c();

                Id learningId = learning.Id;
                String selectedContentId = selectedContent;

                //BEGIN Access Check
                List<String> lvFields =  new List<String>{'Learning__c','Version__c','Type__c'};
                Map<Schema.sObjectType,List<String>> relatedFieldsObjectsView = new Map<Schema.sObjectType,List<String>>();
                relatedFieldsObjectsView.put(Learning_Version__c.sObjectType,lvFields);
                Map<Schema.sObjectType,List<String>> relatedFieldsObjectsCreate = new Map<Schema.sObjectType,List<String>>();
                relatedFieldsObjectsCreate.put(Learning_Version__c.sObjectType,lvFields);

                LMS_ESAPI.isAuthorizedToView(relatedFieldsObjectsView);
                LMS_ESAPI.isAuthorizedToCreate(relatedFieldsObjectsCreate);
                //END Access Check

                LearningPreviewService.LearningMappings mappings = LearningPreviewService.getLearningMappings();
                Map<String,String> rtFieldMapping = mappings.rtFieldMapping;
                
                //Fetch existing learning version for current content
                String soql = 'select id from Learning_Version__c where Type__c = \'Preview\' and Learning__c = :learningId';
                soql+= ' and '+rtFieldMapping.get(currentRecordType)+' = :selectedContentId';

                //Set common attributes
                previewlVersion.put(rtFieldMapping.get(currentRecordType),selectedContent);
                previewlVersion.Learning__c = learning.Id;
                previewlVersion.Version__c = 0;
                previewlVersion.Type__c = 'Preview';

                //Look for an existing preview version, if there's a match just return that version
                List<Learning_Version__c> existingPreviewLVs = (List<Learning_Version__c>)Database.query(soql);

                if(existingPreviewLVs.size()>0){
                    previewlVersion = existingPreviewLVs.get(0);
                }else{
                    //Nope, there's no version create a new preview version
                    upsert previewlVersion;
                }

                PageReference redirectionRef = doRedirection(learning, previewlVersion.Id, currentRecordType);
                return redirectionRef.getUrl();

            }else{
                return null;
            }

        }catch(Exception e){
            LMSUtils.logException(e,'LearningPreviewRedirectController');
            return null;
        }

    }

    //This method creates an assignment for the preview learning version and redirects to the preview page
    public static PageReference doRedirection(Learning__c learning, Id previewVersionId, String currentRecordType){

        try{

            Learning_Assignment__c previewAssignment = new Learning_Assignment__c();

            //BEGIN Access Check
            List<String> laFields =  new List<String>{'Learning__c'
                                                        ,'Learning_Version__c'
                                                        ,'Is_Test_Assignment__c'
            };
            Map<Schema.sObjectType,List<String>> relatedFieldsObjectsView = new Map<Schema.sObjectType,List<String>>();
            relatedFieldsObjectsView.put(Learning_Assignment__c.sObjectType,laFields);
            Map<Schema.sObjectType,List<String>> relatedFieldsObjectsCreate = new Map<Schema.sObjectType,List<String>>();
            relatedFieldsObjectsCreate.put(Learning_Assignment__c.sObjectType,laFields);

            LMS_ESAPI.isAuthorizedToView(relatedFieldsObjectsView);
            LMS_ESAPI.isAuthorizedToCreate(relatedFieldsObjectsCreate);
            //END Access Check

            //Fetch existing preview assignments
            List<Learning_Assignment__c> previewAssignments = [select id
                                                                    ,name
                                                                    from Learning_Assignment__c
                                                                    where Learning__c = :learning.Id
                                                                    and Learning_Version__c = :previewVersionId
                                                                    and User__c = :UserInfo.getUserId()
                                                                    and Is_Test_Assignment__c = true];

            if(previewAssignments.size()>0){
                //We found an existing test assignment, no need to create a new one, use this one instead
                previewAssignment = previewAssignments.get(0);
            }else{
                //There's no preview assignment, let's create one
                previewAssignment.Learning__c = learning.Id;
                previewAssignment.Learning_Version__c = previewVersionId;
                previewAssignment.Is_Test_Assignment__c = true;
                previewAssignment.User__c = UserInfo.getUserId();
                insert previewAssignment;
            }

            //Redirect to content launcher
            PageReference ref = null;

            if(learning.Custom_Preview_URL__c != null){
                ref = new PageReference(learning.Custom_Preview_URL__c);
            }else{

                if(currentRecordType == LMSConstants.RT_TASK){
                    ref = Page.TaskViewer;
                }else if(currentRecordType == LMSConstants.RT_TRAINING_RESOURCE){
                    ref = Page.ResourceViewer;
                }else if(currentRecordType == LMSConstants.RT_QUIZ){
                    ref = Page.QuizViewer;
                }else{
                    //Check for plugin launch URL
                    LMSPlugins.LearningConfig customLearningConfig = LMSPlugins.getLearningPluginConfig(currentRecordType);
                    ref = new PageReference(customLearningConfig.getLaunchURLWithNamespace());
                }

            }

            //Add common parameters to content launcher page
            ref.setRedirect(true);
            ref.getParameters().put('aid',previewAssignment.Id);
            ref.getParameters().put('pMode','true');

            return ref;
        }catch(Exception e){
            LMSUtils.logException(e,'LearningPreviewRedirectController');
            return null;
        }

    }
}
