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
public class TestLMS_API {

    static testmethod void testUpsertTrainingPlanAssignment(){

        //Create admin users
        List<User> adminUsers = TestUtilClass.createUsers(2,'System Administrator');
        List<User> lmsUsers = TestUtilClass.createUsers(5,'Standard User');

        System.runAs(adminUsers.get(0)){
            //Assign corresponding perm sets
            TestUtilClass.addPermissionSet(adminUsers,'LMS_Admin');
            TestUtilClass.addPermissionSet(lmsUsers,'LMS_User');
        }

        TestTrainingPlanData.createSampleData();
        List<Training_Plan__c> tplan = [select id from Training_Plan__c];
        System.assertEquals(1,tplan.size());
        Id tplanId = tplan.get(0).Id;
        Set<Id> selectedUserIds = new Set<Id>();

        for(User u : lmsUsers){
            selectedUserIds.add(u.Id);
        }

        //Test Insert
        Test.startTest();
            System.runAs(adminUsers.get(0)){
                LMS_API.upsertAssignments(selectedUserIds,tplanId);
            }

            List<Training_Plan_Assignment__c> assignments = [select id from Training_Plan_Assignment__c where Training_Plan__c = :tplanId];
            System.assertEquals(5,assignments.size());
            List<Learning_Assignment__c> learningAssignments = [select id from Learning_Assignment__c where Training_Plan_Section_Assignment__r.Training_Plan_Section__r.Training_Plan__c = :tplanId];
            System.assert(learningAssignments.size()>0);
            List<Learning__c> resourceLearnings;

            System.runAs(adminUsers.get(0)){
                //Add an additional shared learning
                //create resource learnings
                resourceLearnings = TestLearningData.createTestLearning(1, 'Resource', true);
                //create training resources
                List<Training_Resource__c> tresources = TestLearningData.createTestTrainingResource(resourceLearnings);
                //Publish resource
                TestLearningData.publishLearning(resourceLearnings.get(0).Id,'resource',tresources.get(0).Id,false);
                List<Training_Plan_Section__c> tplanSections = [select id from Training_Plan_Section__c where Training_Plan__c = :tplanId limit 1];
                //Add to training plan section
                List<Training_Plan_Section_Item__c> tplanSectionItemUpdate = TestTrainingPlanData.createTrainingPlanSectionItems(tplanSections.get(0).Id,resourceLearnings);

                LMS_API.upsertAssignments(selectedUserIds,tplanId);
            }

        Test.stopTest();

        assignments = [select id from Training_Plan_Assignment__c where Training_Plan__c = :tplanId];
        System.assertEquals(5,assignments.size());
        List<Shared_Learning_Assignment__c> sharedlearningAssignments = [select id from Shared_Learning_Assignment__c where Learning__c in :resourceLearnings];
        System.assertEquals(5,sharedlearningAssignments.size());

    }

    static testmethod void testUpsertTrainingPlanAssignmentWithAchievements(){

        //Create admin users
        List<User> adminUsers = TestUtilClass.createUsers(2,'System Administrator');
        List<User> lmsUsers = TestUtilClass.createUsers(5,'Standard User');

        System.runAs(adminUsers.get(0)){
            //Assign corresponding perm sets
            TestUtilClass.addPermissionSet(adminUsers,'LMS_Admin');
            TestUtilClass.addPermissionSet(lmsUsers,'LMS_User');
        }

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

        //Test Insert
        Test.startTest();
            System.runAs(adminUsers.get(0)){
                LMS_API.upsertAssignments(selectedUserIds,tplanId);
            }

            List<Training_Plan_Assignment__c> assignments = [select id from Training_Plan_Assignment__c where Training_Plan__c = :tplanId];
            System.assertEquals(5,assignments.size());
            List<Learning_Assignment__c> learningAssignments = [select id from Learning_Assignment__c where Training_Plan_Section_Assignment__r.Training_Plan_Section__r.Training_Plan__c = :tplanId];
            System.assert(learningAssignments.size()>0);
            List<Learning__c> resourceLearnings;

            System.runAs(adminUsers.get(0)){
                //Add an additional shared learning
                //create resource learnings
                resourceLearnings = TestLearningData.createTestLearning(1, 'Resource', true);
                //create training resources
                List<Training_Resource__c> tresources = TestLearningData.createTestTrainingResource(resourceLearnings);
                //Publish resource
                TestLearningData.publishLearning(resourceLearnings.get(0).Id,'resource',tresources.get(0).Id,false);
                List<Training_Plan_Section__c> tplanSections = [select id from Training_Plan_Section__c where Training_Plan__c = :tplanId limit 1];
                //Add to training plan section
                List<Training_Plan_Section_Item__c> tplanSectionItemUpdate = TestTrainingPlanData.createTrainingPlanSectionItems(tplanSections.get(0).Id,resourceLearnings);

                LMS_API.upsertAssignments(selectedUserIds,tplanId);
            }

        Test.stopTest();

        assignments = [select id from Training_Plan_Assignment__c where Training_Plan__c = :tplanId];
        System.assertEquals(5,assignments.size());
        List<Shared_Learning_Assignment__c> sharedlearningAssignments = [select id from Shared_Learning_Assignment__c where Learning__c in :resourceLearnings];
        System.assertEquals(5,sharedlearningAssignments.size());
        List<Achievement_Assignment__c> achievementAssignments = [select Id from Achievement_Assignment__c where Training_Plan_Achievement__c in :lTPlanAchievement and Status__c = 'Eligible'];
        System.assertEquals(lmsUsers.size(), achievementAssignments.size());
    }

    static testmethod void testImportData(){
        System.assertEquals(0,getTrainingPlanCount());
        System.assertEquals(0,getTrainingTrackCount());
        Test.startTest();
        LMSStartController cont = new LMSStartController();
        LMS_API.importJSON(LMSInit.fetchInitData('almond_LMSInitDataWithTracks'),false);
        System.assertEquals(1,getTrainingPlanCount());
        System.assertEquals(1,getTrainingTrackCount());
        Test.stopTest();
    }

    static testmethod void testImportDataWithTimeStamps(){
        System.assertEquals(0,getTrainingPlanCount());
        System.assertEquals(0,getTrainingTrackCount());
        Test.startTest();
        LMSStartController cont = new LMSStartController();
        LMS_API.importJSON(LMSInit.fetchInitData('almond_LMSInitDataWithTracks'),true);
        System.assertEquals(1,getTrainingPlanCount());
        System.assertEquals(1,getTrainingTrackCount());
        Test.stopTest();
    }

    static Integer getTrainingPlanCount(){
        return [select count() from Training_Plan__c];
    }

    static Integer getTrainingTrackCount(){
        return [select count() from Training_Track__c];
    }


}
