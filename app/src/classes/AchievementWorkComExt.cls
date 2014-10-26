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
public with sharing class AchievementWorkComExt{

    private Id achievementId{get;set;}
    public List<WorkBadgeDefinition> badges{get;set;}
    public String selectedBadge{get;set;}
    public Achievement__c achievement{get;set;}

    public AchievementWorkComExt(ApexPages.StandardController cont){
        this.achievementId  = cont.getRecord().Id;
        init();
    }

    private void init(){

        this.selectedBadge = null;

        this.achievement = [select id
                                    ,name
                                    ,Work_Badge_Id__c
                                    ,Work_Badge_Giver__c
                                    ,Work_Badge_Message__c
                                    from Achievement__c
                                    where id = :achievementId];

        selectedBadge = this.achievement.Work_Badge_Id__c;

        badges = [select Id
                        ,ImageUrl
                        ,IsActive
                        ,IsCompanyWide
                        ,Name
                        FROM WorkBadgeDefinition
                        where IsActive = true
                        order by CreatedDate desc
                        limit 2000];
    }

    public PageReference saveBadgeInfo(){

        try{

            if(String.isBlank(selectedBadge)){
                LMSUtils.addErrorMessage('You must select a Badge from the list below.');
                return null;
            }

            WorkBadgeDefinition b = [select id
                                ,ImageUrl
                                from WorkBadgeDefinition
                                where Id = :selectedBadge
                                limit 1];

            this.achievement.Work_Badge_Id__c  = selectedBadge;
            this.achievement.Work_Badge_Image_URL__c = b.ImageUrl;
            update this.achievement;
            PageReference ref = new PageReference('/'+achievementId);
            ref.setRedirect(true);
            return ref;
        }catch(Exception e){
            LMSUtils.logException(e,'AchievementWorkComExt');
            LMSUtils.addGenericUnknownErrorMessage('AchievementWorkComExt - addBadge (1)');
            return null;
        }
    }

}
