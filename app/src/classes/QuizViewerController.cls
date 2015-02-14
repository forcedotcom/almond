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
public with sharing class QuizViewerController extends LMSBaseController{

    public Quiz__c quiz{get;set;}
    public Question_Line__c questionLine{get; private set;}
    public Question_Line__c startQuestionLine{get;private set;}
    public Question_Line__c finishQuestionLine{get;private set;}
    public List<QuizItem> quizItemList { get ; set; }
    public Integer totalPages{get; private set;}
    public Integer progress{get; private set;}
    public Learning_Assignment__c assignment {get;private set;}
    private Learning_Version__c learningVersion;

    private List<Id> qlNavigation = new List<Id>();
    private Map<Id,Response__c> responseMap = new Map<Id, Response__c>();


    private Boolean isPreviewMode{get;set;}

    //Navigation logic
    public Boolean showStartButton {get {return questionLine.Id != startQuestionLine.Id;}}
    public Boolean showDoneButton {get {return questionLine.Id == finishQuestionLine.Id;}}
    public Boolean showNextButton {get {return questionLine.Id != finishQuestionLine.Id;}}
    public Boolean showPreviousButton {get {return !qlNavigation.isEmpty();}}
    public Boolean hasMessages{get{return ApexPages.hasMessages();}}

    public Boolean showBackNoSaveMessage{get;set;}

    public QuizViewerController(){
        quizItemList = new List<QuizItem>();
        totalPages = 0;
        progress = 0;
        isPreviewMode = false;
        showBackNoSaveMessage = false;

        initQuiz();
    }

    //Inner exception class
    public class QuizException extends Exception{}

    //Initialize quiz parameters
    private void initQuiz(){

        //Retrieve assignment id
        String aid = Apexpages.currentPage().getParameters().get('aid');
        //Retrieve quiz id
        String qid = Apexpages.currentPage().getParameters().get('qid');
        //Retrieve preview mode flag
        if(String.isNotBlank(Apexpages.currentPage().getParameters().get('pMode'))){
            isPreviewMode = true;
        }

        try{

            if(String.isNotBlank(aid)){

                assignment = LMSService.getLearningAssignmentDetails(aid,UserInfo.getUserId());
                LMSService.WithoutSharingOps wsops = new LMSService.WithoutSharingOps();
                learningVersion = wsops.getLearningVersionDetails(assignment.Learning_Version__c,'Quiz');
                Learning__c assignmentLearning = wsops.getLearningDetails(assignment.Learning__c);

                if(learningVersion.Quiz__c == null){
                    LMSUtils.addErrorMessage(System.Label.ALMS_Invalid_Assignment_Id);
                    return;
                }else{
                    quiz = learningVersion.Quiz__r;
                    if(quiz.Description__c == null){
                        quiz.Description__c = assignmentLearning.Description__c;
                    }
                }

                //Fetch quiz question lines
                List<Question_Line__c> questionLines = wsops.getQuizQuestionLines(quiz.Id);

                //Set default start question if no question line parameter is present
                String ql = Apexpages.currentPage().getParameters().get('ql') ;
                if (String.isBlank(ql)){
                    ql = questionLines.get(0).Id;
                }
                //Set question line object
                questionLine = questionLines.get(0);
                startQuestionLine = questionLines.get(0);
                finishQuestionLine = questionLines.get(questionLines.size()-1);

                //Set progress data
                totalPages = questionLines.size();

            }else{
                LMSUtils.addErrorMessage(System.Label.ALMS_Invalid_Assignment_Id);
                return;
            }

        }catch(Exception e){
            LMSUtils.logException(e,'QuizViewerController');
            LMSUtils.addGenericUnknownErrorMessage('QuizViewerController - initQuiz (1)');
        }

    }

    public PageReference initializeQuestions() {

        //Verify if user can continue taking the quiz
        if(!isAllowedToTakeQuiz()){
            return redirectToResultsPage();
        }

        showBackNoSaveMessage = false;
        try{

            LMSService.WithoutSharingOps wsops = new LMSService.WithoutSharingOps();

            //Retrieve question line information
            questionLine = wsops.getQuestionLineDetails(quiz.Id,questionLine.Id);

            //Retrieve questions for the current question line
            List<Question__c> questions = wsops.getQuestionsForQuestionLine(questionLine.Id);

            //Collect Answer Sequence Ids for the current questions
            Set<Id> answerSequenceIDs = new Set<Id>();
            for (Question__c q : questions) {
                if (q.Answer_Sequence__c != null) {
                    answerSequenceIDs.add(q.Answer_Sequence__c);
                }
            }

            //Retrieve info for related answer sequences
            Map<Id,Answer_Sequence__c> answerSequencesMap = wsops.fetchAnswerSequences(answerSequenceIDs);

            // prepare the final list that will drive the page
            quizItemList.clear();

            //Fetch existing responses
            responseMap = fetchExistingResponses(assignment.Id,assignment.Shared_Learning_Assignment__c,questionLine.Id,null);

            //Initialize wrapper list and set values for new responses
            for (Question__c q : questions) {
                Response__c re = responseMap.get(q.Id);
                if ( re == null ) {
                    re = new Response__c(Learning_Assignment__c = assignment.id
                                        ,Shared_Learning_Assignment__c = assignment.Shared_Learning_Assignment__c
                                        ,Question__c = q.id
                                        ,User__c = assignment.User__c
                                        ,OwnerId = assignment.User__c);
                    responseMap.put(q.Id, re);
                }
                QuizItem qi = new QuizItem(q,assignment,re);
                qi.answers = answerSequencesMap.get(q.Answer_Sequence__c);
                quizItemList.add(qi);
            }

        }catch(Exception e){
            LMSUtils.logException(e,'QuizViewerController');
            LMSUtils.addGenericUnknownErrorMessage('QuizViewerController - initializeQuestions (2)');
        }

        return null;
    }

    //Redirect user to the training plan page
    public PageReference backToTrainingPlan(){
        PageReference ret = Page.TrainingPlanDetail;
        if(isPreviewMode){
          ret = new PageReference('/'+assignment.Learning__c);
        }else{
          ret.getParameters().put('id',assignment.Training_Plan__c);
        }
        ret.setRedirect(true);
        return ret;
    }

    //Reset progress to the first page
    public PageReference reset() {
        PageReference ret = Page.QuizViewer;
        ret.setRedirect( true );
        ret.getParameters().put('aid',Apexpages.currentPage().getParameters().get('aid'));
        return ret;
    }

    //Save responses and move to the previous question line
    public PageReference previous() {

        try {
            saveResponses(true);

            questionLine = new Question_Line__c(id = qlNavigation.remove(qlNavigation.size()-1));
            PageReference ret = Page.QuizViewer;
            return ret;

        }catch(QuizException qe){
            showBackNoSaveMessage = true;
            LMSUtils.addErrorMessage(qe.getMessage());
        }catch(Exception e) {
            showBackNoSaveMessage = true;
            LMSUtils.logException(e,'QuizViewerController');
            LMSUtils.addGenericUnknownErrorMessage('QuizViewerController - previous (3)');
        }
        return null;
    }

    //Return to the previous page without save
    public PageReference previousNoSave() {
        questionLine = new Question_Line__c(id = qlNavigation.remove(qlNavigation.size()-1));
        PageReference ret = Page.QuizViewer;
        return ret;
    }

    //Save responses and move to the next question line
    public PageReference next() {

        try {

            LMSService.WithoutSharingOps wsops = new LMSService.WithoutSharingOps();

            saveResponses(true);

            List<Question_Line__c> orderedQuestionLines = wsops.getQuizOrderedQuestionLines(quiz.Id,questionLine.Id,questionLine.Order__c);

            //Fetch next question lines and define the next page
            for (Question_Line__c ql : orderedQuestionLines) {

                //Store the question we came from in navigation list
                if ( questionLine != null ) {
                    qlNavigation.add(questionLine.Id);
                }

                questionLine = ql;
                PageReference ref = Page.QuizViewer;
                return ref;

            }

            LMSUtils.addErrorMessage(System.Label.ALMS_No_Remaining_Question_Lines);

        }catch(QuizException qe){
            LMSUtils.addErrorMessage(qe.getMessage());
        } catch(Exception e) {
            LMSUtils.logException(e,'QuizViewerController');
            LMSUtils.addGenericUnknownErrorMessage('QuizViewerController - next (4)');
        }
        return null;
    }

    //Submit quiz, save answers and redirect to completed page
    public PageReference done() {

        try {
            //Don't recalculate progress for final action, this is done in the updateAssignmentFinalScore method
            saveResponses(false);

            updateAssignmentFinalScore();

            return redirectToResultsPage();

        }catch(QuizException qe){
            LMSUtils.addErrorMessage(qe.getMessage());
        }catch(Exception e) {
            LMSUtils.logException(e,'QuizViewerController');
            LMSUtils.addGenericUnknownErrorMessage('QuizViewerController - done (5)');
        }
        return null;

    }

    //Redirect to results page
    public PageReference redirectToResultsPage() {
        PageReference ret = Page.QuizResults;
        String networkName = LMSUtils.getCurrentNetworkURLPath();
        String namespace = '';
        if(LMSUtils.getPackageNamespace() != null){
            namespace = LMSUtils.getPackageNamespace();
        }
        if(networkName != null){
            ret = new PageReference('/'+networkName+'/apex/'+namespace+'QuizResults');
        }
        ret.setRedirect( true );
        ret.getParameters().put('aid',Apexpages.currentPage().getParameters().get('aid') );

        if(isPreviewMode){
            ret.getParameters().put('pMode','true');
        }
        return ret;
    }

    //Save the responses captured in the current questionline
    public PageReference saveResponses(Boolean updateProgress) {

        List<Response__c> tosave = new List<Response__c>();

        for (QuizItem qi : quizItemList) {
            tosave.add(qi.response);
            Boolean missingAnswer = false;
            // TODO : Add different error message based on question type
            if ((qi.question.Type__c == 'SelectOneQuestion' || qi.question.Type__c == 'SelectMultipleQuestion' ) && String.isBlank(qi.response.Response_Answer_Sequence_Long__c)) {
                missingAnswer = true;
            }else if(qi.question.Type__c == 'Text' && String.isBlank(qi.response.Response_Text_Long__c)){
                missingAnswer = true;
            }else if(qi.question.Type__c == 'Number' && qi.response.Number_Response__c == null){
                missingAnswer = true;
            }else if(qi.question.Type__c == 'Boolean' && String.isBlank(qi.response.Boolean_Response__c)){
                missingAnswer = true;
            }

            if(missingAnswer){
              throw new QuizException(System.Label.ALMS_Quiz_Missing_Answers);
            }
        }

        //Update responses
        LMSService.WithoutSharingOps wsops = new LMSService.WithoutSharingOps();
        wsops.upsertResponses(tosave);

        if(updateProgress){
            updateAssignmentProgress();
        }

        return null;
    }


    private void updateAssignmentProgress(){

        if(isPreviewMode){
            LearningAssignmentsHelper.previewMode = true;
        }

        if(learningVersion.Quiz__r.Total_Questions__c != null){

            LMSService.WithoutSharingOps wsops = new LMSService.WithoutSharingOps();

            Integer respCount = wsops.getAssignmentResponseCount(assignment.Id, learningVersion.Quiz__c);

            Double newProgress = respCount/learningVersion.Quiz__r.Total_Questions__c;
            assignment.Progress_Percentage__c = newProgress*100;
            assignment.Progress__c = LMSConstants.ASSIGNMENT_STATUS_IN_PROGRESS;

            //No CRUD/FLS enforced here as Users don't have access to update the learning assignment object
            update assignment;

        }

    }

    private void updateAssignmentFinalScore(){

        LMSService.WithoutSharingOps wsops = new LMSService.WithoutSharingOps();

        if(assignment.Evaluation_Times_Taken__c == null){
            assignment.Evaluation_Times_Taken__c = 0;
        }

        assignment.Evaluation_Times_Taken__c++;


        //If running in preview mode
        if(isPreviewMode){
            LearningAssignmentsHelper.previewMode = true;
        }

        //Calculate Score

        //Fetch all quiz questions
        Map<Id,Question__c> quizQuestions = wsops.getQuestionsForQuiz(quiz.Id);

        Set<Id> answerQuestionIds = new Set<Id>();
        for(Question__c q : quizQuestions.values()){
            if(q.Answer_Sequence__c != null){
                answerQuestionIds.add(q.Answer_Sequence__c);
            }
        }

        //Fetch all question answer sequences
        Map<Id,Answer_Sequence__c> mapQuizAnswerSequences = wsops.fetchAnswerSequences(answerQuestionIds);

        //Evaluate responses
        Map<Id,Response__c> responseMap = fetchExistingResponses(assignment.Id,assignment.Shared_Learning_Assignment__c,null,quiz.Id);

        Integer correctQuestionCounter = 0;
        List<Response__c> responsesToUpdate = new List<Response__c>();

        for(Id questionId : responseMap.keySet()){

            Question__c q = quizQuestions.get(questionId);

            if(q != null){

                Response__c resp = responseMap.get(questionId);
                Boolean isCorrect = false;

                //Get correct answers for the current question
                Set<String> correctAnswers =new Set<String>();
                Set<String> currentAnswer =new Set<String>();

                if((q.Type__c == 'SelectOneQuestion' || q.Type__c == 'SelectMultipleQuestion') && q.Answer_Sequence__c != null){

                    Answer_Sequence__c aseq = mapQuizAnswerSequences.get(q.Answer_Sequence__c);
                    for(Answer_Sequence_Item__c asi : aseq.Answer_Sequence_Items__r){
                        if(asi.Is_Correct_Answer__c){
                            correctAnswers.add(asi.Item_Id__c);
                        }
                    }

                    if(correctAnswers.size()>0){
                        //Get answers for the current response
                        if(resp.Question_Type__c == 'SelectOneQuestion' || resp.Question_Type__c== 'SelectMultipleQuestion'){
                            String selectedAnswerSequence = resp.Response_Answer_Sequence_Long__c;
                            if(selectedAnswerSequence != null){
                                Set<String> selectedAnswersSet = new Set<String>();
                                selectedAnswersSet.addAll(selectedAnswerSequence.split(';',0));
                                if(resp.Question_Type__c == 'SelectOneQuestion'){
                                    if(correctAnswers.removeAll(selectedAnswersSet)){
                                        correctQuestionCounter++;
                                        isCorrect = true;
                                    }
                                }else if(resp.Question_Type__c== 'SelectMultipleQuestion'){
                                    if(selectedAnswersSet.containsAll(correctAnswers) && selectedAnswersSet.size() == correctAnswers.size()){
                                        correctQuestionCounter++;
                                        isCorrect = true;
                                    }
                                }
                            }
                        }
                    }

                }else if(q.Type__c == 'Number' && q.Correct_Number__c != null){

                    if(resp.Number_Response__c == q.Correct_Number__c){
                        correctQuestionCounter++;
                        isCorrect = true;
                    }
                }else if(q.Type__c == 'Boolean' && q.Correct_Boolean__c != null){

                    if(resp.Boolean_Response__c == q.Correct_Boolean__c){
                        correctQuestionCounter++;
                        isCorrect = true;
                    }
                }else{
                    //Unsupported types will be marked as correct
                    correctQuestionCounter++;
                    isCorrect = true;
                }

                if(resp != null){
                    resp.Correct_Response__c = isCorrect;
                    responsesToUpdate.add(resp);
                }

            }

        }

        Double finalScore = (correctQuestionCounter/quiz.Total_Questions__c)*100;
        assignment.Evaluation_Score__c = finalScore;
        if(quiz.Passing_Score__c == null || finalScore >= quiz.Passing_Score__c){
            assignment.Evaluation_Result__c = LMSConstants.ASSIGNMENT_EVAL_PASSED;
            assignment.Progress__c = LMSConstants.ASSIGNMENT_STATUS_COMPLETED;
            assignment.Progress_Percentage__c = 100;
        }else{
            assignment.Evaluation_Result__c = LMSConstants.ASSIGNMENT_EVAL_FAILED;
            assignment.Progress_Percentage__c = 100;
        }

        //No CRUD/FLS enforced here as Users don't have access to update the learning assignment object
        update assignment;

        if(quiz != null && quiz.Delete_Responses_On_Submission__c){
            LMSService.deleteResponsesForAssignment(assignment.id, assignment.Shared_Learning_Assignment__c);
        }else{
          //Update correct response flag at the response level
          //No CRUD/FLS enforced here as Users don't have access to update the correct response flag object
          if(!LMSSettings.getDisableCorrectResponseCheckbox() && responsesToUpdate.size()>0){
              wsops.upsertResponses(responsesToUpdate);
          }
        }

    }

    private Map<Id,Response__c> fetchExistingResponses(Id assignmentId, Id sharedAssignmentId, Id questionLineId, Id quizId){

        LMSService.WithoutSharingOps wsops = new LMSService.WithoutSharingOps();

        List<Response__c> responses = wsops.getQuizResponses(quizId, questionLineId, assignmentId, sharedAssignmentId);

        Map<Id,Response__c> responseMap = new Map<Id, Response__c>();

        for (Response__c r: responses) {
            responseMap.put(r.Question__c,r);
        }

        return responseMap;
    }

    private Boolean isAllowedToTakeQuiz(){

        if(!isPreviewMode){
            if(assignment.Progress__c == LMSConstants.ASSIGNMENT_STATUS_COMPLETED && assignment.Evaluation_Result__c == LMSConstants.ASSIGNMENT_EVAL_PASSED){
                return false;
            }

            if(learningVersion.Quiz__r.Max_Attempts__c != null && assignment.Evaluation_Result__c != LMSConstants.ASSIGNMENT_EVAL_PASSED){
                if(assignment.Evaluation_Times_Taken__c == learningVersion.Quiz__r.Max_Attempts__c){
                    return false;
                }
            }
        }

        return true;
    }


}
