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
private class TestAchievementAssignmentsWorkCom{

    static testMethod void testCompletingTrainingPlan(){

	    //Create admin users
		List<User> adminUsers = TestUtilClass.createUsers(1,'System Administrator');
		List<User> lmsUsers = TestUtilClass.createUsers(1,'Standard User');

		System.runAs(adminUsers.get(0)){
			//Assign corresponding perm sets
			TestUtilClass.addPermissionSet(adminUsers,'LMS_Admin');
			TestUtilClass.addPermissionSet(lmsUsers,'LMS_User');
		}

        Id learningAssignmentId = createSingleItemTrainingPlanWithWorkAchievement(adminUsers,lmsUsers);

		PageReference pageRef = Page.ResourceViewer;
        pageRef.getParameters().put('aid',learningAssignmentId);

        System.assertEquals(0,getWorkBadgeCount(lmsUsers.get(0).Id));

		Test.setCurrentPage(pageRef);
		Test.startTest();
            System.runAs(lmsUsers.get(0)){
                ResourceViewerController cont = new ResourceViewerController();
                String contRef = ResourceViewerController.redirectToResource(learningAssignmentId);
                System.assert(contRef != null);
                List<Learning_Assignment__c> assignments;
                assignments = [select id,Progress__c from Learning_Assignment__c where id = :learningAssignmentId];
                System.assertEquals(LMSConstants.ASSIGNMENT_STATUS_COMPLETED,assignments.get(0).Progress__c);
            }

        Test.stopTest();

        //Assert work badge has been created
        System.assertEquals(1,getWorkBadgeCount(lmsUsers.get(0).Id));

    }

    private static Id createSingleItemTrainingPlanWithWorkAchievement(List<User> adminUsers, List<User> lmsUsers){

        //create resource learnings
		List<Learning__c> resourceLearnings = TestLearningData.createTestLearning(1, 'Resource', false);
		//create training resources
		List<Training_Resource__c> tresources = TestLearningData.createTestTrainingResource(resourceLearnings);

		for(Integer i = 0;i < resourceLearnings.size();i++){
			TestLearningData.publishLearning(resourceLearnings.get(i).Id,'resource',tresources.get(i).Id,false);
		}

		//Create training plans
		List<Training_Plan__c> tplans = TestTrainingPlanData.createTrainingPlans(new List<TestParams.TrainingPlanParam>{new TestParams.TrainingPlanParam()});
		//Create training plan sections
		List<Training_Plan_Section__c> tplanSections1 = TestTrainingPlanData.createTrainingPlanSections(tplans.get(0).Id,1);
		//Create training plan section items for resource
		List<Training_Plan_Section_Item__c> tplan1SectionItems1 = TestTrainingPlanData.createTrainingPlanSectionItems(tplanSections1.get(0).Id,resourceLearnings);
		List<Achievement_Category__c> lAchieveCat = TestAchievementData.createAchievementCategories(1);
		List<Achievement__c> lAchievements = TestAchievementData.createAchievements(1, lAchieveCat.get(0).Id, 'Achievements');
		List<Training_Plan_Achievement__c> lTPlanAchievement = TestTrainingPlanData.createTrainingPlanAchievements(tplans, new List<Achievement__c>{lAchievements.get(0)});

        List<WorkBadgeDefinition> lWorkBadges = TestAchievementData.createWorkBadges(1);
        WorkBadgeDefinition wb = lWorkBadges.get(0);

        Achievement__c ach  = new Achievement__c(id = lAchievements.get(0).Id);
        ach.Work_Badge_Id__c = wb.Id;
        ach.Work_Badge_Image_URL__c = wb.ImageUrl;
        ach.Work_Badge_Giver__c = adminUsers.get(0).Id;
        update ach;

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

    private static Integer getWorkBadgeCount(String userId){
        return  [select count() from WorkBadge where RecipientId = :userId];
    }

}
