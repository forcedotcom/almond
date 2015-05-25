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
public class TestTrainingPlanData {

    public static List<Training_Plan__c> createTrainingPlans(List<TestParams.TrainingPlanParam> params){
        List<Training_Plan__c> lResult = new List<Training_Plan__c>();
        for(TestParams.TrainingPlanParam p : params){
            Training_Plan__c tplan = new Training_Plan__c();
            tplan.Name = p.Name;
            tplan.Chatter_Notifications_Enabled__c = p.chatterNotificationsEnabled;
            tplan.Description__c = p.Description;
            tplan.Enable_Self_Registration__c = p.enableSelfRegistration;
            tplan.End_Date__c =  p.endDate;
            tplan.Start_Date__c = p.startDate;
            tplan.Enforce_Sequence__c = p.enforceSequence;
            tplan.Self_Registration_Access__c = p.selfRegistrationAccess;
            tplan.Status__c = p.status;
            lResult.add(tplan);
        }
        insert lResult;
        return lResult;
    }

    public static List<Training_Plan_Section__c> createTrainingPlanSections(String tplanId, Integer totalSections){
        List<Training_Plan_Section__c> lResult = new List<Training_Plan_Section__c>();
        for(Integer i =1;i<= totalSections;i++){
            Training_Plan_Section__c tPlanSection = new Training_Plan_Section__c();
            tPlanSection.Optional__c = false;
            tPlanSection.Order__c = i;
            tPlanSection.Training_Plan__c = tplanId;
            lResult.add(tPlanSection);
        }
        insert lResult;
        return lResult;
    }

    public static List<Training_Plan_Section_Item__c> createTrainingPlanSectionItems(String tplanSectionId,List<Learning__c> learnings){
        List<Training_Plan_Section_Item__c> lResult = new List<Training_Plan_Section_Item__c>();
        for(Learning__c l : learnings){
            Training_Plan_Section_Item__c tPlanSectionItem = new Training_Plan_Section_Item__c();
            tPlanSectionItem.Optional__c = false;
            tPlanSectionItem.Order__c = lResult.size()+1;
            tPlanSectionItem.Learning__c = l.Id;
            tPlanSectionItem.Training_Plan_Section__c = tplanSectionId;
            lResult.add(tPlanSectionItem);
        }
        insert lResult;
        return lResult;
    }

    public static List<Training_Plan_Achievement__c> createTrainingPlanAchievements(List<Training_Plan__c> lTPlans, List<Achievement__c> lAchievements){
        List<Training_Plan_Achievement__c> lResult = new List<Training_Plan_Achievement__c>();
        for(Integer i = 0; i < lTPlans.size(); i++){
            Training_Plan_Achievement__c otpa = new Training_Plan_Achievement__c();
            otpa.Achievement__c = lAchievements.get(i).Id;
            otpa.Main_Achievement__c = true;
            otpa.Training_Plan__c = lTPlans.get(i).Id;
            otpa.Type__c = 'Plan';
            lResult.add(otpa);
        }
        insert lResult;
        return lResult;
    }

    public static List<Training_Plan_Achievement__c> createTrainingPlanSectionAchievements(List<Training_Plan_Section__c> lTPlanSections, List<Achievement__c> lAchievements){
        List<Training_Plan_Achievement__c> lResult = new List<Training_Plan_Achievement__c>();
        for(Integer i = 0; i < lTPlanSections.size(); i++){
            Training_Plan_Achievement__c otpa = new Training_Plan_Achievement__c();
            otpa.Achievement__c = lAchievements.get(i).Id;
            otpa.Main_Achievement__c = true;
            otpa.Training_Plan__c = lTPlanSections.get(i).Training_Plan__c;
            otpa.Training_Plan_Section__c = lTPlanSections.get(i).Id;
            otpa.Type__c = 'Section';
            lResult.add(otpa);
        }
        insert lResult;
        return lResult;
    }

    public static List<Training_Plan_Category__c> createTrainingPlanCategories(List<Training_Plan__c> lTPlans, List<Learning_Category__c> lCategories){
        List<Training_Plan_Category__c> lResult = new List<Training_Plan_Category__c>();
        for(Training_Plan__c tplan : lTPlans){
            for(Learning_Category__c  lc : lCategories){
                Training_Plan_Category__c tpc = new Training_Plan_Category__c();
                tpc.Training_Plan__c = tplan.Id;
                tpc.Learning_Category__c = lc.Id;
                lResult.add(tpc);
            }

        }
        insert lResult;
        return lResult;
    }

