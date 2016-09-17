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
public class TestLearning {

    static testmethod void testLearningQuizAndPreview(){

        //create users
        List<User> systemUsers = TestUtilClass.createUsers(1,'System Administrator');
        TestUtilClass.addPermissionSet(systemUsers, 'LMS_Admin');

        System.runAs(systemUsers.get(0)){

            //create learning
            List<Learning__c> learning = TestLearningData.createTestLearning(1, 'Quiz', false);

            //create quiz
            List<Quiz__c> quiz = TestLearningData.createTestQuiz(learning);

            //create question line
            List<Question_Line__c> qline = TestLearningData.createTestQuestionLine(quiz, 3);

            //create question
            List<Question__c> question = TestLearningData.createTestQuestions(qline, 4, null);


            List<Learning_Version__c> learningversions = [select id from Learning_Version__c
                                                                where Type__c = 'Preview'
                                                                and Learning__c = :learning.get(0).Id];

            System.assert(learningversions.size() == 0, 'Learning has already been previewed');

            PageReference pageRef = Page.Learning_Preview;
            Test.setCurrentPage(pageRef);
            ApexPages.Standardcontroller stdcontroller = New ApexPages.StandardController(learning.get(0));
            Learning_Preview_Ext extension = new Learning_Preview_Ext(stdcontroller);
            System.assert(extension.learning != null, 'Unable to retrieve learning object');
            List<sObject> lsobjects = extension.getContents();
            System.assert(lsobjects.size() == 1, 'getContents is wrong');
            LearningPreviewRedirectController.previewContent(learning.get(0).Id, quiz.get(0).Id);

            List<Learning_Version__c> learningversions2 = [select id from Learning_Version__c
                                                                where Type__c = 'Preview'
                                                                and Learning__c = :learning.get(0).Id];

            System.assert(learningversions2.size() == 1, 'Learning has not been previewed, size = ' + learningversions2.size());

            List<Learning_Assignment__c> previewAssignments = [select id, name from Learning_Assignment__c
                                                                    where Learning__c = :learning.get(0).Id
                                                                    and Is_Test_Assignment__c = true];

        System.assert(previewAssignments.size() == 1, 'previewAssignments failed, size = ' + previewAssignments.size());
        }

    }

    static testmethod void testLearningTrainingResourceAndPreview(){

        //create users
        List<User> systemUsers = TestUtilClass.createUsers(1,'System Administrator');
        TestUtilClass.addPermissionSet(systemUsers, 'LMS_Admin');

        System.runAs(systemUsers.get(0)){

            //create learning
            List<Learning__c> learning = TestLearningData.createTestLearning(1, 'Resource', false);

            //create training resource
            List<Training_Resource__c> tresource = TestLearningData.createTestTrainingResource(learning);


            List<Learning_Version__c> learningversions = [select id from Learning_Version__c
                                                                where Type__c = 'Preview'
                                                                and Learning__c = :learning.get(0).Id];

            System.assert(learningversions.size() == 0, 'Learning has already been previewed');

            PageReference pageRef = Page.Learning_Preview;
            Test.setCurrentPage(pageRef);
            ApexPages.Standardcontroller stdcontroller = New ApexPages.StandardController(learning.get(0));
            Learning_Preview_Ext extension = new Learning_Preview_Ext(stdcontroller);

            System.assert(extension.learning != null, 'Unable to retrieve learning object');
            List<sObject> lsobjects = extension.getContents();
            System.assert(lsobjects.size() == 1, 'getContents is wrong');
            LearningPreviewRedirectController.previewContent(learning.get(0).Id, tresource.get(0).Id);
            
            List<Learning_Version__c> learningversions2 = [select id from Learning_Version__c
                                                                where Type__c = 'Preview'
                                                                and Learning__c = :learning.get(0).Id];

            System.assert(learningversions2.size() == 1, 'Learning has not been previewed, size = ' + learningversions2.size());

            List<Learning_Assignment__c> previewAssignments = [select id, name from Learning_Assignment__c
                                                                    where Learning__c = :learning.get(0).Id
                                                                    and Is_Test_Assignment__c = true];

            System.assert(previewAssignments.size() == 1, 'previewAssignments failed, size = ' + previewAssignments.size());
        }

    }

