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
public class TestTrainingPlans {

    static testmethod void testOptionalSectionsValidations(){

        //Create admin users
        List<User> adminUsers = TestUtilClass.createUsers(2,'System Administrator');

        System.runAs(adminUsers.get(0)){
            //Assign corresponding perm sets
            TestUtilClass.addPermissionSet(adminUsers,'LMS_Admin');
        }

        TestTrainingPlanData.createSampleData();
        List<Training_Plan__c> tplan = [select id from Training_Plan__c];
        System.assertEquals(1,tplan.size());
        Id tplanId = tplan.get(0).Id;
        List<Training_Plan_Section__c> tplanSections = [select id,Optional__c from Training_Plan_Section__c where Training_Plan__c = :tplanId];

        //Test Insert
        Test.startTest();

            Training_Plan_Section__c sampleSection = tplanSections.get(0);
            try{
                sampleSection.Optional__c = true;
                update sampleSection;
                System.assert(false,'Section item with optional items cannot be made optional');
            }catch(Exception e){
                System.assert(true);
            }

        Test.stopTest();

    }

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
                LMSService.upsertAssignments(selectedUserIds,tplanId, null);
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

                LMSService.upsertAssignments(selectedUserIds,tplanId,null);
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
                LMSService.upsertAssignments(selectedUserIds,tplanId,null);
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

