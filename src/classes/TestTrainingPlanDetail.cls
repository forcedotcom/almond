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
public class TestTrainingPlanDetail {

    static testmethod void testTrainingPlanDetailMobile(){

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
                LMSService.upsertAssignments(selectedUserIds,tplanId,null);
            }
        Test.stopTest();

        System.runAs(lmsUsers.get(0)){
            PageReference pageRef = Page.TrainingPlanDetail;
            Test.setCurrentPage(pageRef);
            pageRef.getHeaders().put('User-Agent', 'iPhone');
            ApexPages.Standardcontroller stdcontroller = New ApexPages.StandardController(tplan.get(0));
            TrainingPlanDetailController extension = new TrainingPlanDetailController(stdcontroller);

            List<Training_Plan_Section__c> ltpsec = [select id from Training_Plan_Section__c where Training_Plan__c =: tplan.get(0).Id order by Order__c asc];
            System.assert(ltpsec.size() == 3);

            List<Training_Plan_Section_Item__c> ltpsitem = [select id from Training_Plan_Section_Item__c where Training_Plan_Section__c =: ltpsec.get(0).Id order by Order__c asc];
            System.assert(ltpsitem.size() == 1, 'Training Plan Section Item issues, size = ' + ltpsitem.size());

            extension.selectedSectionId = ltpsec.get(0).Id;
            extension.selectedItemId = ltpsitem.get(0).Id;
            extension.retrieveItemDetails();
            extension.launchLearning();
            System.assert(extension.selectedItemStatusLabel == 'default', 'Error on selectedItemStatusLabel, label = ' + extension.selectedItemStatusLabel);

            List<Learning_Assignment__c> lassignment = [select Id,
                                                            Progress__c from Learning_Assignment__c
                                                            where Training_Plan__c =: tplanId
                                                            and Training_Plan_Section__c =:ltpsec.get(0).Id
                                                            and User__c =: lmsUsers.get(0).Id];
            for(Learning_Assignment__c oa : lassignment){
                oa.Progress__c = 'In Progress';
            }

            upsert lassignment;

            extension.init();
            extension.selectedSectionId = ltpsec.get(0).Id;
            extension.selectedItemId = ltpsitem.get(0).Id;
            extension.retrieveItemDetails();
            extension.launchLearning();
            System.assert(extension.selectedItemStatusLabel == 'warning', 'Error on selectedItemStatusLabel, label = ' + extension.selectedItemStatusLabel);

            for(Learning_Assignment__c oa : lassignment){
                oa.Progress__c = 'Completed';
            }

            upsert lassignment;

            extension.init();
            extension.selectedSectionId = ltpsec.get(0).Id;
            extension.selectedItemId = ltpsitem.get(0).Id;
            extension.retrieveItemDetails();
            extension.launchLearning();
            System.assert(extension.selectedItemStatusLabel == 'success', 'Error on selectedItemStatusLabel, label = ' + extension.selectedItemStatusLabel);

            List<Training_Plan_Section_Item__c> ltpsitem2 = [select id from Training_Plan_Section_Item__c where Training_Plan_Section__c =: ltpsec.get(1).Id order by Order__c asc];
            System.assert(ltpsitem2.size() == 3, 'Training Plan Section Item issues, size = ' + ltpsitem2.size());

            extension.selectedSectionId = ltpsec.get(1).Id;
            extension.selectedItemId = ltpsitem2.get(0).Id;
            extension.retrieveItemDetails();
            extension.launchLearning();

            List<Learning_Assignment__c> lassignment2 = [select Id,
                                                            Progress__c from Learning_Assignment__c
                                                            where Training_Plan__c =: tplanId
                                                            and Training_Plan_Section__c =:ltpsec.get(1).Id
                                                            and User__c =: lmsUsers.get(0).Id];
            for(Learning_Assignment__c oa2 : lassignment2){
                oa2.Progress__c = 'Completed';
            }

            upsert lassignment2;

            List<Training_Plan_Section_Item__c> ltpsitem3 = [select id from Training_Plan_Section_Item__c where Training_Plan_Section__c =: ltpsec.get(2).Id order by Order__c asc];
            System.assert(ltpsitem3.size() == 3, 'Training Plan Section Item issues, size = ' + ltpsitem3.size());

            extension.selectedSectionId = ltpsec.get(2).Id;
            extension.selectedItemId = ltpsitem3.get(0).Id;
            extension.retrieveItemDetails();
            extension.launchLearning();

            List<Learning_Assignment__c> lassignment3 = [select Id,
                                                            Progress__c from Learning_Assignment__c
                                                            where Training_Plan__c =: tplanId
                                                            and Training_Plan_Section__c =:ltpsec.get(2).Id
                                                            and User__c =: lmsUsers.get(0).Id];
            for(Learning_Assignment__c oa3 : lassignment3){
                oa3.Progress__c = 'Completed';
            }
            upsert lassignment3;

        }
    }

    static testmethod void testTrainingPlanDetailWeb(){

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
                LMSService.upsertAssignments(selectedUserIds,tplanId,null);
            }
        Test.stopTest();

        System.runAs(lmsUsers.get(0)){
            PageReference pageRef = Page.TrainingPlanDetail;
            Test.setCurrentPage(pageRef);
            pageRef.getHeaders().put('User-Agent', 'Mozilla');
            ApexPages.Standardcontroller stdcontroller = New ApexPages.StandardController(tplan.get(0));
            TrainingPlanDetailController extension = new TrainingPlanDetailController(stdcontroller);

            List<Training_Plan_Section__c> ltpsec = [select id from Training_Plan_Section__c where Training_Plan__c =: tplan.get(0).Id order by Order__c asc];
            System.assert(ltpsec.size() == 3);

            List<Training_Plan_Section_Item__c> ltpsitem = [select id from Training_Plan_Section_Item__c where Training_Plan_Section__c =: ltpsec.get(0).Id order by Order__c asc];
            System.assert(ltpsitem.size() == 1, 'Training Plan Section Item issues, size = ' + ltpsitem.size());

            extension.selectedSectionId = ltpsec.get(0).Id;
            extension.selectedItemId = ltpsitem.get(0).Id;
            extension.retrieveItemDetails();
            extension.launchLearning();
            System.assert(extension.selectedItemStatusLabel == 'default', 'Error on selectedItemStatusLabel, label = ' + extension.selectedItemStatusLabel);

            List<Learning_Assignment__c> lassignment = [select Id,
                                                            Progress__c from Learning_Assignment__c
                                                            where Training_Plan__c =: tplanId
                                                            and Training_Plan_Section__c =:ltpsec.get(0).Id
                                                            and User__c =: lmsUsers.get(0).Id];
            for(Learning_Assignment__c oa : lassignment){
                oa.Progress__c = 'In Progress';
            }

            upsert lassignment;

            extension.init();
            extension.selectedSectionId = ltpsec.get(0).Id;
            extension.selectedItemId = ltpsitem.get(0).Id;
            extension.retrieveItemDetails();
            extension.launchLearning();
            System.assert(extension.selectedItemStatusLabel == 'warning', 'Error on selectedItemStatusLabel, label = ' + extension.selectedItemStatusLabel);

            for(Learning_Assignment__c oa : lassignment){
                oa.Progress__c = 'Completed';
            }

            upsert lassignment;

            extension.init();
            extension.selectedSectionId = ltpsec.get(0).Id;
            extension.selectedItemId = ltpsitem.get(0).Id;
            extension.retrieveItemDetails();
            extension.launchLearning();
            System.assert(extension.selectedItemStatusLabel == 'success', 'Error on selectedItemStatusLabel, label = ' + extension.selectedItemStatusLabel);

            List<Training_Plan_Section_Item__c> ltpsitem2 = [select id from Training_Plan_Section_Item__c where Training_Plan_Section__c =: ltpsec.get(1).Id order by Order__c asc];
            System.assert(ltpsitem2.size() == 3, 'Training Plan Section Item issues, size = ' + ltpsitem2.size());

            extension.selectedSectionId = ltpsec.get(1).Id;
            extension.selectedItemId = ltpsitem2.get(0).Id;
            extension.retrieveItemDetails();
            extension.launchLearning();

            List<Learning_Assignment__c> lassignment2 = [select Id,
                                                            Progress__c from Learning_Assignment__c
                                                            where Training_Plan__c =: tplanId
                                                            and Training_Plan_Section__c =:ltpsec.get(1).Id
                                                            and User__c =: lmsUsers.get(0).Id];
            for(Learning_Assignment__c oa2 : lassignment2){
                oa2.Progress__c = 'Completed';
            }

            upsert lassignment2;

            List<Training_Plan_Section_Item__c> ltpsitem3 = [select id from Training_Plan_Section_Item__c where Training_Plan_Section__c =: ltpsec.get(2).Id order by Order__c asc];
            System.assert(ltpsitem3.size() == 3, 'Training Plan Section Item issues, size = ' + ltpsitem3.size());

            extension.selectedSectionId = ltpsec.get(2).Id;
            extension.selectedItemId = ltpsitem3.get(0).Id;
            extension.retrieveItemDetails();
            extension.launchLearning();

            List<Learning_Assignment__c> lassignment3 = [select Id,
                                                            Progress__c from Learning_Assignment__c
                                                            where Training_Plan__c =: tplanId
                                                            and Training_Plan_Section__c =:ltpsec.get(2).Id
                                                            and User__c =: lmsUsers.get(0).Id];
            for(Learning_Assignment__c oa3 : lassignment3){
                oa3.Progress__c = 'Completed';
            }
            upsert lassignment3;

        }
    }

    static testmethod void testTrainingPlanDetailChangesOnLearning_KeepNewVersion(){

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
                LMSService.upsertAssignments(selectedUserIds,tplanId,null);
            }
        Test.stopTest();

        System.runAs(lmsUsers.get(0)){
            PageReference pageRef = Page.TrainingPlanDetail;
            Test.setCurrentPage(pageRef);
            pageRef.getHeaders().put('User-Agent', 'iPhone');
            ApexPages.Standardcontroller stdcontroller = New ApexPages.StandardController(tplan.get(0));
            TrainingPlanDetailController extension = new TrainingPlanDetailController(stdcontroller);

            List<Training_Plan_Section__c> ltpsec = [select id from Training_Plan_Section__c where Training_Plan__c =: tplan.get(0).Id order by Order__c asc];
            System.assert(ltpsec.size() == 3);

            List<Training_Plan_Section_Item__c> ltpsitem = [select id from Training_Plan_Section_Item__c where Training_Plan_Section__c =: ltpsec.get(0).Id order by Order__c asc];
            System.assert(ltpsitem.size() == 1, 'Training Plan Section Item issues, size = ' + ltpsitem.size());

            extension.selectedSectionId = ltpsec.get(0).Id;
            extension.selectedItemId = ltpsitem.get(0).Id;
            extension.retrieveItemDetails();
            extension.launchLearning();
            System.assert(extension.selectedItemStatusLabel == 'default', 'Error on selectedItemStatusLabel, label = ' + extension.selectedItemStatusLabel);

            List<Learning_Assignment__c> lassignment = [select Id,
                                                            Progress__c from Learning_Assignment__c
                                                            where Training_Plan__c =: tplanId
                                                            and Training_Plan_Section__c =:ltpsec.get(0).Id
                                                            and User__c =: lmsUsers.get(0).Id];

            for(Learning_Assignment__c oa : lassignment){
                oa.Progress__c = 'Completed';
            }

            upsert lassignment;
        }
        List<Training_Plan_Section__c> ltpsection = [select id from Training_Plan_Section__c where Training_Plan__c =: tplan.get(0).Id order by Order__c asc];

        List<Learning_Assignment__c> lassignment3 = [select Id, Learning__c from Learning_Assignment__c
                                                            where Training_Plan__c =: tplanId
                                                            and Training_Plan_Section__c =:ltpsection.get(2).Id
                                                            and User__c =: lmsUsers.get(0).Id];

        List<Learning__c> learning = [select Id from Learning__c where Id =: lassignment3.get(0).Learning__c];
        //create task
        List<Task__c> ttasks = TestLearningData.createTestTask(learning);
        //publish task learning
        TestLearningData.publishLearning(learning.get(0).Id,'task',ttasks.get(0).Id,false);

        System.runAs(lmsUsers.get(0)){
            PageReference pageRef = Page.TrainingPlanDetail;
            Test.setCurrentPage(pageRef);
            pageRef.getHeaders().put('User-Agent', 'iPhone');
            ApexPages.Standardcontroller stdcontroller = New ApexPages.StandardController(tplan.get(0));
            TrainingPlanDetailController extension = new TrainingPlanDetailController(stdcontroller);

            List<Training_Plan_Section__c> ltpsec = [select id from Training_Plan_Section__c where Training_Plan__c =: tplan.get(0).Id order by Order__c asc];
            System.assert(ltpsec.size() == 3);

            List<Training_Plan_Section_Item__c> ltpsitem = [select id from Training_Plan_Section_Item__c where Training_Plan_Section__c =: ltpsec.get(0).Id order by Order__c asc];
            System.assert(ltpsitem.size() == 1, 'Training Plan Section Item issues, size = ' + ltpsitem.size());

            extension.selectedSectionId = ltpsec.get(0).Id;
            extension.selectedItemId = ltpsitem.get(0).Id;
            extension.retrieveItemDetails();
            extension.launchLearning();
            extension.updateToNewVersionAndLaunch();

            List<Training_Plan_Section_Item__c> ltpsitem2 = [select id from Training_Plan_Section_Item__c where Training_Plan_Section__c =: ltpsec.get(1).Id order by Order__c asc];
            System.assert(ltpsitem2.size() == 3, 'Training Plan Section Item issues, size = ' + ltpsitem2.size());

            extension.init();
            extension.selectedSectionId = ltpsec.get(1).Id;
            extension.selectedItemId = ltpsitem2.get(1).Id;
            extension.retrieveItemDetails();
            extension.launchLearning();

        }
    }


    static testmethod void testTrainingPlanDetailChangesOnLearning_KeepOldVersion(){

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
                LMSService.upsertAssignments(selectedUserIds,tplanId,null);
            }
        Test.stopTest();

        System.runAs(lmsUsers.get(0)){
            PageReference pageRef = Page.TrainingPlanDetail;
            Test.setCurrentPage(pageRef);
            pageRef.getHeaders().put('User-Agent', 'iPhone');
            ApexPages.Standardcontroller stdcontroller = New ApexPages.StandardController(tplan.get(0));
            TrainingPlanDetailController extension = new TrainingPlanDetailController(stdcontroller);

            List<Training_Plan_Section__c> ltpsec = [select id from Training_Plan_Section__c where Training_Plan__c =: tplan.get(0).Id order by Order__c asc];
            System.assert(ltpsec.size() == 3);

            List<Training_Plan_Section_Item__c> ltpsitem = [select id from Training_Plan_Section_Item__c where Training_Plan_Section__c =: ltpsec.get(0).Id order by Order__c asc];
            System.assert(ltpsitem.size() == 1, 'Training Plan Section Item issues, size = ' + ltpsitem.size());

            extension.selectedSectionId = ltpsec.get(0).Id;
            extension.selectedItemId = ltpsitem.get(0).Id;
            extension.retrieveItemDetails();
            extension.launchLearning();
            System.assert(extension.selectedItemStatusLabel == 'default', 'Error on selectedItemStatusLabel, label = ' + extension.selectedItemStatusLabel);

            List<Learning_Assignment__c> lassignment = [select Id,
                                                            Progress__c from Learning_Assignment__c
                                                            where Training_Plan__c =: tplanId
                                                            and Training_Plan_Section__c =:ltpsec.get(0).Id
                                                            and User__c =: lmsUsers.get(0).Id];

            for(Learning_Assignment__c oa : lassignment){
                oa.Progress__c = 'Completed';
            }

            upsert lassignment;
        }

        //Update learning version on Plan
        List<Training_Plan_Section__c> ltpsection = [select id from Training_Plan_Section__c where Training_Plan__c =: tplan.get(0).Id order by Order__c asc];

        List<Learning_Assignment__c> lassignment3 = [select Id, Learning__c from Learning_Assignment__c
                                                            where Training_Plan__c =: tplanId
                                                            and Training_Plan_Section__c =:ltpsection.get(2).Id
                                                            and User__c =: lmsUsers.get(0).Id];

        List<Learning__c> learning = [select Id from Learning__c where Id =: lassignment3.get(0).Learning__c];
        //create task
        List<Task__c> ttasks = TestLearningData.createTestTask(learning);
        //publish task learning
        TestLearningData.publishLearning(learning.get(0).Id,'task',ttasks.get(0).Id,false);

        System.runAs(lmsUsers.get(0)){
            PageReference pageRef = Page.TrainingPlanDetail;
            Test.setCurrentPage(pageRef);
            pageRef.getHeaders().put('User-Agent', 'iPhone');
            ApexPages.Standardcontroller stdcontroller = New ApexPages.StandardController(tplan.get(0));
            TrainingPlanDetailController extension = new TrainingPlanDetailController(stdcontroller);

            List<Training_Plan_Section__c> ltpsec = [select id from Training_Plan_Section__c where Training_Plan__c =: tplan.get(0).Id order by Order__c asc];
            System.assert(ltpsec.size() == 3);

            List<Training_Plan_Section_Item__c> ltpsitem = [select id from Training_Plan_Section_Item__c where Training_Plan_Section__c =: ltpsec.get(0).Id order by Order__c asc];
            System.assert(ltpsitem.size() == 1, 'Training Plan Section Item issues, size = ' + ltpsitem.size());

            extension.selectedSectionId = ltpsec.get(0).Id;
            extension.selectedItemId = ltpsitem.get(0).Id;
            extension.retrieveItemDetails();
            extension.launchLearning();
            extension.keepOldVersionAndLaunch();

            List<Training_Plan_Section_Item__c> ltpsitem2 = [select id from Training_Plan_Section_Item__c where Training_Plan_Section__c =: ltpsec.get(1).Id order by Order__c asc];
            System.assert(ltpsitem2.size() == 3, 'Training Plan Section Item issues, size = ' + ltpsitem2.size());

            extension.init();
            extension.selectedSectionId = ltpsec.get(1).Id;
            extension.selectedItemId = ltpsitem2.get(1).Id;
            extension.retrieveItemDetails();
            extension.launchLearning();

        }
    }

    static testmethod void testTrainingPlanDetailWebnNoMainAchievement(){

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
        List<Training_Plan_Section__c> tplanSections = [select id,Training_Plan__c from Training_Plan_Section__c where Training_Plan__c = :tplan.get(0).id];


        List<Achievement_Category__c> lAchieveCat = TestAchievementData.createAchievementCategories(1);
        List<Achievement__c> lAchievement = TestAchievementData.createAchievements(1, lAchieveCat.get(0).Id, 'Achievements');
        List<Training_Plan_Achievement__c> lTPlanSectionAchievements = TestTrainingPlanData.createTrainingPlanSectionAchievements(new List<Training_Plan_Section__c>{tplanSections.get(0)},lAchievement);

        Id tplanId = tplan.get(0).Id;
        Set<Id> selectedUserIds = new Set<Id>();

        for(User u : lmsUsers){
            selectedUserIds.add(u.Id);
        }

        //Test Insert
        Test.startTest();
            System.runAs(adminUsers.get(0)){
                LMSService.upsertAssignments(selectedUserIds,tplanId,null);
            }
        Test.stopTest();

        System.runAs(lmsUsers.get(0)){
            PageReference pageRef = Page.TrainingPlanDetail;
            Test.setCurrentPage(pageRef);
            pageRef.getHeaders().put('User-Agent', 'Mozilla');
            ApexPages.Standardcontroller stdcontroller = New ApexPages.StandardController(tplan.get(0));
            TrainingPlanDetailController extension = new TrainingPlanDetailController(stdcontroller);

        }
    }

    static testmethod void testTrainingPlanDetailWithMultipleAchievements(){

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
        List<Training_Plan_Section__c> tplanSections = [select id,Training_Plan__c from Training_Plan_Section__c where Training_Plan__c = :tplan.get(0).id];


        List<Achievement_Category__c> lAchieveCat = TestAchievementData.createAchievementCategories(1);
        //Create multiple achievments tied to the plan
        List<Achievement__c> lAchievement = TestAchievementData.createAchievements(2, lAchieveCat.get(0).Id, 'Achievements');
        List<Achievement__c> lSectionAchievements = TestAchievementData.createAchievements(2, lAchieveCat.get(0).Id, 'Achievements');
        List<Training_Plan_Achievement__c> lTPlanAchievement1 = TestTrainingPlanData.createTrainingPlanAchievements(tplan, new List<Achievement__c>{lAchievement.get(0)});
        List<Training_Plan_Achievement__c> lTPlanAchievement2 = TestTrainingPlanData.createTrainingPlanAchievements(tplan, new List<Achievement__c>{lAchievement.get(1)});
        List<Training_Plan_Achievement__c> lTPlanSectionAchievements1 = TestTrainingPlanData.createTrainingPlanSectionAchievements(new List<Training_Plan_Section__c>{tplanSections.get(0)},new List<Achievement__c>{lSectionAchievements.get(0)});
        List<Training_Plan_Achievement__c> lTPlanSectionAchievements2 = TestTrainingPlanData.createTrainingPlanSectionAchievements(new List<Training_Plan_Section__c>{tplanSections.get(0)},new List<Achievement__c>{lSectionAchievements.get(1)});

        Id tplanId = tplan.get(0).Id;
        Set<Id> selectedUserIds = new Set<Id>();

        for(User u : lmsUsers){
            selectedUserIds.add(u.Id);
        }

        //Test Insert
        Test.startTest();
            System.runAs(adminUsers.get(0)){
                LMSService.upsertAssignments(selectedUserIds,tplanId,null);
            }
        Test.stopTest();

        System.runAs(lmsUsers.get(0)){
            PageReference pageRef = Page.TrainingPlanDetail;
            Test.setCurrentPage(pageRef);
            pageRef.getHeaders().put('User-Agent', 'Mozilla');
            ApexPages.Standardcontroller stdcontroller = New ApexPages.StandardController(tplan.get(0));
            TrainingPlanDetailController extension = new TrainingPlanDetailController(stdcontroller);

        }
    }

}
