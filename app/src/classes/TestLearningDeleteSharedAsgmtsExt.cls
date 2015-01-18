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
public class TestLearningDeleteSharedAsgmtsExt {

    static testMethod void testSharedAssignmentsCleanup(){

        //create learning
		//Create admin users
		List<User> adminUsers = TestUtilClass.createUsers(1,'System Administrator');
		List<User> lmsUsers = TestUtilClass.createUsers(5,'Standard User');

		System.runAs(adminUsers.get(0)){
			//Assign corresponding perm sets
			TestUtilClass.addPermissionSet(adminUsers,'LMS_Admin');
			TestUtilClass.addPermissionSet(lmsUsers,'LMS_User');
		}

		TestTrainingPlanData.createSampleData();

        List<Learning__c> taskLearnings = [select id,Sync_progress__c from Learning__c where RecordType.DeveloperName = 'Task'];
        System.assert(taskLearnings.size()>0);
        Learning__c sampleSharedTask = taskLearnings.get(0);
        sampleSharedTask.Sync_progress__c = true;
        update sampleSharedTask;


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

        List<Learning_Assignment__c> las = [select id,Shared_Learning_Assignment__c,User__c from Learning_Assignment__c];

        List<Learning_Assignment__c> taskLearningAssignments = [select id,Shared_Learning_Assignment__c
            from Learning_Assignment__c
            where Learning__c = :sampleSharedTask.Id
            and Shared_Learning_Assignment__c != null];

        System.assertEquals(5,taskLearningAssignments.size());

        //Grab one sample learning assignment and delete it
        Learning_Assignment__c assgmtToBeDeleted = taskLearningAssignments.get(0);
        delete assgmtToBeDeleted;

        System.assertEquals(5,getSharedAssignmentsCount(sampleSharedTask.Id));

		Test.startTest();

			System.runAs(adminUsers.get(0)){

                LearningDeleteSharedAssignmentsExt cont = new LearningDeleteSharedAssignmentsExt(new ApexPages.StandardController(sampleSharedTask));
                cont.deleteUnusuedSharedAssignments();
			}

		Test.stopTest();

        System.assertEquals(4,getSharedAssignmentsCount(sampleSharedTask.Id));


    }

    private static Integer getSharedAssignmentsCount(String learningId){
        return [select count() from Shared_Learning_Assignment__c where Learning__c = :learningId];
    }

}
