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
public with sharing class AchievementAssignmentWrapper{

    public transient Achievement_Assignment__c assignment{get;set;}
    public transient String overrideURL{get;set;}
    public transient String status{get;set;}

    public AchievementAssignmentWrapper(Achievement_Assignment__c a){
        this.assignment = a;
        if(a != null){

            if(a.Status__c == LMSConstants.AA_ELIGIBLE_STATUS){
                this.status = LMSConstants.AA_ELIGIBLE_STATUS;
            }else if(a.Status__c == LMSConstants.AA_ACQUIRED_STATUS){
                this.status = LMSConstants.AA_ACQUIRED_STATUS;
            }else{
                if(UserInfo.getUserId() == a.User__c){
                    this.status = LMSConstants.AA_OVERRIDE_STATUS;
                }else{
                    this.status = LMSConstants.AA_ELIGIBLE_STATUS;
                }
            }

            if(a.Achievement__r.Override_URL__c != null){
                PageReference ref = new PageReference(a.Achievement__r.Override_URL__c);
                ref.getParameters().put('aaid',a.Id);
                ref.getParameters().put('uid',a.User__c);
                overrideURL = ref.getUrl();
            }
        }
    }

}
