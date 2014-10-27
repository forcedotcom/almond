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
public with sharing class Learning_Publish_Ext {

    public Learning__c learning{get;set;}
    public String selectedContent{get;set;}
    public Learning_Version__c dummyLearningVersion{get;set;}
    public Boolean enableVersionBehavior{get;private set;}

    private String currentRecordType;
    private ApexPages.StandardSetController contentsSSC{get;set;}

    private Map<String,String> rtObjectMapping;
    private Map<String,String> rtFieldMapping;

    public Learning_Publish_Ext(ApexPages.standardController cont){

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
            learning = [select Id
                                ,Name
                                ,Published__c
                                ,Current_published_version__c
                                ,Recordtype.DeveloperName
                                from Learning__c
                                where Id = :cont.getId()];
            init();

        }catch(Exception e){
            LMSUtils.logException(e,'Learning_Publish_Ext');
            LMSUtils.addGenericUnknownErrorMessage('Learning_Publish_Ext - init (1)');
        }
    }

    private void init(){

        //Init auxiliary field/object maps
        rtObjectMapping = new Map<String,String>{
           'task'=>'Task__c'
           ,'quiz'=>'Quiz__c'
           ,'resource'=>'Training_Resource__c'
        };

        rtFieldMapping = new Map<String,String>{
           'task'=>'Task__c'
           ,'quiz'=>'Quiz__c'
           ,'resource'=>'Training_Resource__c'
        };

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

        //Decide wheter we should enable versioning, e.g. not necessary if this is the first version
        enableVersionBehavior = true;
        if(learning.Current_Published_Version__c == null){
            enableVersionBehavior = false;
        }

        //Get the record type for the current learning
        currentRecordType = learning.recordType.developerName;
        currentRecordType = currentRecordType.toLowerCase();

        //Init a dummy learning version for showing versioning picklist in the UI
        dummyLearningVersion = new Learning_Version__c();

        //Init Standard set controller
        Id lid = learning.Id;
        String soql = 'select '+String.join(listSOQLFields,',')+' from '+LMSUtils.getPackageNamespace()+rtObjectMapping.get(currentRecordType)+' where Learning__c = :lid order by CreatedDate desc';
        contentsSSC = new ApexPages.StandardSetController(Database.getQueryLocator(soql));

    }

    public List<SObject> getContents() {
        return contentsSSC.getRecords();
    }

    public PageReference publishContent(){

        try{

            //BEGIN Access Check
            Map<Schema.sObjectType,List<String>> relatedFieldsObjectsView = new Map<Schema.sObjectType,List<String>>();
            relatedFieldsObjectsView.put(Learning_Version__c.sObjectType,new List<String>{'Version__c'});
            Map<Schema.sObjectType,List<String>> relatedFieldsObjectsCreate = new Map<Schema.sObjectType,List<String>>();
            relatedFieldsObjectsCreate.put(Learning_Version__c.sObjectType,new List<String>{'Learning__c','Type__c','Version__c','Version_Selection_Behavior__c'});
            Map<Schema.sObjectType,List<String>> relatedFieldsObjectsUpdate = new Map<Schema.sObjectType,List<String>>();
            relatedFieldsObjectsUpdate.put(Learning__c.sObjectType,new List<String>{'Published__c','Current_Published_Version__c'});

            LMS_ESAPI.isAuthorizedToView(relatedFieldsObjectsView);
            LMS_ESAPI.isAuthorizedToCreate(relatedFieldsObjectsCreate);
            LMS_ESAPI.isAuthorizedToUpdate(relatedFieldsObjectsUpdate);
            //END Access Check

            //Get latest version for the current learning
            Decimal latestVersion = 0;
            AggregateResult[] groupedResults = [SELECT MAX(Version__c) maxv from Learning_Version__c where learning__c = :learning.Id GROUP BY learning__c];
            if(groupedResults.size()>0 && groupedResults[0] != null){
                latestVersion = (Decimal)groupedResults[0].get('maxv');
            }
            latestVersion++;

            //Set Learning version information
            Learning_Version__c lVersion = new Learning_Version__c();
            lVersion.Learning__c = learning.Id;
            lVersion.Version_selection_behavior__c = dummyLearningVersion.Version_selection_behavior__c;
            lVersion.put(rtFieldMapping.get(currentRecordType),selectedContent);
            lVersion.Type__c = 'Published';
            lVersion.Version__c = latestVersion;
            insert lVersion;

            //Update learning with latest published version reference
            learning.Published__c = true;
            learning.Current_Published_Version__c = lVersion.Id;
            update learning;

            //Redirect to learning page
            return new PageReference('/'+learning.Id);

        }catch(Exception e){
            LMSUtils.logException(e,'Learning_Publish_Ext');
            LMSUtils.addGenericUnknownErrorMessage('Learning_Publish_Ext - init (1)');
            return null;
        }

    }

}
