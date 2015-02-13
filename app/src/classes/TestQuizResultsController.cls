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
@isTest
private class TestQuizResultsController{

    static testMethod void testPassingResults(){

        //Create admin users
        List<User> adminUsers = TestUtilClass.createUsers(1,'System Administrator');
        List<User> lmsUsers = TestUtilClass.createUsers(1,'Standard User');

        System.runAs(adminUsers.get(0)){
            //Assign corresponding perm sets
            TestUtilClass.addPermissionSet(adminUsers,'LMS_Admin');
            TestUtilClass.addPermissionSet(lmsUsers,'LMS_User');
        }

        Id learningAssignmentId = createSampleData(adminUsers,lmsUsers,createQuizLearnings());

        List<Learning_Assignment__c> lassignment = [select Id,
                                                            Learning__c, Learning_Version__r.Quiz__c from Learning_Assignment__c
                                                            where Id = :learningAssignmentId];

        System.assert(lassignment.size() == 1, 'Learning Assignment issues, size = ' + lassignment.size());
        System.assert(lassignment.get(0).Learning_Version__r.Quiz__c != null, 'Learning Assignment is not for Quiz');

        //Answer all the quiz questions
        Set<Id> qlineIds = new Set<Id>();
        for(Question_Line__c oql : [select Id from Question_Line__c where Quiz__c =: lassignment.get(0).Learning_Version__r.Quiz__c]){
            qlineIds.add(oql.Id);
        }

        Map<String, Response__c> mResponses = TestLearningData.createTestQuestionResponses(qlineIds, lmsUsers.get(0).Id, lassignment.get(0).Id);

        Test.startTest();
            System.runAs(lmsUsers.get(0)){
                PageReference pageRef = Page.QuizViewer;
                Test.setCurrentPage(pageRef);
                pageRef.getHeaders().put('User-Agent', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.6; rv:25.0) Gecko/20100101 Firefox/25.0');
                pageRef.getParameters().put('aid', learningAssignmentId);
                QuizViewerController controller = new QuizViewerController();
                controller.initializeQuestions();

                //first section
                List<QuizItem> lqi = controller.quizItemList;

                for(QuizItem qi : lqi){
                	qi.response = mResponses.get(qi.question.Id);
                }
                controller.next();
                controller.initializeQuestions();

                //second section
                List<QuizItem> lqi2 = controller.quizItemList;

                for(QuizItem qi : lqi2){
                	qi.response	 = mResponses.get(qi.question.Id);
                }
                controller.next();
                controller.initializeQuestions();

                //third & final section
                List<QuizItem> lqi3 = controller.quizItemList;

                for(QuizItem qi : lqi3){
                    qi.response	 = mResponses.get(qi.question.Id);
                }
                controller.done();

            }
        Test.stopTest();

        System.runAs(lmsUsers.get(0)){
            //Switch to quiz results page
            PageReference pageRef = Page.QuizResults;
            pageRef.getParameters().put('aid',learningAssignmentId);
            Test.setCurrentPage(pageRef);
            QuizResultsController cont = new QuizResultsController();
            System.assertEquals(LMSConstants.ASSIGNMENT_EVAL_PASSED,cont.evalResult);
            PageReference contRef = cont.quizContinue();
            PageReference dummyRef = new PageReference(cont.redirectURL);
            System.assert(dummyRef.getParameters().get('id') != null,'Result does not contain assignment id');
            System.assert(countAssignmentResponses(learningAssignmentId) > 0, 'No responses were captured');
        }

    }

