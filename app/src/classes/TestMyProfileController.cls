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
private class TestMyProfileController {

    static testMethod void testWithNoAchievements(){

		//Create admin users
		List<User> adminUsers = TestUtilClass.createUsers(2,'System Administrator');
		List<User> lmsUsers = TestUtilClass.createUsers(2,'Standard User');

		System.runAs(adminUsers.get(0)){
			//Assign corresponding perm sets
			TestUtilClass.addPermissionSet(adminUsers,'LMS_Admin');
			TestUtilClass.addPermissionSet(lmsUsers,'LMS_User');
		}

        //Update manager for user 1
        User u1 = [select id,managerId from User where id = :lmsUsers.get(0).id];
        u1.managerId = lmsUsers.get(1).Id;
        update u1;

		TestTrainingPlanData.createSampleData();
		List<Training_Plan__c> tplan = [select id from Training_Plan__c];
		System.assertEquals(1,tplan.size());
		Id tplanId = tplan.get(0).Id;
		Set<Id> selectedUserIds = new Set<Id>();

		for(User u : lmsUsers){
			selectedUserIds.add(u.Id);
		}

		System.runAs(adminUsers.get(0)){
			LMSService.upsertAssignments(selectedUserIds,tplanId);
		}

        PageReference ref = Page.MyProfile;
        Test.setCurrentPageReference(ref);

		Test.startTest();

            System.runAs(lmsUsers.get(0)){

                MyProfileController cont = new MyProfileController();
                System.assert(cont.oManager != null);
                System.assert(cont.achievementType == 'Achievements');
                System.assert(cont.oUser != null);
                System.assertEquals(0,cont.lcategories.size());

                List<MyProfileController.AchievementTypeWrapper> atypes = cont.getAchievementTypes();
                System.assert(atypes.size()>0);


                ref.getParameters().put('aType','Certifications');
                Test.setCurrentPageReference(ref);

                PageReference ctypeRef = cont.changeAchievementType();
                System.assert(ctypeRef != null);

            }

        Test.stopTest();

    }

    static testMethod void testWithAchievements(){

		//Create admin users
		List<User> adminUsers = TestUtilClass.createUsers(2,'System Administrator');
		List<User> lmsUsers = TestUtilClass.createUsers(2,'Standard User');

		System.runAs(adminUsers.get(0)){
			//Assign corresponding perm sets
			TestUtilClass.addPermissionSet(adminUsers,'LMS_Admin');
			TestUtilClass.addPermissionSet(lmsUsers,'LMS_User');
		}

        //Update manager for user 1
        User u1 = [select id,managerId from User where id = :lmsUsers.get(0).id];
        u1.managerId = lmsUsers.get(1).Id;
        update u1;

		TestTrainingPlanData.createSampleData();
		List<Training_Plan__c> tplan = [select id from Training_Plan__c];
		System.assertEquals(1,tplan.size());

		List<Achievement_Category__c> lAchieveCat = TestAchievementData.createAchievementCategories(1);
		List<Achievement__c> lAchievement = TestAchievementData.createAchievements(1, lAchieveCat.get(0).Id, 'Achievements');
		List<Training_Plan_Achievement__c> lTPlanAchievement = TestTrainingPlanData.createTrainingPlanAchievements(tplan, lAchievement);

		Id tplanId = tplan.get(0).Id;
		Set<Id> selectedUserIds = new Set<Id>();

		for(User u : lmsUsers){
			selectedUserIds.add(u.Id);
		}

		System.runAs(adminUsers.get(0)){
			LMSService.upsertAssignments(selectedUserIds,tplanId);
		}

        PageReference ref = Page.MyProfile;
        Test.setCurrentPageReference(ref);

		Test.startTest();

            System.runAs(lmsUsers.get(0)){

                MyProfileController cont = new MyProfileController();
                System.assertEquals(1,cont.lcategories.size());

                List<MyProfileController.AchievementTypeWrapper> atypes = cont.getAchievementTypes();
                System.assert(atypes.size()>0);
                ref.getParameters().put('aType','Certifications');
                Test.setCurrentPageReference(ref);

                PageReference ctypeRef = cont.changeAchievementType();
                System.assert(ctypeRef != null);

            }

        Test.stopTest();

    }

    static testMethod void testWithAchievementsAndOverrideURL(){

		//Create admin users
		List<User> adminUsers = TestUtilClass.createUsers(2,'System Administrator');
		List<User> lmsUsers = TestUtilClass.createUsers(2,'Standard User');

		System.runAs(adminUsers.get(0)){
			//Assign corresponding perm sets
			TestUtilClass.addPermissionSet(adminUsers,'LMS_Admin');
			TestUtilClass.addPermissionSet(lmsUsers,'LMS_User');
		}

        //Update manager for user 1
        User u1 = [select id,managerId from User where id = :lmsUsers.get(0).id];
        u1.managerId = lmsUsers.get(1).Id;
        update u1;

		TestTrainingPlanData.createSampleData();
		List<Training_Plan__c> tplan = [select id from Training_Plan__c];
		System.assertEquals(1,tplan.size());

        //Override achievement url
		List<Achievement_Category__c> lAchieveCat = TestAchievementData.createAchievementCategories(1);
		List<Achievement__c> lAchievement = TestAchievementData.createAchievements(1, lAchieveCat.get(0).Id, 'Achievements');
        Achievement__c ach = [select id,Override_URL__c from Achievement__c where Id = :lAchievement.get(0).Id];
        ach.Override_URL__c = 'https://www.salesforce.com';
        update ach;


		List<Training_Plan_Achievement__c> lTPlanAchievement = TestTrainingPlanData.createTrainingPlanAchievements(tplan, lAchievement);

		Id tplanId = tplan.get(0).Id;
		Set<Id> selectedUserIds = new Set<Id>();

		for(User u : lmsUsers){
			selectedUserIds.add(u.Id);
		}

		System.runAs(adminUsers.get(0)){
			LMSService.upsertAssignments(selectedUserIds,tplanId);
		}


        //Change achievement status
		List<Achievement_Assignment__c> achievementAssignments = [select Id,Status__c from Achievement_Assignment__c where Training_Plan_Achievement__r.Training_Plan__c = :tplanId];
        for(Achievement_Assignment__c aa : achievementAssignments){
            aa.Status__c = LMSConstants.AA_ACQUIRED_STATUS;
        }
        update achievementAssignments;

        PageReference ref = Page.MyProfile;
        Test.setCurrentPageReference(ref);

		Test.startTest();

            System.runAs(lmsUsers.get(0)){

                MyProfileController cont = new MyProfileController();
                System.assertEquals(1,cont.lcategories.size());

                List<MyProfileController.AchievementTypeWrapper> atypes = cont.getAchievementTypes();
                System.assert(atypes.size()>0);
                ref.getParameters().put('aType','Certifications');
                Test.setCurrentPageReference(ref);

                PageReference ctypeRef = cont.changeAchievementType();
                System.assert(ctypeRef != null);

            }

        Test.stopTest();

    }

}
