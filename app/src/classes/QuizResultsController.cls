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
public with sharing class QuizResultsController{

    public String evalResult{get;private set;}
    public String evalScore{get;private set;}
    public Boolean showErrorButtons{get;private set;}
    public String messageStyle{get;set;}
    public String resultPreMessage{get;set;}
    public Boolean maxAttemptsReached{get;set;}
    public String redirectURL{get;set;}

    private Learning_Assignment__c assignment;
    private Boolean isPreview;

    public QuizResultsController(){
        init();
    }

    private void init(){

        try{

            //BEGIN Access Check
            //Note: we're excluding the following fields from the FLS check since some installations may want to remove view permissions
            //'Evaluation_Score__c','Evaluation_Result__c','Evaluation_Times_Taken__c'
            Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
            relatedFieldsObjects.put(Learning_Assignment__c.sObjectType,new List<String>{
                'Id'
                ,'Learning__c'
                ,'Training_Plan__c'
                ,'Learning__c'
                ,'Training_Plan_Section__c'
            });
            LMS_ESAPI.isAuthorizedToView(relatedFieldsObjects);
            //END Access Check

            maxAttemptsReached = false;
            isPreview = false;
            showErrorButtons = false;
            messageStyle = 'alert-danger';
            resultPreMessage = '';

            //Retrieve assignment id
            String aid = Apexpages.currentPage().getParameters().get('aid');
            String pMode = Apexpages.currentPage().getParameters().get('pMode');
            if(!String.isBlank(pMode)){
                isPreview = true;
            }

            //Retrieve assignment information
            if(!String.isBlank(aid)){

                //Fetch assignment information
                assignment = [select id
                                    ,Evaluation_Score__c
                                    ,Evaluation_Result__c
                                    ,Learning__c
                                    ,Training_Plan__c
                                    ,Training_Plan_Section__c
                                    ,Learning_Version__r.Quiz__r.Max_Attempts__c
                                    ,Evaluation_Times_Taken__c
                                    from Learning_Assignment__c
                                    where id = :aid limit 1];

                evalResult = assignment.Evaluation_Result__c;
                Decimal score = assignment.Evaluation_Score__c;
                evalScore = score.setScale(2).format();

                if(evalResult == LMSConstants.ASSIGNMENT_EVAL_PASSED){
                    messageStyle = 'alert-success';
                    resultPreMessage = 'Yes!';
                }

                if(!isPreview && assignment.Learning_Version__r.Quiz__r.Max_Attempts__c != null && evalResult != LMSConstants.ASSIGNMENT_EVAL_PASSED){
                    if(assignment.Evaluation_Times_Taken__c == assignment.Learning_Version__r.Quiz__r.Max_Attempts__c){
                        maxAttemptsReached = true;
                    }
                }

            }else{
                showErrorMessage();
            }
        }catch(Exception e){
            LMSUtils.logException(e,'QuizResultsController');
            LMSUtils.addGenericUnknownErrorMessage('QuizResultsController - init (1)');
            showErrorMessage();
        }
    }

    private void showErrorMessage(){
        showErrorButtons = true;
    }

    public PageReference quizContinue(){
        redirectURL = null;
        PageReference ref = Page.MyTraining;

        if(isPreview){
            ref = new PageReference('/'+assignment.Learning__c);
        }else{
            ref = Page.TrainingPlanDetail;
            ref.getParameters().put('id',assignment.Training_Plan__c);
            ref.getParameters().put('section',assignment.Training_Plan_Section__c);
        }

        ref.getParameters().put('aid',assignment.id);
        ref.setRedirect(true);
        redirectURL = ref.getUrl();
        return null;

    }

}
