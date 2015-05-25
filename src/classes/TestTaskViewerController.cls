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
private class TestTaskViewerController{

    static testMethod void testSimpleTask(){

        //Create admin users
        List<User> adminUsers = TestUtilClass.createUsers(1,'System Administrator');
        List<User> lmsUsers = TestUtilClass.createUsers(1,'Standard User');

        System.runAs(adminUsers.get(0)){
            //Assign corresponding perm sets
            TestUtilClass.addPermissionSet(adminUsers,'LMS_Admin');
            TestUtilClass.addPermissionSet(lmsUsers,'LMS_User');
        }

        Id learningAssignmentId = createTaskViewerData(adminUsers,lmsUsers,false);

            //Test Insert
            PageReference pageRef = Page.TaskViewer;
            pageRef.getParameters().put('aid',learningAssignmentId);
            Test.setCurrentPage(pageRef);
            Test.startTest();
                System.runAs(lmsUsers.get(0)){
                TaskViewerController cont = new TaskViewerController();
                PageReference contRef;
                //Test cancel
                contRef = cont.cancelTask();
                System.assert(cont.redirectURL != null);
                PageReference dummyRef = new PageReference(cont.redirectURL);
                System.assert(dummyRef.getParameters().get('section') != null);
                List<Learning_Assignment__c> assignments;
                assignments = [select id,Progress__c from Learning_Assignment__c where id = :learningAssignmentId];
                System.assertEquals(LMSConstants.ASSIGNMENT_STATUS_NOT_STARTED,assignments.get(0).Progress__c);
                contRef = cont.markCompleted();
                assignments = [select id,Progress__c from Learning_Assignment__c where id = :learningAssignmentId];
                System.assertEquals(LMSConstants.ASSIGNMENT_STATUS_COMPLETED,assignments.get(0).Progress__c);

            }

        Test.stopTest();
    }

    static testMethod void testTaskWithApprovers(){

        //Create admin users
        List<User> adminUsers = TestUtilClass.createUsers(1,'System Administrator');
        List<User> lmsUsers = TestUtilClass.createUsers(1,'Standard User');

        System.runAs(adminUsers.get(0)){
            //Assign corresponding perm sets
            TestUtilClass.addPermissionSet(adminUsers,'LMS_Admin');
            TestUtilClass.addPermissionSet(lmsUsers,'LMS_User');
        }

        Id learningAssignmentId = createTaskViewerData(adminUsers,lmsUsers,true);

            //Test Insert
            PageReference pageRef = Page.TaskViewer;
            pageRef.getParameters().put('aid',learningAssignmentId);
            Test.setCurrentPage(pageRef);
            Test.startTest();
            System.runAs(lmsUsers.get(0)){
                TaskViewerController cont = new TaskViewerController();
                PageReference contRef;
                List<Learning_Assignment__c> assignments;
                assignments = [select id,Progress__c from Learning_Assignment__c where id = :learningAssignmentId];
                System.assertEquals(LMSConstants.ASSIGNMENT_STATUS_NOT_STARTED,assignments.get(0).Progress__c);
                contRef = cont.markCompleted();
                assignments = [select id,Progress__c from Learning_Assignment__c where id = :learningAssignmentId];
                System.assertEquals(LMSConstants.ASSIGNMENT_STATUS_IN_REVIEW,assignments.get(0).Progress__c);

            }

        Test.stopTest();
    }


    static testMethod void testTaskWithAttachment(){

        //Create admin users
        List<User> adminUsers = TestUtilClass.createUsers(1,'System Administrator');
        List<User> lmsUsers = TestUtilClass.createUsers(1,'Standard User');

        System.runAs(adminUsers.get(0)){
            //Assign corresponding perm sets
            TestUtilClass.addPermissionSet(adminUsers,'LMS_Admin');
            TestUtilClass.addPermissionSet(lmsUsers,'LMS_User');
        }

        Id learningAssignmentId = createTaskViewerData(adminUsers,lmsUsers,false);

            //Test Insert
            PageReference pageRef = Page.TaskViewer;
            pageRef.getParameters().put('aid',learningAssignmentId);
            Test.setCurrentPage(pageRef);
            Test.startTest();
            System.runAs(lmsUsers.get(0)){
                TaskViewerController cont = new TaskViewerController();
                PageReference contRef;
                cont.attachment.Body = Blob.valueOf('Test Data');
                List<Learning_Assignment__c> assignments;
                assignments = [select id,Progress__c from Learning_Assignment__c where id = :learningAssignmentId];
                System.assertEquals(LMSConstants.ASSIGNMENT_STATUS_NOT_STARTED,assignments.get(0).Progress__c);
                contRef = cont.markCompletedAndRedirect();
                assignments = [select id,Progress__c from Learning_Assignment__c where id = :learningAssignmentId];
                System.assertEquals(LMSConstants.ASSIGNMENT_STATUS_COMPLETED,assignments.get(0).Progress__c);

            }

        Test.stopTest();
    }

    static testMethod void testLoadingCompletedTask(){

        //Create admin users
        List<User> adminUsers = TestUtilClass.createUsers(1,'System Administrator');
        List<User> lmsUsers = TestUtilClass.createUsers(1,'Standard User');

        System.runAs(adminUsers.get(0)){
            //Assign corresponding perm sets
            TestUtilClass.addPermissionSet(adminUsers,'LMS_Admin');
            TestUtilClass.addPermissionSet(lmsUsers,'LMS_User');
        }

        Id learningAssignmentId = createTaskViewerData(adminUsers,lmsUsers,false);
        List<Learning_Assignment__c> theAssignment = [select id,Progress__c from Learning_Assignment__c where id  = :learningAssignmentId];
        theAssignment.get(0).Progress__c = LMSConstants.ASSIGNMENT_STATUS_COMPLETED;
        update theAssignment.get(0);

            PageReference pageRef = Page.TaskViewer;
            pageRef.getParameters().put('aid',learningAssignmentId);
            Test.setCurrentPage(pageRef);
            Test.startTest();
            System.runAs(lmsUsers.get(0)){
                TaskViewerController cont = new TaskViewerController();
                System.assert(cont.taskCompleted == true);
            }

        Test.stopTest();
    }