    static testMethod void testMissingSelectMultipleValues(){

        //Create admin users
        List<User> adminUsers = TestUtilClass.createUsers(1,'System Administrator');
        List<User> lmsUsers = TestUtilClass.createUsers(1,'Standard User');

        System.runAs(adminUsers.get(0)){
            //Assign corresponding perm sets
            TestUtilClass.addPermissionSet(adminUsers,'LMS_Admin');
            TestUtilClass.addPermissionSet(lmsUsers,'LMS_User');
        }

        List<Learning__c> quizLearnings = createMultipleQuestionQuizLearnings();
        Id learningAssignmentId = createSampleData(adminUsers,lmsUsers,quizLearnings);

        List<Learning_Assignment__c> lassignment = [select Id,
                                                            Learning__c, Learning_Version__r.Quiz__c from Learning_Assignment__c
                                                            where Id = :learningAssignmentId];

        System.assert(lassignment.size() == 1, 'Learning Assignment issues, size = ' + lassignment.size());
        System.assert(lassignment.get(0).Learning_Version__r.Quiz__c != null, 'Learning Assignment is not for Quiz');

        //Create a new answer sequence item for testing purposes
        Answer_Sequence__c oaseq = new Answer_Sequence__c();
        oaseq.Internal_Notes__c = 'dummy internal notes';
        insert oaseq;

        //Create answer sequence items
        List<Answer_Sequence_Item__c> lanswerSequence = new List<Answer_Sequence_Item__c>();

        for(Integer i = 0; i < 3; i++){
            Answer_Sequence_Item__c oasi = new Answer_Sequence_Item__c();
            oasi.Item_Id__c = 'testMPQ'+i;
            oasi.Answer_Sequence__c = oaseq.Id;
            oasi.Answer_Text__c = 'testMPQ'+i;
            oasi.Is_Correct_Answer__c = true;
            oasi.Order__c = i;
            lanswerSequence.add(oasi);
        }
        insert lanswerSequence;

        //Associate the new answer sequence to the quiz question
        List<Question__c> questions = [select id,Answer_Sequence__c from Question__c where Question_Line__r.Quiz__r.Learning__c = :quizLearnings.get(0).id];
        Question__c selectMultipleQ = questions.get(0);
        selectMultipleQ.Answer_Sequence__c = oaseq.Id;
        update selectMultipleQ;

        //Answer the multiple choice question
        Response__c response = new Response__c();
        response.Learning_Assignment__c = lassignment.get(0).Id;
        response.Question__c = selectMultipleQ.Id;
        response.User__c =  lmsUsers.get(0).Id;
        //Respond with only two of the options
        response.Response_Answer_Sequence_Label__c = 'testMPQ0;testMPQ1;';
        response.Response_Answer_Sequence_Long__c = 'testMPQ0;testMPQ1;';

        Test.startTest();
            System.runAs(lmsUsers.get(0)){
                PageReference pageRef = Page.QuizViewer;
                Test.setCurrentPage(pageRef);
                pageRef.getParameters().put('aid', learningAssignmentId);
                QuizViewerController controller = new QuizViewerController();
                controller.initializeQuestions();
                //first section
                List<QuizItem> lqi = controller.quizItemList;
                for(QuizItem qi : lqi){
                	qi.response = response;
                }
                controller.done();
            }
        Test.stopTest();

        System.runAs(lmsUsers.get(0)){
            //Switch to quiz results page
            PageReference pageRef = Page.QuizResults;
            pageRef.getParameters().put('aid',learningAssignmentId);
            Test.setCurrentPage(pageRef);
            QuizResultsController cont = new QuizResultsController();
            System.assertEquals(LMSConstants.ASSIGNMENT_EVAL_FAILED,cont.evalResult);
            PageReference contRef = cont.quizContinue();
            PageReference dummyRef = new PageReference(cont.redirectURL);
            System.assert(dummyRef.getParameters().get('id') != null,'Result does not contain assignment id');
        }
    }

