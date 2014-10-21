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
public class TestTrainingTrackData {

	public static List<Training_Track__c> createTrainingTracks(List<TestParams.TrainingTrackParam> params){
		List<Training_Track__c> lResult = new List<Training_Track__c>();
		for(TestParams.TrainingTrackParam p : params){
			Training_Track__c ttrack = new Training_Track__c();
			ttrack.Name = p.Name;
			ttrack.Description__c = p.Description;
			ttrack.Status__c = p.status;
			ttrack.Background_Color__c = p.backgroundColor;
			ttrack.Background_Image_URL__c = p.backgroundImageURL;
			ttrack.Text_Color__c = p.textColor;
			ttrack.Achievement__c = p.achievementId;
			lResult.add(ttrack);
		}
		insert lResult;
		return lResult;
	}

	public static List<Training_Track_Level_Item__c> createTrainingTrackItems(String trackId, List<Training_Plan__c> tplans, Integer level){
		List<Training_Track_Level_Item__c> lResult = new List<Training_Track_Level_Item__c>();

		//Create level
		Training_Track_Level__c ttlevel = new Training_Track_Level__c();
		ttlevel.Order__c = level;
		ttlevel.Training_Track__c = trackId;
		ttlevel.Description__c = 'test';
		insert ttlevel;

		//Create items
		for(Training_Plan__c tplan : tplans){
			Training_Track_Level_Item__c ttrackItem = new Training_Track_Level_Item__c();
			ttrackItem.Training_Track_Level__c = ttlevel.Id;
			ttrackItem.Training_Plan__c = tplan.Id;
			lResult.add(ttrackItem);
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
		List<Question__c> question = TestLearningData.createTestQuestions(qline, 4);
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
		TestParams.TrainingPlanParam tplan1 = new TestParams.TrainingPlanParam();
		TestParams.TrainingPlanParam tplan2 = new TestParams.TrainingPlanParam();
		TestParams.TrainingPlanParam tplan3 = new TestParams.TrainingPlanParam();
		List<Training_Plan__c> tplans = TestTrainingPlanData.createTrainingPlans(new List<TestParams.TrainingPlanParam>{tplan1,tplan2,tplan3});

		//Add learning categories to training plan
		List<Training_Plan_Category__c> tplanCategories = TestTrainingPlanData.createTrainingPlanCategories(tplans,learningCategories);

		//Create training plan sections
		List<Training_Plan_Section__c> tplanSections1 = TestTrainingPlanData.createTrainingPlanSections(tplans.get(0).Id,1);
		List<Training_Plan_Section__c> tplanSections2 = TestTrainingPlanData.createTrainingPlanSections(tplans.get(1).Id,2);
		List<Training_Plan_Section__c> tplanSections3 = TestTrainingPlanData.createTrainingPlanSections(tplans.get(2).Id,1);


		//Create training plan section items for quizzes
		List<Training_Plan_Section_Item__c> tplan1SectionItems1 = TestTrainingPlanData.createTrainingPlanSectionItems(tplanSections1.get(0).Id,quizLearnings);

		List<Training_Plan_Section_Item__c> tplan2SectionItems1 = TestTrainingPlanData.createTrainingPlanSectionItems(tplanSections2.get(0).Id,resourceLearnings);
		List<Training_Plan_Section_Item__c> tplan2SectionItems2 = TestTrainingPlanData.createTrainingPlanSectionItems(tplanSections2.get(1).Id,taskLearnings);

		List<Training_Plan_Section_Item__c> tplan3SectionItems1 = TestTrainingPlanData.createTrainingPlanSectionItems(tplanSections3.get(0).Id,resourceLearnings);

		//Create a training track
		TestParams.TrainingTrackParam ttrack1 = new TestParams.TrainingTrackParam();
		List<Training_Track__c> ttracks = createTrainingTracks(new List<TestParams.TrainingTrackParam>{ttrack1});

		//Add training track items
		List<Training_Track_Level_Item__c> trackItems1 = createTrainingTrackItems(ttracks.get(0).Id,new List<Training_Plan__c>{tplans.get(0)},1);
		List<Training_Track_Level_Item__c> trackItems2 = createTrainingTrackItems(ttracks.get(0).Id,new List<Training_Plan__c>{tplans.get(1),tplans.get(2)},2);
	}

}