    static testMethod void testLoadingInReviewTask(){

        //Create admin users
        List<User> adminUsers = TestUtilClass.createUsers(1,'System Administrator');
        List<User> lmsUsers = TestUtilClass.createUsers(1,'Standard User');

        System.runAs(adminUsers.get(0)){
            //Assign corresponding perm sets
            TestUtilClass.addPermissionSet(adminUsers,'LMS_Admin');
            TestUtilClass.addPermissionSet(lmsUsers,'LMS_User');
        }

        Id learningAssignmentId = createTaskViewerData(adminUsers,lmsUsers,false);
        List<Learning_Assignment__c> theAssignment = [select id,Progress__c from Learning_Assignment__c where id  = :learningAssignmentId];
        theAssignment.get(0).Progress__c = LMSConstants.ASSIGNMENT_STATUS_IN_REVIEW;
        update theAssignment.get(0);

            PageReference pageRef = Page.TaskViewer;
            pageRef.getParameters().put('aid',learningAssignmentId);
            Test.setCurrentPage(pageRef);
            Test.startTest();
            System.runAs(lmsUsers.get(0)){
                TaskViewerController cont = new TaskViewerController();
                System.assert(cont.taskCompleted == true);
                System.assert(cont.taskInReview == true);
            }

        Test.stopTest();
    }


    static testMethod void testUndoTask(){

        //Create admin users
        List<User> adminUsers = TestUtilClass.createUsers(1,'System Administrator');
        List<User> lmsUsers = TestUtilClass.createUsers(1,'Standard User');

        System.runAs(adminUsers.get(0)){
            //Assign corresponding perm sets
            TestUtilClass.addPermissionSet(adminUsers,'LMS_Admin');
            TestUtilClass.addPermissionSet(lmsUsers,'LMS_User');
        }

        Id learningAssignmentId = createTaskViewerData(adminUsers,lmsUsers,false);

        //Test Insert
        PageReference pageRef = Page.TaskViewer;
        pageRef.getParameters().put('aid',learningAssignmentId);
        Test.setCurrentPage(pageRef);
        Test.startTest();
        System.runAs(lmsUsers.get(0)){
            TaskViewerController cont = new TaskViewerController();
            PageReference contRef;
            //Test cancel
            contRef = cont.cancelTask();
            System.assert(cont.redirectURL != null);
            PageReference dummyRef = new PageReference(cont.redirectURL);
            System.assert(dummyRef.getParameters().get('section') != null);
            List<Learning_Assignment__c> assignments;
            assignments = [select id,Progress__c from Learning_Assignment__c where id = :learningAssignmentId];
            System.assertEquals(LMSConstants.ASSIGNMENT_STATUS_NOT_STARTED,assignments.get(0).Progress__c);
            contRef = cont.markCompleted();
            assignments = [select id,Progress__c from Learning_Assignment__c where id = :learningAssignmentId];
            System.assertEquals(LMSConstants.ASSIGNMENT_STATUS_COMPLETED,assignments.get(0).Progress__c);
            contRef = cont.resetTask();
            assignments = [select id,Progress__c from Learning_Assignment__c where id = :learningAssignmentId];
            System.assertEquals(LMSConstants.ASSIGNMENT_STATUS_NOT_STARTED,assignments.get(0).Progress__c);

        }

        Test.stopTest();
    }

    private static Id createTaskViewerData(List<User> adminUsers, List<User> lmsUsers, Boolean hasApprovers){

        //create task learnings
        List<Learning__c> taskLearnings = TestLearningData.createTestLearning(1, 'Task', false);
        //create task resources
        List<Task__c> ttasks = TestLearningData.createTestTask(taskLearnings);

        if(hasApprovers){
            List<User> approvers = TestUtilClass.createUsers(1,'Standard User');
            System.runAs(adminUsers.get(0)){
                TestUtilClass.addPermissionSet(approvers,'LMS_User');
            }

            //Enable manager approval in the task
            Task__c theTask = [select id,Requires_Manager_Approval__c,Add_training_parameters_to_URL__c from Task__c where Id = :ttasks.get(0).Id];
            theTask.Requires_Manager_Approval__c = true;
            theTask.Add_training_parameters_to_URL__c = true;
            update theTask;

            //Add second user as a task approver
            Task_Approver__c ta = new Task_Approver__c();
            ta.Task__c = theTask.Id;
            ta.User__c = approvers.get(0).Id;
            insert ta;
        }

        for(Integer i = 0;i < taskLearnings.size();i++){
            TestLearningData.publishLearning(taskLearnings.get(i).Id,'task',ttasks.get(i).Id,false);
        }
        //Create training plans
        List<Training_Plan__c> tplans = TestTrainingPlanData.createTrainingPlans(new List<TestParams.TrainingPlanParam>{new TestParams.TrainingPlanParam()});
        //Create training plan sections
        List<Training_Plan_Section__c> tplanSections1 = TestTrainingPlanData.createTrainingPlanSections(tplans.get(0).Id,1);
        //Create training plan section items for quizzes
        List<Training_Plan_Section_Item__c> tplan1SectionItems1 = TestTrainingPlanData.createTrainingPlanSectionItems(tplanSections1.get(0).Id,taskLearnings);

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

}