    static testmethod void testLearningTaskAndPreview(){

        //create users
        List<User> systemUsers = TestUtilClass.createUsers(1,'System Administrator');
        TestUtilClass.addPermissionSet(systemUsers, 'LMS_Admin');

        System.runAs(systemUsers.get(0)){

            //create learning
            List<Learning__c> learning = TestLearningData.createTestLearning(1, 'Task', false);

            //create task
            List<Task__c> task = TestLearningData.createTestTask(learning);

            List<Learning_Version__c> learningversions = [select id from Learning_Version__c
                                                                where Type__c = 'Preview'
                                                                and Learning__c = :learning.get(0).Id];

            System.assert(learningversions.size() == 0, 'Learning has already been previewed');

            PageReference pageRef = Page.Learning_Preview;
            Test.setCurrentPage(pageRef);
            ApexPages.Standardcontroller stdcontroller = New ApexPages.StandardController(learning.get(0));
            Learning_Preview_Ext extension = new Learning_Preview_Ext(stdcontroller);

            System.assert(extension.learning != null, 'Unable to retrieve learning object');
            List<sObject> lsobjects = extension.getContents();
            System.assert(lsobjects.size() == 1, 'getContents is wrong');
            LearningPreviewRedirectController.previewContent(learning.get(0).Id, task.get(0).Id);
            
            
            List<Learning_Version__c> learningversions2 = [select id from Learning_Version__c
                                                                where Type__c = 'Preview'
                                                                and Learning__c = :learning.get(0).Id];

            System.assert(learningversions2.size() == 1, 'Learning has not been previewed, size = ' + learningversions2.size());

            List<Learning_Assignment__c> previewAssignments = [select id, name from Learning_Assignment__c
                                                                    where Learning__c = :learning.get(0).Id
                                                                    and Is_Test_Assignment__c = true];

            System.assert(previewAssignments.size() == 1, 'previewAssignments failed, size = ' + previewAssignments.size());
        }

    }

    static testmethod void testExistingLearningPreview(){

        //create users
        List<User> systemUsers = TestUtilClass.createUsers(2,'System Administrator');
        TestUtilClass.addPermissionSet(systemUsers, 'LMS_Admin');

        List<Learning__c> learning;
        List<Task__c> task;

        System.runAs(systemUsers.get(0)){

            //create learning
            learning = TestLearningData.createTestLearning(1, 'Task', false);

            //create task
            task = TestLearningData.createTestTask(learning);


            List<Learning_Version__c> learningversions = [select id from Learning_Version__c
                                                                where Type__c = 'Preview'
                                                                and Learning__c = :learning.get(0).Id];

            System.assert(learningversions.size() == 0, 'Learning has already been previewed');

            PageReference pageRef = Page.Learning_Preview;
            Test.setCurrentPage(pageRef);
            ApexPages.Standardcontroller stdcontroller = New ApexPages.StandardController(learning.get(0));
            Learning_Preview_Ext extension = new Learning_Preview_Ext(stdcontroller);

            System.assert(extension.learning != null, 'Unable to retrieve learning object');
            List<sObject> lsobjects = extension.getContents();
            System.assert(lsobjects.size() == 1, 'getContents is wrong');
            LearningPreviewRedirectController.previewContent(learning.get(0).Id, task.get(0).Id);

            List<Learning_Version__c> learningversions2 = [select id from Learning_Version__c
                                                                where Type__c = 'Preview'
                                                                and Learning__c = :learning.get(0).Id];

            System.assert(learningversions2.size() == 1, 'Learning has not been previewed, size = ' + learningversions2.size());

            List<Learning_Assignment__c> previewAssignments = [select id, name from Learning_Assignment__c
                                                                    where Learning__c = :learning.get(0).Id
                                                                    and Is_Test_Assignment__c = true];

            System.assert(previewAssignments.size() == 1, 'previewAssignments failed, size = ' + previewAssignments.size());
        }

        System.runAs(systemUsers.get(1)){
            List<Learning_Version__c> learningversions = [select id from Learning_Version__c
                                                                where Type__c = 'Preview'
                                                                and Learning__c = :learning.get(0).Id];

            System.assert(learningversions.size() == 1, 'Learning has already been previewed');

            PageReference pageRef = Page.Learning_Preview;
            Test.setCurrentPage(pageRef);
            ApexPages.Standardcontroller stdcontroller = New ApexPages.StandardController(learning.get(0));
            Learning_Preview_Ext extension = new Learning_Preview_Ext(stdcontroller);

            System.assert(extension.learning != null, 'Unable to retrieve learning object');
            List<sObject> lsobjects = extension.getContents();
            System.assert(lsobjects.size() == 1, 'getContents is wrong');
            LearningPreviewRedirectController.previewContent(learning.get(0).Id, task.get(0).Id);

            List<Learning_Version__c> learningversions2 = [select id from Learning_Version__c
                                                                where Type__c = 'Preview'
                                                                and Learning__c = :learning.get(0).Id];

            System.assert(learningversions2.size() == 1, 'Learning has not been previewed, size = ' + learningversions2.size());
            System.assert(learningversions2.get(0).Id == learningversions.get(0).Id, 'Learning has not been previewed, size = ' + learningversions2.size());

        }

    }

