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
public with sharing class AchievementAssignmentsHelper{

    //Create a work.com thanks record for achievements with work.com badges
    public void processAfterUpdates(Map<Id,Achievement_Assignment__c> oldAssignmentsMap,Map<Id,Achievement_Assignment__c> newAssignmentsMap){

        List<Achievement_Assignment__c> completedWorkAAs = new List<Achievement_Assignment__c>();
        Map<Id,Achievement__c> completedAchievements= new Map<Id,Achievement__c>();
        for(Achievement_Assignment__c aa : newAssignmentsMap.values()){
            Achievement_Assignment__c oldAA = oldAssignmentsMap.get(aa.Id);
            if(oldAA.Status__c != aa.Status__c && aa.Status__c == LMSConstants.AA_ACQUIRED_STATUS){
                if(aa.Achievement__c != null){
                    completedAchievements.put(aa.Achievement__c,null);
                }
                completedWorkAAs.add(aa);

            }
        }

        //Fetch achievement information
        for(Achievement__c ac : [select id
                                        ,Name
                                        ,Work_Badge_Id__c
                                        ,Work_Badge_Image_URL__c
                                        ,Work_Badge_Message__c
                                        ,Work_Badge_Giver__c
                                        from Achievement__c
                                        where id in :completedAchievements.keySet()]){
            completedAchievements.put(ac.Id,ac);
        }

        AchievementAssignmentsHelper.WithoutSharingOps wosHelper = new AchievementAssignmentsHelper.WithoutSharingOps();
        wosHelper.createWorkObjects(completedWorkAAs,completedAchievements);

    }

	public without sharing class WithoutSharingOps{

        // Work.com objects are not managed by our package
        // We want to create records for these objects in a without sharing context to bypass any sharing restrictions
        public void createWorkObjects(List<Achievement_Assignment__c> completedWorkAAs,Map<Id,Achievement__c> completedAchievements){

            List<WorkThanks> workThanksInsert = new List<WorkThanks>();
            List<WorkBadge> workBadgeInsert = new List<WorkBadge>();
            List<FeedItem> feedItemInsert = new List<FeedItem>();
            List<Map<String,String>> workBadges = new List<Map<String,String>>();

            for(Achievement_Assignment__c aa : completedWorkAAs){
                Achievement__c ac = completedAchievements.get(aa.Achievement__c);
                if(ac != null){

                    if(ac.Work_Badge_Id__c != null && ac.Work_Badge_Giver__c != null){
                        //Init values map
                        Map<String,String> workBadge = new Map<String,String>();

                        String msg = ac.Work_Badge_Message__c != null ? ac.Work_Badge_Message__c : System.Label.ALMS_Default_Achievement_Message;
                        workBadge.put('message',msg);
                        workBadge.put('giverid',ac.Work_Badge_Giver__c);
                        workBadge.put('recipientid',aa.User__c);
                        workBadge.put('sourceid',null);
                        workBadge.put('definitionid',ac.Work_Badge_Id__c);
                        workBadge.put('feedtype','RypplePost');
                        workBadges.add(workBadge);

                        //Create work thanks records
                        WorkThanks wt = new WorkThanks();
                        wt.GiverId = workBadge.get('giverid');
                        wt.Message = workBadge.get('message');
                        workThanksInsert.add(wt);
                    }

                }
            }

            if(workThanksInsert.size() > 0){

                //Do partial insert of work thanks records
                Database.SaveResult[] wThanksResults = Database.insert(workThanksInsert,false);

                for(Integer i = 0; i < wThanksResults.size(); i++) {
                    Database.SaveResult sr = wThanksResults[i];

                    if(sr.isSuccess()){
                        workBadges[i].put('sourceid',sr.getId());

                        //Create work badge records
                        WorkBadge wb = new WorkBadge();
                        wb.RecipientId = workBadges[i].get('recipientid');
                        wb.SourceId = workBadges[i].get('sourceid');
                        wb.DefinitionId = workBadges[i].get('definitionid');
                        workBadgeInsert.add(wb);

                        //Create feed item records
                        FeedItem fi = new FeedItem();
                        fi.Body = workBadges[i].get('message');
                        fi.RelatedRecordId = workBadges[i].get('sourceid');
                        fi.ParentId = workBadges[i].get('recipientid');
                        fi.Type = 'RypplePost';
                        feedItemInsert.add(fi);

                    }else{
                        workThanksInsert[i].addError(System.Label.ALMS_Default_Error_Inserting_Thanks +' : '+sr.getErrors().get(0).getMessage());
                    }
                }

                if(workBadgeInsert.size()>0){

                    Database.SaveResult[] wBadgeResults = Database.insert(workBadgeInsert,false);
                    Database.SaveResult[] feedItemResults = Database.insert(feedItemInsert,false);

                    for(Integer i = 0; i < wBadgeResults.size(); i++) {
                        Database.SaveResult sr = wBadgeResults[i];
                        if(!sr.isSuccess()){
                            workBadgeInsert[i].addError(System.Label.ALMS_Default_Error_Inserting_Badge +' : '+sr.getErrors().get(0).getMessage());
                        }
                    }

                    for(Integer i = 0; i < feedItemResults.size(); i++) {
                        Database.SaveResult sr = feedItemResults[i];
                        if(!sr.isSuccess()){
                            feedItemInsert[i].addError(System.Label.ALMS_Default_Error_Inserting_Feed +': '+sr.getErrors().get(0).getMessage());
                        }
                    }

                }

            }

        }

    }

}
