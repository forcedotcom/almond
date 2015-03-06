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
public with sharing class TrainingPlanWithAchievement {
    public Id planId {get;private set;}
    public transient String planName {get;private set;}
    public transient String planDescription {get; private set;}
    public transient String planDetailURL {get; private set;}
    public transient String planAccess{get;private set;}
    public transient String planEndDate{get;private set;}
    public transient String planCompletedDate{get;set;}
    public transient Achievement__c mainAchievement {get; private set;}
    public transient Boolean hasAssignment{get;set;}
    public transient String assignmentStatus{get;set;}
    public transient Boolean selfRegistrationEnabled{get;set;}
    public transient Date newUntil{get;set;}

    public TrainingPlanWithAchievement(Training_Plan__c tplan, Achievement__c tachievement,String detailURL, Boolean hasAssignment){
        planName = tplan.Name;
        planId = tplan.Id;
        planAccess = tplan.Self_Registration_Access__c;
        planDescription = tplan.Description__c;
        newUntil = tplan.New_Until__c;
        selfRegistrationEnabled = tplan.Enable_Self_Registration__c;
        if(detailURL != null){
            planDetailURL = detailURL+'?id='+tplan.Id;
        }
        mainAchievement = tachievement;
        assignmentStatus = null;
        this.hasAssignment = hasAssignment;
        if(tplan.End_Date__c != null){
            planEndDate = (tplan.End_Date__c).format();
        }
        planCompletedDate = null;
    }
}
