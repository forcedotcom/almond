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
public with sharing class TrainingPlanSectionItem{

    public Id currentSectionItemId{get;set;}
    public transient Training_Plan_Section_Item__c trainingPlanSectionItem{get;set;}
    public Learning__c learning{get;set;}
    public transient List<Learning_Assignment__c> assignments{get;set;}
    public transient List<Shared_Learning_Assignment__c> sharedAssignments{get;set;}
    public Id previousSectionItemId{get;set;}
    public Boolean previousSectionItemOptional{get;set;}
    public Id previousOptionalSectionItemId{get;set;}
    //Versioning details
    public String latestLearningVersionId{get;set;}
    public Learning_Assignment__c latestAssignment{get;set;}
    public Learning_Assignment__c oldestAssignment{get;set;}
    public Boolean outdatedAssignment{get;set;}
    public String latestVersionDecision{get;set;}
    public String launchBehavior{get;set;}

    public TrainingPlanSectionItem(){
        currentSectionItemId = null;
        trainingPlanSectionItem = null;
        learning = null;
        assignments = null;
        sharedAssignments = null;
        latestLearningVersionId = null;
        latestAssignment = null;
        oldestAssignment = null;
        outdatedAssignment = false;
        latestVersionDecision = null;
        launchBehavior = null;
        previousSectionItemId = null;
        previousOptionalSectionItemId = null;
        previousSectionItemOptional = false;
    }

    public void updateToLatestVersion(){
        if(this.latestAssignment != null && this.learning.Current_Published_Version__c != null){
            this.latestAssignment.Last_Published_Learning_Version__c = this.learning.Current_Published_Version__c;
            this.latestAssignment.Last_Published_Learning_Version_Decision__c = 'New version taken';
            this.latestAssignment.Learning_Version__c = this.learning.Current_Published_Version__c;

            //By-passing CRUD/FLS here as users don't have update permissions for learning assignments
            update this.latestAssignment;
        }

    }

    public void keepOldVersion(){
        if(this.latestAssignment != null && this.learning.Current_Published_Version__c != null){
            this.latestAssignment.Last_Published_Learning_Version__c = this.learning.Current_Published_Version__c;
            this.latestAssignment.Last_Published_Learning_Version_Decision__c = 'Keep using old version';

            //By-passing CRUD/FLS here as users don't have update permissions for learning assignments
            update this.latestAssignment;
        }
    }

}
