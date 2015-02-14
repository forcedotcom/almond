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
public with sharing class MyProfileController extends LMSBaseController{

    public User oUser{get;set;}
    public transient List<AchievementCategoryWrapper> lcategories{get;set;}
    public User oManager{get;set;}
    public String achievementType{get;private set;}
    private String profileUserId{get;set;}
    public Integer totalAchievements{get;private set;}

    public List<AchievementTypeWrapper> getAchievementTypes(){
        List<AchievementTypeWrapper> results = new List<AchievementTypeWrapper>();
        Schema.DescribeFieldResult fieldResult = Achievement__c.Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple){
            AchievementTypeWrapper act = new AchievementTypeWrapper();
            act.name = f.getValue();
            act.label = f.getLabel();
            results.add(act);
        }
        return results;
    }

    public MyProfileController(){
        totalAchievements = 0;
        profileUserId = ApexPages.currentPage().getParameters().get('id');
        String chatterPageUserId = ApexPages.currentPage().getParameters().get('sfdc.userId');

        achievementType = 'Achievements';

        String paramAchievementType = ApexPages.currentPage().getParameters().get('aType');

        if(!String.isBlank(paramAchievementType)){
            achievementType = paramAchievementType;
        }

        if(String.isBlank(profileUserId)){
            profileUserId = chatterPageUserId;
        }

        if(String.isBlank(profileUserId)){
            profileUserId = UserInfo.getUserId();
        }

        //No need to enforce CRUD/FLS on User object + standard fields
        oUser = [select Id
                        ,Name
                        ,Title
                        ,ManagerId
                        ,Email
                        ,Department
                        ,AboutMe
                        ,FullPhotoUrl
                        from User
                        where Id =:profileUserId];

        if(oUser.ManagerId !=null){
            oManager = [select Id
                                ,Name
                                ,SmallPhotoUrl
                                from User
                                where Id = :oUser.ManagerId];
        }

        List<AchievementAssignmentWrapper> lachievementassignment = new List<AchievementAssignmentWrapper>();
        lcategories = new List<AchievementCategoryWrapper>();

            //BEGIN Access Check
            Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
            relatedFieldsObjects.put(Achievement_Assignment__c.sObjectType,new List<String>{
                'Id'
                ,'Name'
                ,'Status__c'
                ,'Achievement__c'
                ,'Training_Plan_Achievement__c'
                ,'User__c'
            });
            relatedFieldsObjects.put(Achievement__c.sObjectType,new List<String>{
                'Id'
                ,'Name'
                ,'Acquired_Image__c'
                ,'Eligible_Image__c'
                ,'Work_Badge_Id__c'
                ,'Work_Badge_Image_URL__c'
                ,'Override_URL__c'
                ,'Override_Completed_Status__c'
            });
            relatedFieldsObjects.put(Training_Plan_Achievement__c.sObjectType,new List<String>{
                'Type__c'
                ,'Training_Plan__c'
                ,'Training_Plan_Section__c'
            });
            LMS_ESAPI.isAuthorizedToView(relatedFieldsObjects);
        //END Access Check

        String achievementCategory = '';

        List<String> listSOQLFields = new List<String>{
            'Id'
            ,'Name'
            ,'Status__c'
            ,'Achievement__c'
            ,'Achievement__r.Name'
            ,'Achievement__r.Acquired_Image__c'
            ,'Achievement__r.Eligible_Image__c'
            ,'Achievement__r.Work_Badge_Id__c'
            ,'Achievement__r.Work_Badge_Image_URL__c'
            ,'Achievement__r.Override_URL__c'
            ,'Achievement__r.Override_Completed_Status__c'
            ,'Achievement__r.Expiration_Date__c'
            ,'Achievement__r.Achievement_Category__r.Name'
            ,'Achievement__r.Type__c'
            ,'User__c'
        };

        String soqlQuery = 'select '+String.join(listSOQLFields,',')+' from Achievement_Assignment__c';
        soqlQuery += ' where User__c = :profileUserId and Achievement__r.Type__c = :achievementType and Achievement__r.Hidden__c = false';

        if(LMSUtils.isPortalUser()){
            soqlQuery += ' and Achievement__r.Is_Internal__c = false';
        }

        soqlQuery += ' order by Achievement__r.Achievement_Category__r.Name desc, Status__c desc';

        List<AchievementAssignmentWrapper> achievementRecs = new List<AchievementAssignmentWrapper>();
        for (Achievement_Assignment__c a : (List<Achievement_Assignment__c>)Database.query(soqlQuery)){


            String currentCategoryName = a.Achievement__r.Achievement_Category__r.Name;
            if(achievementCategory == ''){
                achievementCategory = currentCategoryName;
            }

            if(achievementCategory != currentCategoryName){
                AchievementCategoryWrapper acw = new AchievementCategoryWrapper();
                acw.Name = achievementCategory;
                acw.achievements = achievementRecs;
                lcategories.add(acw);

                //Reset comparison params
                achievementRecs = new List<AchievementAssignmentWrapper>();
                achievementCategory = currentCategoryName;
            }

            if(a.Status__c == LMSConstants.AA_ACQUIRED_STATUS){
                totalAchievements++;
            }
            achievementRecs.add(new AchievementAssignmentWrapper(a));
        }

        if(achievementRecs.size()>0){
            AchievementCategoryWrapper acw = new AchievementCategoryWrapper();
            acw.Name = achievementCategory;
            acw.achievements = achievementRecs;
            lcategories.add(acw);
    	}
    }

    public PageReference changeAchievementType(){
        String paramAchievementType = ApexPages.currentPage().getParameters().get('type');
        String isSubTab = ApexPages.currentPage().getParameters().get('subtab');

        PageReference ref = Page.MyProfile;

        if(!String.isBlank(isSubTab)){
        	ref = Page.AchievementsSubTab;
        }

        ref.getParameters().put('aType',paramAchievementType);
        ref.getParameters().put('id',profileUserId);
        ref.setRedirect(true);
        return ref;
    }

    public class AchievementTypeWrapper{
        public String name{get;set;}
        public String label{get;set;}
    }

}
