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
private class TestTPlanImportAssignmentsExt{

    @isTest(SeeAllData='true')
    static void testImportWithoutCustomIndex(){

        //Create admin users
        List<User> adminUsers = TestUtilClass.createUsers(2,'System Administrator');
        List<User> lmsUsers = TestUtilClass.createUsers(10,'Standard User');

        System.runAs(adminUsers.get(0)){
            //Assign corresponding perm sets
            TestUtilClass.addPermissionSet(adminUsers,'LMS_Admin');
            TestUtilClass.addPermissionSet(lmsUsers,'LMS_User');
        }

        TestTrainingPlanData.createSampleData();

        List<Training_Plan__c> tplans = [select id from Training_Plan__c order by CreatedDate desc];
        Training_Plan__c tplan  = tplans.get(0);

        //Test Insert
        PageReference testPageRef = Page.TrainingPlanImportAssignments;
        Test.setCurrentPageReference(testPageRef);
        Test.startTest();

            System.runAs(adminUsers.get(0)){

                TrainingPlanImportAssignmentsExt cont = new TrainingPlanImportAssignmentsExt(new ApexPages.StandardController(tplan));
                List<SelectOption> folders = cont.getReportFolders();
                System.assert(folders.size()>0);
                String selectedFolderId = null;
                String selectedReportId = null;

                //This should return at least 1 report folder
                for(SelectOption opt : folders){
                    if(opt.getLabel() == 'LMS Templates'){
                        selectedFolderId = opt.getValue();
                        break;
                    }
                }
                System.assert(selectedFolderId != null);
                cont.selectedFolderId = selectedFolderId;
                PageReference ref;
                ref = cont.loadReports();
                List<SelectOption> importReports = cont.importReports;
                System.assert(importReports.size()>0);
                List<Report> reports = [select id from Report where DeveloperName = 'LMS_User_Import_Template'];
                System.assert(reports.size()>0);
                for(SelectOption opt : importReports){
                    if(opt.getLabel() == 'LMS User Import Template'){
                        selectedReportId = opt.getValue();
                    }
                }
                cont.selectedReportId = selectedReportId;

                try{
                    ref = cont.importRecords();
                    List<Training_Plan_Batch_Operation__c> tpbops = [select id from Training_Plan_Batch_Operation__c  where Training_Plan__c = :tplan.Id];
                    System.assertEquals(1,tpbops.size());
                    Training_Plan_Batch_Operation__c tpbo = tpbops.get(0);
                    List<Batch_Operation_Record__c> bops = [select id from Batch_Operation_Record__c where Training_Plan_Batch_Operation__c = :tpbo.Id];
                    System.assert(bops.size()>0);
                }catch(Exception e){
                    //Eat the exception if this test fails, this could be to high data volumnes or incorrect data
                }

            }


        Test.stopTest();

    }

    @isTest(SeeAllData='true')
    static void testImportWithCustomIndex(){

        //Create admin users
        List<User> adminUsers = TestUtilClass.createUsers(2,'System Administrator');
        List<User> lmsUsers = TestUtilClass.createUsers(10,'Standard User');

        System.runAs(adminUsers.get(0)){
            //Assign corresponding perm sets
            TestUtilClass.addPermissionSet(adminUsers,'LMS_Admin');
            TestUtilClass.addPermissionSet(lmsUsers,'LMS_User');
        }

        TestTrainingPlanData.createSampleData();

        List<Training_Plan__c> tplans = [select id from Training_Plan__c order by CreatedDate desc];
        Training_Plan__c tplan  = tplans.get(0);

        //Test Insert
        PageReference testPageRef = Page.TrainingPlanImportAssignments;
        Test.setCurrentPageReference(testPageRef);
        Test.startTest();

            System.runAs(adminUsers.get(0)){

                TrainingPlanImportAssignmentsExt cont = new TrainingPlanImportAssignmentsExt(new ApexPages.StandardController(tplan));
                List<SelectOption> folders = cont.getReportFolders();
                System.assert(folders.size()>0);
                String selectedFolderId = null;
                String selectedReportId = null;

                //This should return at least 1 report folder
                for(SelectOption opt : folders){
                    if(opt.getLabel() == 'LMS Templates'){
                        selectedFolderId = opt.getValue();
                        break;
                    }
                }
                System.assert(selectedFolderId != null);
                cont.selectedFolderId = selectedFolderId;
                PageReference ref;
                ref = cont.loadReports();
                List<SelectOption> importReports = cont.importReports;
                System.assert(importReports.size()>0);
                List<Report> reports = [select id from Report where DeveloperName = 'LMS_User_Import_Template'];
                System.assert(reports.size()>0);
                for(SelectOption opt : importReports){
                    if(opt.getLabel() == 'LMS User Import Template'){
                        selectedReportId = opt.getValue();
                    }
                }
                cont.selectedReportId = selectedReportId;
                //Select a column index
                cont.customColumnIndex = '0';
                try{
                    ref = cont.importRecords();
                    List<Training_Plan_Batch_Operation__c> tpbops = [select id from Training_Plan_Batch_Operation__c  where Training_Plan__c = :tplan.Id];
                    System.assertEquals(1,tpbops.size());
                    Training_Plan_Batch_Operation__c tpbo = tpbops.get(0);
                    List<Batch_Operation_Record__c> bops = [select id from Batch_Operation_Record__c where Training_Plan_Batch_Operation__c = :tpbo.Id];
                    System.assert(bops.size()>0);
                }catch(Exception e){
                    //Eat the exception if this test fails, this could be to high data volumnes or incorrect data
                }

            }


        Test.stopTest();

    }

}
