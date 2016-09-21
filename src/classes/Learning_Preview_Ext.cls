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
public with sharing class Learning_Preview_Ext{

    public Learning__c learning{get;set;}
    @TestVisible
    private ApexPages.StandardSetController contentsSSC{get;set;}

    public Learning_Preview_Ext(ApexPages.StandardController cont){

        try{

            //BEGIN Access Check
            Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
            relatedFieldsObjects.put(Learning__c.sObjectType,new List<String>{
                'Id'
                ,'Name'
                ,'Published__c'
                ,'Current_Published_Version__c'
                ,'Custom_Preview_URL__c'
            });
            LMS_ESAPI.isAuthorizedToView(relatedFieldsObjects);
            //END Access Check

            //Fetch current learning information
            learning = LearningPreviewService.getLearningInfo(cont.getId());

            init();

         }catch(LMSPlugins.LMSPluginsException e){
             LMSUtils.addErrorMessage(e.getMessage());
         }catch(Exception e){
             LMSUtils.logException(e,'Learning_Preview_Ext');
             LMSUtils.addGenericUnknownErrorMessage('Learning_Preview_Ext - init (1)');
         }

    }

    private void init(){
                
        //Get the record type for the current learning
        String currentRecordType = learning.recordType.developerName;
        currentRecordType = currentRecordType.toLowerCase();

        List<String> listSOQLFields = new List<String>{
            'Id'
            ,'Name'
            ,'CreatedDate'
        };

        //BEGIN Access Check
        Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
        relatedFieldsObjects.put(Task__c.sObjectType,listSOQLFields);
        relatedFieldsObjects.put(Quiz__c.sObjectType,listSOQLFields);
        relatedFieldsObjects.put(Training_Resource__c.sObjectType,listSOQLFields);

        LMS_ESAPI.isAuthorizedToView(relatedFieldsObjects);
        //END Access Check

        LearningPreviewService.LearningMappings mappings = LearningPreviewService.getLearningMappings();
        Map<String,String> rtObjectMapping = mappings.rtObjectMapping;
        Map<String,String> rtFieldMapping = mappings.rtFieldMapping;
        Map<String,String> recordTypeNamespaceMap = mappings.recordTypeNamespaceMap;

        //Init Standard set controller
        Id lid = learning.Id;
        String soql = 'select '+String.join(listSOQLFields,',')+' from '+rtObjectMapping.get(currentRecordType)+' where '+recordTypeNamespaceMap.get(currentRecordType)+'Learning__c = :lid order by CreatedDate desc';
        contentsSSC = new ApexPages.StandardSetController(Database.getQueryLocator(soql));
    }

    //Get records from the standard set controller
    public List<SObject> getContents() {
        if(contentsSSC == null){
            return new List<SObject>();
        }
        return contentsSSC.getRecords();
    }

}