    static testMethod void testCorrectSelectMultipleValues(){

        //Create admin users
        List<User> adminUsers = TestUtilClass.createUsers(1,'System Administrator');
        List<User> lmsUsers = TestUtilClass.createUsers(1,'Standard User');

        System.runAs(adminUsers.get(0)){
            //Assign corresponding perm sets
            TestUtilClass.addPermissionSet(adminUsers,'LMS_Admin');
            TestUtilClass.addPermissionSet(lmsUsers,'LMS_User');
        }

        List<Learning__c> quizLearnings = createMultipleQuestionQuizLearnings();
        Id learningAssignmentId = createSampleData(adminUsers,lmsUsers,quizLearnings);

        List<Learning_Assignment__c> lassignment = [select Id,
                                                            Learning__c, Learning_Version__r.Quiz__c from Learning_Assignment__c
                                                            where Id = :learningAssignmentId];

        System.assert(lassignment.size() == 1, 'Learning Assignment issues, size = ' + lassignment.size());
        System.assert(lassignment.get(0).Learning_Version__r.Quiz__c != null, 'Learning Assignment is not for Quiz');

        //Create a new answer sequence item for testing purposes
        Answer_Sequence__c oaseq = new Answer_Sequence__c();
        oaseq.Internal_Notes__c = 'dummy internal notes';
        insert oaseq;

        //Create answer sequence items
        List<Answer_Sequence_Item__c> lanswerSequence = new List<Answer_Sequence_Item__c>();

        for(Integer i = 0; i < 3; i++){
            Answer_Sequence_Item__c oasi = new Answer_Sequence_Item__c();
            oasi.Item_Id__c = 'testMPQ'+i;
            oasi.Answer_Sequence__c = oaseq.Id;
            oasi.Answer_Text__c = 'testMPQ'+i;
            oasi.Is_Correct_Answer__c = true;
            oasi.Order__c = i;
            lanswerSequence.add(oasi);
        }
        insert lanswerSequence;

        //Associate the new answer sequence to the quiz question
        List<Question__c> questions = [select id,Answer_Sequence__c from Question__c where Question_Line__r.Quiz__r.Learning__c = :quizLearnings.get(0).id];
        Question__c selectMultipleQ = questions.get(0);
        selectMultipleQ.Answer_Sequence__c = oaseq.Id;
        update selectMultipleQ;

        //Answer the multiple choice question
        Response__c response = new Response__c();
        response.Learning_Assignment__c = lassignment.get(0).Id;
        response.Question__c = selectMultipleQ.Id;
        response.User__c =  lmsUsers.get(0).Id;
        //Respond with only two of the options
        response.Response_Answer_Sequence_Label__c = 'testMPQ0;testMPQ1;testMPQ2;';
        response.Response_Answer_Sequence_Long__c = 'testMPQ0;testMPQ1;testMPQ2;';

        Test.startTest();
            System.runAs(lmsUsers.get(0)){
                PageReference pageRef = Page.QuizViewer;
                Test.setCurrentPage(pageRef);
                pageRef.getParameters().put('aid', learningAssignmentId);
                QuizViewerController controller = new QuizViewerController();
                controller.initializeQuestions();

                //first section
                List<QuizItem> lqi = controller.quizItemList;

                for(QuizItem qi : lqi){
                	qi.response = response;
                }
                controller.done();
            }
        Test.stopTest();

        System.runAs(lmsUsers.get(0)){
            //Switch to quiz results page
            PageReference pageRef = Page.QuizResults;
            pageRef.getParameters().put('aid',learningAssignmentId);
            Test.setCurrentPage(pageRef);
            QuizResultsController cont = new QuizResultsController();
            System.assertEquals(LMSConstants.ASSIGNMENT_EVAL_PASSED,cont.evalResult);
            PageReference contRef = cont.quizContinue();
            PageReference dummyRef = new PageReference(cont.redirectURL);
            System.assert(dummyRef.getParameters().get('id') != null,'Result does not contain assignment id');
        }
    }

    static testMethod void testPassingResultsAndDeletingResponses(){

        //Create admin users
        List<User> adminUsers = TestUtilClass.createUsers(1,'System Administrator');
        List<User> lmsUsers = TestUtilClass.createUsers(1,'Standard User');

        System.runAs(adminUsers.get(0)){
            //Assign corresponding perm sets
            TestUtilClass.addPermissionSet(adminUsers,'LMS_Admin');
            TestUtilClass.addPermissionSet(lmsUsers,'LMS_User');
        }

        Id learningAssignmentId = createSampleData(adminUsers,lmsUsers,createQuizLearnings());

        List<Learning_Assignment__c> lassignment = [select Id,
                                                            Learning__c, Learning_Version__r.Quiz__c from Learning_Assignment__c
                                                            where Id = :learningAssignmentId];

        System.assert(lassignment.size() == 1, 'Learning Assignment issues, size = ' + lassignment.size());
        System.assert(lassignment.get(0).Learning_Version__r.Quiz__c != null, 'Learning Assignment is not for Quiz');

        //Configure quiz to delete responses on submission
        Quiz__c testQuiz = [select id,Delete_Responses_On_Submission__c from Quiz__c where Id = :lassignment.get(0).Learning_Version__r.Quiz__c limit 1];
        testQuiz.Delete_Responses_On_Submission__c = true;
        update testQuiz;

        //Answer all the quiz questions
        Set<Id> qlineIds = new Set<Id>();
        for(Question_Line__c oql : [select Id from Question_Line__c where Quiz__c =: lassignment.get(0).Learning_Version__r.Quiz__c]){
            qlineIds.add(oql.Id);
        }

        Map<String, Response__c> mResponses = TestLearningData.createTestQuestionResponses(qlineIds, lmsUsers.get(0).Id, lassignment.get(0).Id);

        Test.startTest();
            System.runAs(lmsUsers.get(0)){
                PageReference pageRef = Page.QuizViewer;
                Test.setCurrentPage(pageRef);
                pageRef.getHeaders().put('User-Agent', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.6; rv:25.0) Gecko/20100101 Firefox/25.0');
                pageRef.getParameters().put('aid', learningAssignmentId);
                QuizViewerController controller = new QuizViewerController();
                controller.initializeQuestions();

                //first section
                List<QuizItem> lqi = controller.quizItemList;

                for(QuizItem qi : lqi){
                	qi.response = mResponses.get(qi.question.Id);
                }
                controller.next();
                controller.initializeQuestions();

                //second section
                List<QuizItem> lqi2 = controller.quizItemList;

                for(QuizItem qi : lqi2){
                	qi.response	 = mResponses.get(qi.question.Id);
                }
                controller.next();
                controller.initializeQuestions();

                //third & final section
                List<QuizItem> lqi3 = controller.quizItemList;

                for(QuizItem qi : lqi3){
                    qi.response	 = mResponses.get(qi.question.Id);
                }
                controller.done();

            }
        Test.stopTest();

        System.runAs(lmsUsers.get(0)){
            //Switch to quiz results page
            PageReference pageRef = Page.QuizResults;
            pageRef.getParameters().put('aid',learningAssignmentId);
            Test.setCurrentPage(pageRef);
            QuizResultsController cont = new QuizResultsController();
            System.assertEquals(LMSConstants.ASSIGNMENT_EVAL_PASSED,cont.evalResult);
            PageReference contRef = cont.quizContinue();
            PageReference dummyRef = new PageReference(cont.redirectURL);
            System.assert(dummyRef.getParameters().get('id') != null,'Result does not contain assignment id');
            System.assert(countAssignmentResponses(learningAssignmentId) == 0, 'Responses were not deleted after submission');
        }

    }

