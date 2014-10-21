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
global with sharing class ResourceViewerController{

    public Boolean continueRedirection{get;private set;}
    private Boolean isPreviewMode{get;set;}{isPreviewMode = false;}

    public ResourceViewerController(){
        init();
    }

    private void init(){

        //Retrieve assignment id
        String aid = Apexpages.currentPage().getParameters().get('aid');
        //Retrieve preview mode flag
        if(!String.isBlank(Apexpages.currentPage().getParameters().get('pMode'))){
            isPreviewMode = true;
        }
        continueRedirection = false;

        try{

            if(!String.isBlank(aid)){

                Learning_Assignment__c assignment = getAssignment(aid);

                if(assignment.Learning_Version__r.Training_Resource__c == null){
                    LMSUtils.addErrorMessage('Invalid Assignment Id');
                }else{
                    continueRedirection = true;
                }


            }else{
                LMSUtils.addErrorMessage('Invalid Assignment Id');
            }

        }catch(Exception e){
	     	LMSUtils.logException(e,'ResourceViewerController');
	     	LMSUtils.addGenericUnknownErrorMessage('ResourceViewerController - init (1)');
        }
    }

    @RemoteAction
    global static String redirectToResource(String aid){

        Learning_Assignment__c assignment = getAssignment(aid);
        Training_Resource__c resource = assignment.Learning_Version__r.Training_Resource__r;

    	//CRUD/FLS not enforced here as we don't want to give update create or edit access to the learning assignment object to LMS Users
        //Update assignment status
        if(!assignment.Learning_Version__r.Training_Resource__r.Prevent_completion_on_launch__c){
	        assignment.Progress__c = LMSConstants.ASSIGNMENT_STATUS_COMPLETED;
	        assignment.Progress_Percentage__c = 100;
	        assignment.Evaluation_Result__c = 'N/A';
	        update assignment;
        }

        //Redirect to external resource
        String resourceURL = resource.Resource_URL__c;

        //Add https prefix in case protocol is not present in the resource url
        if(!resourceURL.startsWith('http')){
        	resourceURL = 'https://'+resourceURL;
        }

        PageReference ref = new PageReference(resourceURL);
        if(resource.Add_training_parameters_to_URL__c){
            ref.getParameters().put('aid',assignment.Id);
            ref.getParameters().put('tid',assignment.Training_Plan__c);
        }
        String resultURL = ref.getURL();
        return resultURL;

    }

    private static Learning_Assignment__c getAssignment(String aid){

		//BEGIN Access Check
			Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
	        relatedFieldsObjects.put(Learning_Assignment__c.sObjectType,new List<String>{
				'Id'
				,'Name'
				,'User__c'
				,'Contact__c'
				,'Learning__c'
				,'Progress__c'
				,'Training_Plan__c'
				,'Shared_Learning_Assignment__c'
	        });
	        relatedFieldsObjects.put(Training_Resource__c.sObjectType,new List<String>{
				'Id'
				,'Name'
				,'Resource_URL__c'
				,'Add_training_parameters_to_URL__c'
	        });
			LMS_ESAPI.isAuthorizedToView(relatedFieldsObjects);
		//END Access Check

        Learning_Assignment__c assignment = [select id
                                                    ,User__c
                                                    ,Contact__c
                                                    ,Name
                                                    ,Learning__c
                                                    ,Learning_Version__c
                                                    ,Learning_Version__r.Training_Resource__c
                                                    ,Learning_Version__r.Training_Resource__r.Id
                                                    ,Learning_Version__r.Training_Resource__r.Name
                                                    ,Learning_Version__r.Training_Resource__r.Resource_URL__c
                                                    ,Learning_Version__r.Training_Resource__r.Add_training_parameters_to_URL__c
                                                    ,Learning_Version__r.Training_Resource__r.Prevent_completion_on_launch__c
                                                    ,Progress__c
                                                    ,Progress_Percentage__c
                                                    ,Evaluation_Result__c
                                                    ,Evaluation_Score__c
                                                    ,Training_Plan__c
                                                    ,Shared_Learning_Assignment__c
                                                    from Learning_Assignment__c
                                                    where id = :aid
                                                    and User__c = :UserInfo.getUserId()];

        return assignment;
    }

}