    public static void createSampleData(){

        //Create quiz learnings
        List<Learning__c> quizLearnings = TestLearningData.createTestLearning(1, 'Quiz', false);
        //create resource learnings
        List<Learning__c> resourceLearnings = TestLearningData.createTestLearning(3, 'Resource', false);
        //create task learnings
        List<Learning__c> taskLearnings = TestLearningData.createTestLearning(3, 'Task', false);
        //create quiz
        List<Quiz__c> quiz = TestLearningData.createTestQuiz(quizLearnings);
        //create question line
        List<Question_Line__c> qline = TestLearningData.createTestQuestionLine(quiz, 3);
        //create question
        List<Question__c> question = TestLearningData.createTestQuestions(qline, 4, null);
        //create training resources
        List<Training_Resource__c> tresources = TestLearningData.createTestTrainingResource(resourceLearnings);
        //create task resources
        List<Task__c> ttasks = TestLearningData.createTestTask(taskLearnings);
        //create learning categories
        List<Learning_Category__c> learningCategories = TestLearningData.createTestLearningCategories(2);

        //Publish learnings
        for(Integer i = 0;i < quizLearnings.size();i++){
            TestLearningData.publishLearning(quizLearnings.get(i).Id,'quiz',quiz.get(i).Id,false);
        }
        for(Integer i = 0;i < resourceLearnings.size();i++){
            TestLearningData.publishLearning(resourceLearnings.get(i).Id,'resource',tresources.get(i).Id,false);
        }
        for(Integer i = 0;i < taskLearnings.size();i++){
            TestLearningData.publishLearning(taskLearnings.get(i).Id,'task',ttasks.get(i).Id,false);
        }

        //Create training plans
        TestParams.TrainingPlanParam tplan = new TestParams.TrainingPlanParam ();
        List<Training_Plan__c> tplans = createTrainingPlans(new List<TestParams.TrainingPlanParam>{tplan});

        //Add learning categories to training plan
        List<Training_Plan_Category__c> tplanCategories = createTrainingPlanCategories(tplans,learningCategories);

        //Create training plan sections
        List<Training_Plan_Section__c> tplanSections = createTrainingPlanSections(tplans.get(0).Id,3);

        //Create training plan section items for quizzes
        List<Training_Plan_Section_Item__c> tplanSectionItmes1 = createTrainingPlanSectionItems(tplanSections.get(0).Id,quizLearnings);
        //Create training plan section items for resources
        List<Training_Plan_Section_Item__c> tplanSectionItmes2 = createTrainingPlanSectionItems(tplanSections.get(1).Id,resourceLearnings);
        //Create training plan section items for tasks
        List<Training_Plan_Section_Item__c> tplanSectionItmes3 = createTrainingPlanSectionItems(tplanSections.get(2).Id,taskLearnings);

    }

    public static void createSampleDataWithSharedLearnings(){

        //Create quiz learnings
        List<Learning__c> quizLearnings = TestLearningData.createTestLearning(1, 'Quiz', true);
        //create resource learnings
        List<Learning__c> resourceLearnings = TestLearningData.createTestLearning(1, 'Resource', true);
        //create task learnings
        List<Learning__c> taskLearnings = TestLearningData.createTestLearning(1, 'Task', true);
        //create quiz
        List<Quiz__c> quiz = TestLearningData.createTestQuiz(quizLearnings);
        //create question line
        List<Question_Line__c> qline = TestLearningData.createTestQuestionLine(quiz, 3);
        //create question
        List<Question__c> question = TestLearningData.createTestQuestions(qline, 4, null);
        //create training resources
        List<Training_Resource__c> tresources = TestLearningData.createTestTrainingResource(resourceLearnings);
        //create task resources
        List<Task__c> ttasks = TestLearningData.createTestTask(taskLearnings);
        //create learning categories
        List<Learning_Category__c> learningCategories = TestLearningData.createTestLearningCategories(2);

        //Publish learnings
        for(Integer i = 0;i < quizLearnings.size();i++){
            TestLearningData.publishLearning(quizLearnings.get(i).Id,'quiz',quiz.get(i).Id,false);
        }
        for(Integer i = 0;i < resourceLearnings.size();i++){
            TestLearningData.publishLearning(resourceLearnings.get(i).Id,'resource',tresources.get(i).Id,false);
        }
        for(Integer i = 0;i < taskLearnings.size();i++){
            TestLearningData.publishLearning(taskLearnings.get(i).Id,'task',ttasks.get(i).Id,false);
        }

        //Create training plans
        List<Training_Plan__c> tplans = createTrainingPlans(new List<TestParams.TrainingPlanParam>{new TestParams.TrainingPlanParam (),new TestParams.TrainingPlanParam ()});
        //Add learning categories to training plan
        List<Training_Plan_Category__c> tplanCategories = createTrainingPlanCategories(tplans,learningCategories);
        //Create training plan sections
        List<Training_Plan_Section__c> tplanSections1 = createTrainingPlanSections(tplans.get(0).Id,3);
        //Create training plan section items for quizzes
        List<Training_Plan_Section_Item__c> tplan1SectionItems1 = createTrainingPlanSectionItems(tplanSections1.get(0).Id,quizLearnings);
        //Create training plan section items for resources
        List<Training_Plan_Section_Item__c> tplan1SectionItems2 = createTrainingPlanSectionItems(tplanSections1.get(1).Id,resourceLearnings);
        //Create training plan section items for tasks
        List<Training_Plan_Section_Item__c> tplan1SectionItems3 = createTrainingPlanSectionItems(tplanSections1.get(2).Id,taskLearnings);

        //Create training plan sections
        List<Training_Plan_Section__c> tplanSections2 = createTrainingPlanSections(tplans.get(1).Id,3);
        //Create training plan section items for quizzes
        List<Training_Plan_Section_Item__c> tplan2SectionItems1 = createTrainingPlanSectionItems(tplanSections2.get(0).Id,quizLearnings);
        //Create training plan section items for resources
        List<Training_Plan_Section_Item__c> tplan2SectionItems2 = createTrainingPlanSectionItems(tplanSections2.get(1).Id,resourceLearnings);
        //Create training plan section items for tasks
        List<Training_Plan_Section_Item__c> tplan2SectionItems3 = createTrainingPlanSectionItems(tplanSections2.get(2).Id,taskLearnings);

    }

    public static void createExternalSampleData(){
        createSampleData();

        List<Training_Plan__c> tplans = [select id,Enable_Self_Registration__c,Self_Registration_Access__c from Training_Plan__c ];
        for(Training_Plan__c tp : tplans){
            tp.Enable_Self_Registration__c = true;
            tp.Self_Registration_Access__c = 'External';
        }
        update tplans;

    }

}
