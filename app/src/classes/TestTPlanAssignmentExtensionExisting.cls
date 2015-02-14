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
private class TestTPlanAssignmentExtensionExisting{

    static testmethod void testUpdate(){

        //Create admin users
        List<User> adminUsers = TestUtilClass.createUsers(2,'System Administrator');
        List<User> lmsUsers = TestUtilClass.createUsers(5,'Standard User');

        System.runAs(adminUsers.get(0)){
            //Assign corresponding perm sets
            TestUtilClass.addPermissionSet(adminUsers,'LMS_Admin');
            TestUtilClass.addPermissionSet(lmsUsers,'LMS_User');
        }

        TestTrainingPlanData.createSampleData();

        List<Training_Plan__c> tplans = [select id from Training_Plan__c];
        System.assertEquals(1,tplans.size());
        Training_Plan__c tplan  = tplans.get(0);
        Set<Id> selectedUserIds = new Set<Id>();
        for(User u : lmsUsers){
            selectedUserIds.add(u.Id);
        }

        //Test Insert
        PageReference testPageRef = Page.TrainingPlanAssignmentExisting;
        Test.setCurrentPageReference(testPageRef);
        Test.startTest();

            System.runAs(adminUsers.get(0)){

                LMSService.upsertAssignments(selectedUserIds,tplan.Id,null);

                TrainingPlanAssignmentExtensionExisting cont = new TrainingPlanAssignmentExtensionExisting(new ApexPages.StandardController(tplan));

                List<TrainingPlanAssignmentExtensionExisting.TPlanAssignmentWrapper> currentRows = cont.rows;
                System.assertEquals(5,currentRows.size());
                System.assertEquals(false,cont.getHasPrevious());
                System.assertEquals(false,cont.getHasNext());
                System.assertEquals(1,cont.getPageNumber());
                System.assertEquals(1,cont.getTotalPages());

                for(TrainingPlanAssignmentExtensionExisting.TPlanAssignmentWrapper asgmt : currentRows){
                    asgmt.isSelected = true;
                }

                PageReference ref = cont.updateAssignments();

                System.assertEquals(5,currentRows.size());
            }


        Test.stopTest();

    }

    static testmethod void testDelete(){

        //Create admin users
        List<User> adminUsers = TestUtilClass.createUsers(2,'System Administrator');
        List<User> lmsUsers = TestUtilClass.createUsers(5,'Standard User');

        System.runAs(adminUsers.get(0)){
            //Assign corresponding perm sets
            TestUtilClass.addPermissionSet(adminUsers,'LMS_Admin');
            TestUtilClass.addPermissionSet(lmsUsers,'LMS_User');
        }

        TestTrainingPlanData.createSampleData();

        List<Training_Plan__c> tplans = [select id from Training_Plan__c];
        System.assertEquals(1,tplans.size());
        Training_Plan__c tplan  = tplans.get(0);
        Set<Id> selectedUserIds = new Set<Id>();
        for(User u : lmsUsers){
            selectedUserIds.add(u.Id);
        }

        //Test Insert
        PageReference testPageRef = Page.TrainingPlanAssignmentExisting;
        Test.setCurrentPageReference(testPageRef);
        Test.startTest();

            System.runAs(adminUsers.get(0)){

                LMSService.upsertAssignments(selectedUserIds,tplan.Id,null);

                TrainingPlanAssignmentExtensionExisting cont = new TrainingPlanAssignmentExtensionExisting(new ApexPages.StandardController(tplan));
                List<TrainingPlanAssignmentExtensionExisting.TPlanAssignmentWrapper> currentRows = cont.rows;
                System.assertEquals(5,currentRows.size());
                for(TrainingPlanAssignmentExtensionExisting.TPlanAssignmentWrapper asgmt : currentRows){
                    asgmt.isSelected = true;
                }
                PageReference ref = cont.deleteAssignments();
                currentRows = cont.rows;
                System.assertEquals(0,currentRows.size());
            }


        Test.stopTest();

    }

    static testmethod void testPagination(){

        //Create admin users
        List<User> adminUsers = TestUtilClass.createUsers(2,'System Administrator');
        List<User> lmsUsers = TestUtilClass.createUsers(10,'Standard User');

        System.runAs(adminUsers.get(0)){
            //Assign corresponding perm sets
            TestUtilClass.addPermissionSet(adminUsers,'LMS_Admin');
            TestUtilClass.addPermissionSet(lmsUsers,'LMS_User');
        }

        TestTrainingPlanData.createSampleData();

        List<Training_Plan__c> tplans = [select id from Training_Plan__c];
        System.assertEquals(1,tplans.size());
        Training_Plan__c tplan  = tplans.get(0);
        Set<Id> selectedUserIds = new Set<Id>();
        for(User u : lmsUsers){
            selectedUserIds.add(u.Id);
        }

        //Test Insert
        PageReference testPageRef = Page.TrainingPlanAssignmentExisting;
        Test.setCurrentPageReference(testPageRef);
        Test.startTest();

            System.runAs(adminUsers.get(0)){

                LMSService.upsertAssignments(selectedUserIds,tplan.Id,null);

                TrainingPlanAssignmentExtensionExisting cont = new TrainingPlanAssignmentExtensionExisting(new ApexPages.StandardController(tplan));
                cont.setCon.setPageSize(5);
                cont.setRows();
                System.assertEquals(false,cont.getHasPrevious());
                System.assertEquals(true,cont.getHasNext());
                System.assertEquals(1,cont.getPageNumber());
                System.assertEquals(2,cont.getTotalPages());
                cont.doNext();
                System.assertEquals(true,cont.getHasPrevious());
                System.assertEquals(false,cont.getHasNext());
                System.assertEquals(2,cont.getPageNumber());
                System.assertEquals(2,cont.getTotalPages());
                cont.doPrevious();
                System.assertEquals(false,cont.getHasPrevious());
                System.assertEquals(true,cont.getHasNext());
                System.assertEquals(1,cont.getPageNumber());
                System.assertEquals(2,cont.getTotalPages());

            }


        Test.stopTest();

    }
}
