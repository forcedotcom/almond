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
private class TestResourceViewerController{

    static testMethod void testSimpleResource(){

        //Create admin users
        List<User> adminUsers = TestUtilClass.createUsers(1,'System Administrator');
        List<User> lmsUsers = TestUtilClass.createUsers(1,'Standard User');

        System.runAs(adminUsers.get(0)){
            //Assign corresponding perm sets
            TestUtilClass.addPermissionSet(adminUsers,'LMS_Admin');
            TestUtilClass.addPermissionSet(lmsUsers,'LMS_User');
        }

        Id learningAssignmentId = createResourceViewerData(adminUsers,lmsUsers,false);

        //Test Insert
        PageReference pageRef = Page.ResourceViewer;
        pageRef.getParameters().put('aid',learningAssignmentId);
        Test.setCurrentPage(pageRef);
        Test.startTest();
            System.runAs(lmsUsers.get(0)){
                ResourceViewerController cont = new ResourceViewerController();
                String contRef = ResourceViewerController.redirectToResource(learningAssignmentId);
                System.assert(contRef != null);
                System.assert(contRef.indexOf('#t=1') != -1);
                List<Learning_Assignment__c> assignments;
                assignments = [select id,Progress__c from Learning_Assignment__c where id = :learningAssignmentId];
                System.assertEquals(LMSConstants.ASSIGNMENT_STATUS_COMPLETED,assignments.get(0).Progress__c);
            }

        Test.stopTest();
    }

    private static Id createResourceViewerData(List<User> adminUsers, List<User> lmsUsers,Boolean preventCompletionOnLaunch){

        //create resource learnings
        List<Learning__c> resourceLearnings = TestLearningData.createTestLearning(1, 'Resource', false);

        //create training resources
        List<Training_Resource__c> tresources = TestLearningData.createTestTrainingResource(resourceLearnings);

        tresources.get(0).Add_training_parameters_to_URL__c = true;
        tresources.get(0).Resource_URL__c = 'www.salesforce.com#t=1'; //forcing no http protocol to cover https replacement
        if(preventCompletionOnLaunch){
            tresources.get(0).Prevent_completion_on_launch__c = true;
        }
        update tresources.get(0);

        for(Integer i = 0;i < resourceLearnings.size();i++){
            TestLearningData.publishLearning(resourceLearnings.get(i).Id,'resource',tresources.get(i).Id,false);
        }

        //Create training plans
        List<Training_Plan__c> tplans = TestTrainingPlanData.createTrainingPlans(new List<TestParams.TrainingPlanParam>{new TestParams.TrainingPlanParam()});
        //Create training plan sections
        List<Training_Plan_Section__c> tplanSections1 = TestTrainingPlanData.createTrainingPlanSections(tplans.get(0).Id,1);
        //Create training plan section items for quizzes
        List<Training_Plan_Section_Item__c> tplan1SectionItems1 = TestTrainingPlanData.createTrainingPlanSectionItems(tplanSections1.get(0).Id,resourceLearnings);

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

        List<Learning_Assignment__c> assignments = [select id from Learning_Assignment__c where Training_Plan__c = :tplanId];
        System.assertEquals(1,assignments.size());
        return assignments.get(0).Id;

    }

}