    static testmethod void testLearningPreviewFail(){

        //create users
        List<User> systemUsers = TestUtilClass.createUsers(1,'System Administrator');

        TestUtilClass.addPermissionSet(systemUsers, 'LMS_Admin');

        System.runAs(systemUsers.get(0)){

            //create learning
            List<Learning__c> learning = TestLearningData.createTestLearning(1, 'Task', false);

            //create task
            List<Task__c> task = TestLearningData.createTestTask(learning);

            List<Learning_Version__c> learningversions = [select id from Learning_Version__c
                                                                where Type__c = 'Preview'
                                                                and Learning__c = :learning.get(0).Id];

            System.assert(learningversions.size() == 0, 'Learning has already been previewed');

            PageReference pageRef = Page.Learning_Preview;
            Test.setCurrentPage(pageRef);
            ApexPages.Standardcontroller stdcontroller = New ApexPages.StandardController(learning.get(0));
            Learning_Preview_Ext extension = new Learning_Preview_Ext(stdcontroller);

            System.assert(extension.learning != null, 'Unable to retrieve learning object');
            List<sObject> lsobjects = extension.getContents();
            System.assert(lsobjects.size() == 1, 'getContents is wrong');
            LearningPreviewRedirectController.previewContent(learning.get(0).Id, null);

            List<Learning_Version__c> learningversions2 = [select id from Learning_Version__c
                                                                where Type__c = 'Preview'
                                                                and Learning__c = :learning.get(0).Id];

            System.assert(learningversions2.size() == 0, 'Learning has not been previewed, size = ' + learningversions2.size());

            List<Learning_Assignment__c> previewAssignments = [select id, name from Learning_Assignment__c
                                                                    where Learning__c = :learning.get(0).Id
                                                                    and Is_Test_Assignment__c = true];

            System.assert(previewAssignments.size() == 0, 'previewAssignments failed, size = ' + previewAssignments.size());
        }

    }