                LMSService.upsertAssignments(selectedUserIds,tplanId,null);
            }

        Test.stopTest();

        assignments = [select id from Training_Plan_Assignment__c where Training_Plan__c = :tplanId];
        System.assertEquals(5,assignments.size());
        List<Shared_Learning_Assignment__c> sharedlearningAssignments = [select id from Shared_Learning_Assignment__c where Learning__c in :resourceLearnings];
        System.assertEquals(5,sharedlearningAssignments.size());
        List<Achievement_Assignment__c> achievementAssignments = [select Id from Achievement_Assignment__c where Training_Plan_Achievement__c in :lTPlanAchievement and Status__c = 'Eligible'];
        System.assertEquals(lmsUsers.size(), achievementAssignments.size());
    }

    static testmethod void testUpsertAndDeleteTrainingPlanAssignment(){

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

        List<Training_Plan_Assignment__c> assignments = null;
        List<Learning_Assignment__c> learningAssignments = null;

        //Test Insert
        Test.startTest();
            System.runAs(adminUsers.get(0)){
                LMSService.upsertAssignments(selectedUserIds,tplanId,null);
                assignments = [select id from Training_Plan_Assignment__c where Training_Plan__c = :tplanId];
                System.assertEquals(5,assignments.size());
                learningAssignments = [select id from Learning_Assignment__c where Training_Plan_Section_Assignment__r.Training_Plan_Section__r.Training_Plan__c = :tplanId];
                System.assert(learningAssignments.size()>0);
                delete assignments;
            }


        Test.stopTest();

        assignments = [select id from Training_Plan_Assignment__c where Training_Plan__c = :tplanId];
        System.assertEquals(0,assignments.size());
        learningAssignments = [select id from Learning_Assignment__c where Training_Plan_Section_Assignment__r.Training_Plan_Section__r.Training_Plan__c = :tplanId];
        System.assertEquals(0,learningAssignments.size());

    }

    static testMethod void testTrainingPlanAchievementUpdates(){

        TestTrainingPlanData.createSampleData();
        List<Training_Plan__c> tplan = [select id from Training_Plan__c];
        System.assertEquals(1,tplan.size());
        List<Training_Plan_Section__c> tplanSections = [select id,Training_Plan__c from Training_Plan_Section__c where Training_Plan__c = :tplan.get(0).id];

        List<Achievement_Category__c> lAchieveCat = TestAchievementData.createAchievementCategories(1);
        List<Achievement__c> lAchievements = TestAchievementData.createAchievements(3, lAchieveCat.get(0).Id, 'Achievements');
        List<Training_Plan_Achievement__c> lTPlanAchievement = TestTrainingPlanData.createTrainingPlanAchievements(tplan, new List<Achievement__c>{lAchievements.get(0)});
        List<Training_Plan_Achievement__c> lTPlanSectionAchievements1 = TestTrainingPlanData.createTrainingPlanSectionAchievements(new List<Training_Plan_Section__c>{tplanSections.get(0)},new List<Achievement__c>{lAchievements.get(1)});
        List<Training_Plan_Achievement__c> lTPlanSectionAchievements2 = TestTrainingPlanData.createTrainingPlanSectionAchievements(new List<Training_Plan_Section__c>{tplanSections.get(1)},new List<Achievement__c>{lAchievements.get(2)});

        //Test Insert
        Test.startTest();

            //Update a training plan achievement to a section plan achievement
            Training_Plan_Achievement__c tpAchievement = [select id,Training_Plan_Section__c,Type__c from Training_Plan_Achievement__c where id = :lTPlanAchievement.get(0).Id];
            System.assertEquals('Plan',tpAchievement.Type__c);
            tpAchievement.Training_Plan_Section__c = tplanSections.get(2).Id;
            update tpAchievement;
            tpAchievement = [select id,Training_Plan_Section__c,Type__c from Training_Plan_Achievement__c where id = :lTPlanAchievement.get(0).Id];
            System.assertEquals('Section',tpAchievement.Type__c);

        Test.stopTest();


    }

    static testmethod void testTPlansWithSharedLearningAssignments(){

        //Create admin users
        List<User> adminUsers = TestUtilClass.createUsers(2,'System Administrator');
        List<User> lmsUsers = TestUtilClass.createUsers(3,'Standard User');

        System.runAs(adminUsers.get(0)){
            //Assign corresponding perm sets
            TestUtilClass.addPermissionSet(adminUsers,'LMS_Admin');
            TestUtilClass.addPermissionSet(lmsUsers,'LMS_User');
        }

        TestTrainingPlanData.createSampleDataWithSharedLearnings();

        List<Training_Plan__c> tplan = [select id from Training_Plan__c];
        System.assertEquals(2,tplan.size());

        List<Achievement_Category__c> lAchieveCat = TestAchievementData.createAchievementCategories(1);
        List<Achievement__c> lAchievement = TestAchievementData.createAchievements(2, lAchieveCat.get(0).Id, 'Achievements');
        List<Training_Plan_Achievement__c> lTPlanAchievement = TestTrainingPlanData.createTrainingPlanAchievements(tplan, lAchievement);

        Id tplanId = tplan.get(0).Id;
        Id tplanId2 = tplan.get(1).Id;

        Set<Id> selectedUserIds = new Set<Id>();
        for(User u : lmsUsers){
            selectedUserIds.add(u.Id);
        }
        System.runAs(adminUsers.get(0)){
            //Upsert assignemtns for tplan 1
            LMSService.upsertAssignments(selectedUserIds,tplanId,null);
            //Upsert assignemtns for tplan 2
            LMSService.upsertAssignments(selectedUserIds,tplanId2,null);
        }

        //Test Insert
        Test.startTest();

            List<Learning__c> sharedLearningSample = [select id
                                                    ,Sync_progress__c
                                                    from Learning__c
                                                    where RecordType.DeveloperName = 'Task'];

            Learning__c sharedLearning = sharedLearningSample.get(0);
            System.assert(sharedLearning.Sync_progress__c == true);


            List<Learning_Assignment__c> tplan1LearningAsgmts = [select id
                                                                ,Progress__c
                                                                ,Shared_Learning_Assignment__c
                                                                ,Training_Plan__c
                                                                from Learning_Assignment__c
                                                                where Training_Plan__c = :tplanId
                                                                and Learning__c = :sharedLearning.Id
                                                                and User__c = :lmsUsers.get(0).Id];

            System.assertEquals(1,tplan1LearningAsgmts.size());

            List<Learning_Assignment__c> tplan2LearningAsgmts = [select id
                                                                ,Progress__c
                                                                ,Shared_Learning_Assignment__c
                                                                ,Training_Plan__c
                                                                from Learning_Assignment__c
                                                                where Training_Plan__c = :tplanId2
                                                                and Learning__c = :sharedLearning.Id
                                                                and User__c = :lmsUsers.get(0).Id];

            System.assertEquals(1,tplan2LearningAsgmts.size());

            //Update learning assignment progress in training plan 1
            tplan1LearningAsgmts.get(0).Progress__c = 'Completed';
            update tplan1LearningAsgmts.get(0);

            //Confirm the change has been replicated to the shared learning assignment

            List<Shared_Learning_Assignment__c> sharedLearningAssignments = [select id
                                                                ,Progress__c
                                                                from Shared_Learning_Assignment__c
                                                                where Learning__c = :sharedLearning.Id
                                                                and User__c = :lmsUsers.get(0).Id];
            System.assertEquals(1,sharedLearningAssignments.size());
            System.assertEquals('Completed',sharedLearningAssignments.get(0).Progress__c);

        Test.stopTest();


        //Confirm that learning assignments in training plan 2 have also been updated
        List<Learning_Assignment__c> tplan2LearningAsgmtsUpdated = [select id
                                                            ,Progress__c
                                                            ,Shared_Learning_Assignment__c
                                                            ,Training_Plan__c
                                                            from Learning_Assignment__c
                                                            where Training_Plan__c = :tplanId2
                                                            and Learning__c = :sharedLearning.Id
                                                            and User__c = :lmsUsers.get(0).Id];
        System.assertEquals('Completed',tplan2LearningAsgmtsUpdated.get(0).Progress__c);
    }
}