    private static List<Learning__c> createMultipleQuestionQuizLearnings(){
        //create quiz learnings
        List<Learning__c> quizLearnings = TestLearningData.createTestLearning(1, 'Quiz', false);
        //create quiz
        List<Quiz__c> quiz = TestLearningData.createTestQuiz(quizLearnings, new Map<String,Object>{'Passing_Score__c'=>100.0});
        //create question line
        List<Question_Line__c> qline = TestLearningData.createTestQuestionLine(quiz, 1);
        //create question
        List<Question__c> question = TestLearningData.createTestQuestions(qline, 1, 'SelectMultipleQuestion');
        for(Integer i = 0;i < quizLearnings.size();i++){
            TestLearningData.publishLearning(quizLearnings.get(i).Id,'quiz',quiz.get(i).Id,false);
        }
        return quizLearnings;
    }

    private static List<Learning__c> createQuizLearnings(){
        //create quiz learnings
        List<Learning__c> quizLearnings = TestLearningData.createTestLearning(1, 'Quiz', false);
        //create quiz
        List<Quiz__c> quiz = TestLearningData.createTestQuiz(quizLearnings);
        //create question line
        List<Question_Line__c> qline = TestLearningData.createTestQuestionLine(quiz, 2);
        //create question
        List<Question__c> question = TestLearningData.createTestQuestions(qline, 4, null);
        for(Integer i = 0;i < quizLearnings.size();i++){
            TestLearningData.publishLearning(quizLearnings.get(i).Id,'quiz',quiz.get(i).Id,false);
        }
        return quizLearnings;
    }

    private static Id createSampleData(List<User> adminUsers, List<User> lmsUsers,List<Learning__c> quizLearnings){
        //Create training plans
        List<Training_Plan__c> tplans = TestTrainingPlanData.createTrainingPlans(new List<TestParams.TrainingPlanParam>{new TestParams.TrainingPlanParam()});
        //Create training plan sections
        List<Training_Plan_Section__c> tplanSections1 = TestTrainingPlanData.createTrainingPlanSections(tplans.get(0).Id,1);
        //Create training plan section items for quizzes
        List<Training_Plan_Section_Item__c> tplan1SectionItems1 = TestTrainingPlanData.createTrainingPlanSectionItems(tplanSections1.get(0).Id,quizLearnings);

        List<Training_Plan__c> tplan = [select id from Training_Plan__c];
        System.assertEquals(1,tplan.size());
        Id tplanId = tplan.get(0).Id;

        Set<Id> selectedUserIds = new Set<Id>();

        for(User u : lmsUsers){
            selectedUserIds.add(u.Id);
        }

        System.runAs(adminUsers.get(0)){
            LMSService.upsertAssignments(selectedUserIds,tplanId,null);
        }

        List<Learning_Assignment__c> assignments = [select id from Learning_Assignment__c where Training_Plan__c = :tplanId];
        System.assertEquals(1,assignments.size());
        return assignments.get(0).Id;
    }

    private static Integer countAssignmentResponses(Id assignmentId){
        return [select count() from Response__c where Learning_Assignment__c = :assignmentId];
    }
}