    static testmethod void testLearningQuizAndPublish(){

        //create users
        List<User> systemUsers = TestUtilClass.createUsers(1,'System Administrator');
        TestUtilClass.addPermissionSet(systemUsers, 'LMS_Admin');

        System.runAs(systemUsers.get(0)){

            //create learning
            List<Learning__c> learning = TestLearningData.createTestLearning(1, 'Quiz', false);

            //create quiz
            List<Quiz__c> quiz = TestLearningData.createTestQuiz(learning);

            //create question line
            List<Question_Line__c> qline = TestLearningData.createTestQuestionLine(quiz, 3);

            //create question
            List<Question__c> question = TestLearningData.createTestQuestions(qline, 4, null);

            List<Learning_Version__c> learningversions = [select id from Learning_Version__c
                                                                where Type__c = 'Publish'
                                                                and Learning__c = :learning.get(0).Id];

            System.assert(learningversions.size() == 0, 'Learning has already been previewed');

            PageReference pageRef = Page.Learning_Publish;
            Test.setCurrentPage(pageRef);
            ApexPages.Standardcontroller stdcontroller = New ApexPages.StandardController(learning.get(0));
            Learning_Publish_Ext extension = new Learning_Publish_Ext(stdcontroller);
            extension.dummyLearningVersion.Version_selection_behavior__c = 'Update version on launch';
            List<sObject> lsobjects = extension.getContents();
            System.assert(lsobjects.size() == 1, 'getContents is wrong');
            extension.publishContent();

            List<Learning_Version__c> learningversions2 = [select id from Learning_Version__c
                                                                where Type__c = 'Published'
                                                                and Learning__c = :learning.get(0).Id];

            System.assert(learningversions2.size() == 1, 'Learning has not been published, size = ' + learningversions2.size());

            List<Learning__c> pub_learning = [select Id, Published__c, Current_Published_Version__c from Learning__c where Id =:learning.get(0).Id  ];

            System.assert(pub_learning.get(0).Published__c == true, 'Learning was not published');
            System.assert(pub_learning.get(0).Current_Published_Version__c == learningversions2.get(0).Id, 'Learning was not published');
        }

    }

    static testmethod void testLearningTrainingResourceAndPublish(){

        //create users
        List<User> systemUsers = TestUtilClass.createUsers(1,'System Administrator');
        TestUtilClass.addPermissionSet(systemUsers, 'LMS_Admin');

        System.runAs(systemUsers.get(0)){

            //create learning
            List<Learning__c> learning = TestLearningData.createTestLearning(1, 'Resource', false);

            //create training resource
            List<Training_Resource__c> tresource = TestLearningData.createTestTrainingResource(learning);

            List<Learning_Version__c> learningversions = [select id from Learning_Version__c
                                                                where Type__c = 'Published'
                                                                and Learning__c = :learning.get(0).Id];

            System.assert(learningversions.size() == 0, 'Learning has already been published');

            PageReference pageRef = Page.Learning_Publish;
            Test.setCurrentPage(pageRef);
            ApexPages.Standardcontroller stdcontroller = New ApexPages.StandardController(learning.get(0));
            Learning_Publish_Ext extension = new Learning_Publish_Ext(stdcontroller);
            extension.dummyLearningVersion.Version_selection_behavior__c = 'Update version on launch';
            List<sObject> lsobjects = extension.getContents();
            System.assert(lsobjects.size() == 1, 'getContents is wrong');
            extension.publishContent();

            List<Learning_Version__c> learningversions2 = [select id from Learning_Version__c
                                                                where Type__c = 'Published'
                                                                and Learning__c = :learning.get(0).Id];

            System.assert(learningversions2.size() == 1, 'Learning has not been published, size = ' + learningversions2.size());

            List<Learning__c> pub_learning = [select Id, Published__c, Current_Published_Version__c from Learning__c where Id =:learning.get(0).Id  ];
            System.assert(pub_learning.get(0).Published__c == true, 'Learning was not published');
            System.assert(pub_learning.get(0).Current_Published_Version__c == learningversions2.get(0).Id, 'Learning was not published');
        }

    }

