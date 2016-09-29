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
public with sharing class QuestionNewController{

    public Question__c question{get;set;}
    private Answer_Sequence__c answerSequence {get;set;}
    public List<Answer_Sequence_Item__c> lanswerseqitems {get;set;}
    public Boolean banswerseq {get;set;}
    public Boolean banswernum {get;set;}
    public Boolean banswerbool {get;set;}
    public String questiontype {get;set;}
    public String qlid {get; private set;}

    //Note: still need to handle deleting answer sequence items on edit
    //Note: might need some refactoring when all functionality is in place

    //initialize
    public QuestionNewController(ApexPages.StandardController controller){

        try{

            //default all boolean flags
            setDefaults();

            if(!Test.isRunningTest()){
                //add all Question__c fields used on vf page
                controller.addFields(new List<String>{'Name','Description__c','Description_RTA__c','Type__c', 'Order__c', 'Correct_Number__c' , 'Correct_Boolean__c', 'Answer_Sequence__c'});
            }

            //record id
            String recid = controller.getRecord().Id;

            //initliaize question record
            if(String.isNotBlank(recid)){
                question = (Question__c)controller.getRecord();
                Question__c questionDetails = getQuestionDetails(question.Id);
                if(questionDetails != null){
                    qlid = questionDetails.Question_Line__c;
                }
                editmode();
            }else{
                answerSequence = new Answer_Sequence__c();
                question = new Question__c();
                ApexPages.PageReference currentRef = ApexPages.CurrentPage();
                if(LMSUtils.inSF1Context(currentRef)){
                    qlid = LMSUtils.getLKID(currentRef, Question_Line__c.SObjectType);
                }else{
                    qlid = currentRef.getParameters().get('retURL');
                }
                question.Question_Line__c = qlid != null ? qlid.replace('/', '') : null;
                qlid = question.Question_Line__c;
            }

        }catch(Exception e){
            LMSUtils.logException(e,'QuestionNewController');
            LMSUtils.addGenericUnknownErrorMessage('QuestionNewController - constructor (1)');
        }

    }

    private Question__c getQuestionDetails(Id questionId){
        List<Question__c> qDetails = [select id,Question_Line__c from Question__c where id = :questionId limit 1];
        if(qDetails.size() > 0){
            return qDetails.get(0);
        }else{
            return null;
        }
    }

    public void editmode(){

        //BEGIN Access Check
        Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
        relatedFieldsObjects.put(Question__c.sObjectType,new List<String>{
            'Description__c'
            ,'Description_RTA__c'
            ,'Type__c'
            ,'Order__c'
            ,'Correct_Number__c'
            ,'Correct_Boolean__c'
        });
        relatedFieldsObjects.put(Answer_Sequence__c.sObjectType,new List<String>{
            'Id'
            ,'Internal_Notes__c'
        });
        relatedFieldsObjects.put(Answer_Sequence_Item__c.sObjectType,new List<String>{
            'Id'
            ,'Item_Id__c'
            ,'Answer_Text__c'
            ,'Is_Correct_Answer__c'
            ,'Order__c'
            ,'Answer_Sequence__c'
        });
        LMS_ESAPI.isAuthorizedToView(relatedFieldsObjects);
        //END Access Check

        banswerseq = question.Answer_Sequence__c != null ? true : false;
        banswernum = question.Type__c == 'Number' ? true : false;
        banswerbool = question.Type__c == 'Boolean' ? true : false;
        questiontype = question.Type__c;

        if(banswerseq){
            answerSequence = [select Id, Internal_Notes__c from Answer_Sequence__c where Id =: question.Answer_Sequence__c];

            lanswerseqitems = [select Id,
                                    Item_Id__c,
                                    Answer_Text__c,
                                    Is_Correct_Answer__c,
                                    Order__c,
                                    Answer_Sequence__c from Answer_Sequence_Item__c where Answer_Sequence__c =: question.Answer_Sequence__c];
        }
    }

    //enable types of question
    public PageReference answerseqenabler(){

        setDefaults();

        if(!String.isBlank(questiontype) ){

            if(questiontype == 'SelectMultipleQuestion' || questiontype == 'SelectOneQuestion'){
                banswerseq = true;
                //initializes Answer Sequence Item list
                lanswerseqitems = new List<Answer_Sequence_Item__c>();
                lanswerseqitems.add(new Answer_Sequence_Item__c());
            }

            if(questiontype == 'Number'){
                banswernum = true;
            }

            if(questiontype == 'Boolean'){
                banswerbool = true;
            }

        }

        return null;
    }

    public void setDefaults(){
        banswerseq = false;
        banswernum = false;
        banswerbool = false;
    }

    //call with actionfunction
    public PageReference addanswerseqitem(){
        lanswerseqitems.add(new Answer_Sequence_Item__c());
        return null;
    }

    public PageReference c_save(){

        try{

            //BEGIN Access Check
            Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
            relatedFieldsObjects.put(Question__c.sObjectType,new List<String>{
                'Description__c'
                ,'Description_RTA__c'
                ,'Type__c'
                ,'Order__c'
                ,'Correct_Number__c'
                ,'Correct_Boolean__c'
            });
            relatedFieldsObjects.put(Answer_Sequence_Item__c.sObjectType,new List<String>{
                'Answer_Text__c'
                ,'Is_Correct_Answer__c'
                ,'Order__c'
                ,'Answer_Sequence__c'
            });
            relatedFieldsObjects.put(Question__c.sObjectType,new List<String>{
                'Answer_Sequence__c'
                ,'Type__c'
            });
            LMS_ESAPI.isAuthorizedToCreate(relatedFieldsObjects);
            LMS_ESAPI.isAuthorizedToUpdate(relatedFieldsObjects);
            //END Access Check

            if(banswerseq){
                upsert answerSequence;

                for(Answer_Sequence_Item__c asi : lanswerseqitems){
                    asi.Answer_Sequence__c = answerSequence.Id;
                }

                upsert lanswerseqitems;

                question.Answer_Sequence__c = answerSequence.Id;
                upsert question;

            }else{
                upsert question;
                //Note: need to handle deleting Answer Sequence & Answer Sequence Items in case Type changes on edit from options to Text, Boolean or Number
            }
        }catch(Exception e){
            LMSUtils.addErrorMessage(e.getMessage());
            LMSUtils.logException(e,'QuestionNewController');
            LMSUtils.addGenericUnknownErrorMessage('QuestionNewController - c_save (2)');
            return null;
        }

        PageReference refPage = new PageReference ('/' + question.id);
        refPage.setRedirect(true);
        return refPage;
    }

    public PageReference c_save_new(){

        PageReference saveRef = c_save();
        if(saveRef != null){
            ApexPages.PageReference currentRef = ApexPages.CurrentPage();
            PageReference refPage = Page.QuestionNew;
            refPage.getParameters().put('retURL','/'+qlid);
            if(LMSUtils.inSF1Context(currentRef)){
                refPage.getParameters().put('isdtp', 'p1');
                refPage.getParameters().put('_lkid', qlid);
            }
            refPage.setRedirect(true);
            return refPage;
        }else{
            return saveRef;
        }

    }

    public PageReference cancel(){
        ApexPages.PageReference currentRef = ApexPages.CurrentPage();
        if(LMSUtils.inSF1Context(currentRef)){
            Id parentQLId = LMSUtils.getLKID(currentRef, null);
            String retId = '';
            if(parentQLId == null){
                if(question.Id != null){
                  retId = question.Id;
                }
            }else{
                retId = parentQLId;
            }
            return new PageReference('/'+retId);
        }else{
            String returl = ApexPages.CurrentPage().getParameters().get('retURL');
            PageReference refPage = new PageReference (returl);
            refPage.setRedirect(true);
            return refPage;
        }
    }

}
