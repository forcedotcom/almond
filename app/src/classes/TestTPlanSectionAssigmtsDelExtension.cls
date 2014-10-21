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
private class TestTPlanSectionAssigmtsDelExtension{

	static testmethod void testDeletingAssignments(){

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

    	System.runAs(adminUsers.get(0)){
    		LMSService.upsertAssignments(selectedUserIds,tplan.Id);
        }

        //Select one of the training plan secion items
        List<Training_Plan_Section__c> tplanSections = [select id
                                                                from Training_Plan_Section__c
                                                                where Training_Plan__c = :tplan.Id limit 1];

        System.assert(tplanSections.size() > 0);

        Training_Plan_Section__c tplanSection = tplanSections.get(0);
        System.assert(getAssignmentsForSectionCount(tplanSection.Id) > 0);

		//Test Insert
        PageReference testPageRef = Page.TrainingPlanSectionAssignmentsDelete;
        Test.setCurrentPageReference(testPageRef);
		Test.startTest();


            System.runAs(adminUsers.get(0)){

                TrainingPlanSectionAssigmtsDelExtension cont = new TrainingPlanSectionAssigmtsDelExtension(new ApexPages.StandardController(tplanSection));
                cont.deleteAllSectionAssignments();
			}


		Test.stopTest();
        System.assert(getAssignmentsForSectionCount(tplanSection.Id) == 0);

	}

    private static Integer getAssignmentsForSectionCount(String sectionId){
        return  [select count() from Training_Plan_Section_Assignment__c where Training_Plan_Section__c = :sectionId];
    }
}