    static testmethod void testLearningTaskAndPublish(){
        //create users
        List<User> systemUsers = TestUtilClass.createUsers(1,'System Administrator');
        TestUtilClass.addPermissionSet(systemUsers, 'LMS_Admin');

        System.runAs(systemUsers.get(0)){

            //create learning
            List<Learning__c> learning = TestLearningData.createTestLearning(1, 'Task', false);

            //create task
            List<Task__c> task = TestLearningData.createTestTask(learning);

            List<Learning_Version__c> learningversions = [select id from Learning_Version__c
                                                                where Type__c = 'Published'
                                                                and Learning__c = :learning.get(0).Id];

            System.assert(learningversions.size() == 0, 'Learning has already been published');

            PageReference pageRef = Page.Learning_Publish;
            Test.setCurrentPage(pageRef);
            ApexPages.Standardcontroller stdcontroller = New ApexPages.StandardController(learning.get(0));
            Learning_Publish_Ext extension = new Learning_Publish_Ext(stdcontroller);
            extension.dummyLearningVersion.Version_selection_behavior__c = 'Update version on launch';
            List<sObject> lsobjects = extension.getContents();
            System.assert(lsobjects.size() == 1, 'getContents is wrong');
            extension.publishContent();

            List<Learning_Version__c> learningversions2 = [select id from Learning_Version__c
                                                                where Type__c = 'Published'
                                                                and Learning__c = :learning.get(0).Id];

            System.assert(learningversions2.size() == 1, 'Learning has not been published, size = ' + learningversions2.size());

            List<Learning__c> pub_learning = [select Id, Published__c, Current_Published_Version__c from Learning__c where Id =:learning.get(0).Id  ];
            System.assert(pub_learning.get(0).Published__c == true, 'Learning was not published');
            System.assert(pub_learning.get(0).Current_Published_Version__c == learningversions2.get(0).Id, 'Learning was not published');
        }

    }

    static testmethod void testLearningTaskRePublish(){

        //create users
        List<User> systemUsers = TestUtilClass.createUsers(2,'System Administrator');
        TestUtilClass.addPermissionSet(systemUsers, 'LMS_Admin');

        List<Learning__c> learning;
        List<Task__c> task;

        System.runAs(systemUsers.get(0)){

            //create learning
            learning = TestLearningData.createTestLearning(1, 'Task', false);

            //create task
            task = TestLearningData.createTestTask(learning);

            List<Learning_Version__c> learningversions = [select id from Learning_Version__c
                                                                where Type__c = 'Published'
                                                                and Learning__c = :learning.get(0).Id];

            System.assert(learningversions.size() == 0, 'Learning has already been published');

            PageReference pageRef = Page.Learning_Publish;
            Test.setCurrentPage(pageRef);
            ApexPages.Standardcontroller stdcontroller = New ApexPages.StandardController(learning.get(0));
            Learning_Publish_Ext extension = new Learning_Publish_Ext(stdcontroller);
            extension.dummyLearningVersion.Version_selection_behavior__c = 'Update version on launch';
            List<sObject> lsobjects = extension.getContents();
            System.assert(lsobjects.size() == 1, 'getContents is wrong');
            extension.publishContent();

            List<Learning_Version__c> learningversions2 = [select id from Learning_Version__c
                                                                where Type__c = 'Published'
                                                                and Learning__c = :learning.get(0).Id];

            System.assert(learningversions2.size() == 1, 'Learning has not been published, size = ' + learningversions2.size());

            List<Learning__c> pub_learning = [select Id, Published__c, Current_Published_Version__c from Learning__c where Id =:learning.get(0).Id  ];
            System.assert(pub_learning.get(0).Published__c == true, 'Learning was not published');
            System.assert(pub_learning.get(0).Current_Published_Version__c == learningversions2.get(0).Id, 'Learning was not published');
        }

        System.runAs(systemUsers.get(1)){
            List<Learning_Version__c> learningversions = [select id from Learning_Version__c
                                                                where Type__c = 'Published'
                                                                and Learning__c = :learning.get(0).Id];

            System.assert(learningversions.size() == 1, 'Learning has already been published');

            PageReference pageRef = Page.Learning_Publish;
            Test.setCurrentPage(pageRef);
            ApexPages.Standardcontroller stdcontroller = New ApexPages.StandardController(learning.get(0));
            Learning_Publish_Ext extension = new Learning_Publish_Ext(stdcontroller);
            extension.dummyLearningVersion.Version_selection_behavior__c = 'Ask user for version selection';
            List<sObject> lsobjects = extension.getContents();
            System.assert(lsobjects.size() == 1, 'getContents is wrong');
            extension.publishContent();

            List<Learning_Version__c> learningversions2 = [select id from Learning_Version__c
                                                                where Type__c = 'Published'
                                                                and Learning__c = :learning.get(0).Id];

            System.assert(learningversions2.size() == 2, 'Learning has not been published, size = ' + learningversions2.size());
        }
    }

}
