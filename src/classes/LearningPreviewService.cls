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
public with sharing class LearningPreviewService {
  
    public with sharing class LearningMappings{
        public Map<String,String> rtObjectMapping{get;set;}
        public Map<String,String> rtFieldMapping{get;set;}
        public Map<String,String> recordTypeNamespaceMap{get;set;}
    }

    public static LearningPreviewService.LearningMappings getLearningMappings(){
        
        LearningPreviewService.LearningMappings result = new LearningPreviewService.LearningMappings();
        
        //Init auxiliary field/object maps
        Map<String,String>  rtObjectMapping = new Map<String,String>{
         'task'=>'Task__c'
         ,'quiz'=>'Quiz__c'
         ,'resource'=>'Training_Resource__c'
        };

        Map<String,String>  rtFieldMapping = new Map<String,String>{
         'task'=>'Task__c'
         ,'quiz'=>'Quiz__c'
         ,'resource'=>'Training_Resource__c'
        };
        
        Map<String,String> recordTypeNamespaceMap = new Map<String,String>();

        //Update the object names with the package namespace
        for(String rtKey : rtObjectMapping.keySet()){
            String objectName = rtObjectMapping.get(rtKey);
            rtObjectMapping.put(rtKey, LMSUtils.getPackageNamespace()+objectName);
        }

        //Get additional record types for learning plugins
        String learningObjectName = LMSUtils.getPackageNamespace()+'Learning__c';
        
        for(RecordType rt : [select Id,DeveloperName from RecordType where SobjectType = :learningObjectName]){
            String developerName = (rt.DeveloperName).toLowerCase();
            //Skip standard learnings
            if(rtObjectMapping.containsKey(developerName)){
                recordTypeNamespaceMap.put(developerName,LMSUtils.getPackageNamespace());
                continue;
            }
            LMSPlugins.LearningConfig customLearningConfig = LMSPlugins.getLearningPluginConfig(rt.DeveloperName);
            String nameSpacePrefix = String.isBlank(customLearningConfig.namespacePrefix)?'':customLearningConfig.namespacePrefix+'__';
            recordTypeNamespaceMap.put(developerName,nameSpacePrefix);
            rtObjectMapping.put(developerName, nameSpacePrefix+customLearningConfig.objectName);
            rtFieldMapping.put(developerName, nameSpacePrefix+customLearningConfig.learningVersionLookupField);
        }
        
        result.recordTypeNamespaceMap = recordTypeNamespaceMap;
        result.rtObjectMapping = rtObjectMapping;
        result.rtFieldMapping = rtFieldMapping;
        
        return result;
      
    }
    
    public static Learning__c getLearningInfo(Id learningId){
        List<Learning__c> learnings = [select id
                                            ,name
                                            ,published__c
                                            ,current_published_version__c
                                            ,recordtype.developerName
                                            ,Custom_Preview_URL__c
                                            from Learning__c
                                            where id = :learningId];
        if(learnings.size() == 0){
            return null;
        }
        return learnings.get(0);
    }
  
}
