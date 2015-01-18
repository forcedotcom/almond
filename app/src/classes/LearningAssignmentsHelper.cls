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
public with sharing class LearningAssignmentsHelper{

    public static Boolean previewMode{get;set;}

    //Initialize static variables
    static{
        previewMode = false;
    }

    //Initialize learning assignments with shared learning progress
    public void processBeforeInserts(List<Learning_Assignment__c> newAssignments){

        LearningAssignmentsHelper.WithoutSharingOps wosHelper = new LearningAssignmentsHelper.WithoutSharingOps();
        Set<Id> referencedLearnings = new Set<Id>();
        Set<Id> referencedUsers = new Set<Id>();
        Map<Id,Learning__c> sharedLearnings = new Map<Id,Learning__c>();
        Map<Id,List<Learning_Assignment__c>> learningAssignmentsForLearning = new Map<Id,List<Learning_Assignment__c>>();
        Map<Id,Map<Id,Shared_Learning_Assignment__c>> learningsSharedAssignments = null;

        //Create plan assignments
        Map<String,Id> planAssignments = wosHelper.createPlanAssignments(Trigger.new);
        //Create section assignments
        Map<String,Id> sectionAssignments = wosHelper.createSectionAssignments(Trigger.new,planAssignments);

        //Get ids from new assignments
        for(Learning_Assignment__c la : newAssignments){
            if(la.Learning__c != null && !la.Is_Test_Assignment__c){

                //Set TPSA Id
                la.Training_Plan_Section_Assignment__c = sectionAssignments.get(la.User__c+'_'+la.Training_Plan_Section__c);

                referencedLearnings.add(la.Learning__c);
                referencedUsers.add(la.User__c);

                if(!learningAssignmentsForLearning.containsKey(la.Learning__c)){
                    learningAssignmentsForLearning.put(la.Learning__c,new List<Learning_Assignment__c>());
                }
                learningAssignmentsForLearning.get(la.Learning__c).add(la);
            }
        }

        //At this point, the learnings should've been already shared with the current user, so this should be fine running with sharing
        //Get ids for learnings that have shared progress
        if(referencedLearnings.size()>0){
            List<Learning__c> learnings = wosHelper.getLearningDataWOS(referencedLearnings);
            for(Learning__c l : learnings){
                sharedLearnings.put(l.Id,l);
            }
        }

        //We'll query for shared learning assignments records related to the shared learnings.
        learningsSharedAssignments = wosHelper.getSharedAssignmentsForLearningsWOS(sharedLearnings.keySet(),referencedUsers);

        //Create shared assignments for first time assigments
        List<Shared_Learning_Assignment__c> newSharedAssignments = new List<Shared_Learning_Assignment__c>();
        for(Id learningId : sharedLearnings.keySet()){
            if(!learningsSharedAssignments.containsKey(learningId)){
                Learning__c l = sharedLearnings.get(learningId);
                for(Learning_Assignment__c la : learningAssignmentsForLearning.get(learningId)){
                    Shared_Learning_Assignment__c sla = new Shared_Learning_Assignment__c();
                    sla.Learning__c = learningId;
                    sla.Progress_Percentage__c = 0;
                    sla.Progress__c = LMSConstants.ASSIGNMENT_STATUS_NOT_STARTED;
                    sla.Learning_Version__c = l.Current_Published_Version__c;
                    sla.OwnerId = la.OwnerId;
                    sla.User__c = la.User__c;

                    if(!learningsSharedAssignments.containsKey(l.Id)){
                        learningsSharedAssignments.put(l.Id,new Map<Id,Shared_Learning_Assignment__c>{la.User__c=>sla});
                    }else{
                        learningsSharedAssignments.get(l.Id).put(la.User__c,sla);
                    }

                    newSharedAssignments.add(sla);
                }
            }
        }

        //Insert new shared assignments
        if(newSharedAssignments.size()>0){
            wosHelper.insertSharedAssignmentsWOS(newSharedAssignments);
        }

        //Get shared assignments
        if(sharedLearnings.size()>0){
            for(Learning_Assignment__c  la : newAssignments){
                if(la.Learning__c != null){
                    Map<Id,Shared_Learning_Assignment__c> sharedAssignments = learningsSharedAssignments.get(la.Learning__c);
                    //Initialize new assignments with the shared learning assignments values if applicable
                    if(sharedAssignments != null && sharedAssignments.get(la.User__c) != null){
                        Shared_Learning_Assignment__c sharedAssignment = sharedAssignments.get(la.User__c);
                        la.Shared_Learning_Assignment__c = sharedAssignment.Id;
                        la.Progress__c = sharedAssignment.Progress__c;
                        la.Progress_Percentage__c = sharedAssignment.Progress_Percentage__c;
                        la.Evaluation_Result__c = sharedAssignment.Evaluation_Result__c;
                        la.Evaluation_Score__c = sharedAssignment.Evaluation_Score__c;
                        la.Evaluation_Times_Taken__c = sharedAssignment.Evaluation_Times_Taken__c;
                        la.Last_Published_Learning_Version__c = sharedAssignment.Last_Published_Learning_Version__c;
                        la.Last_Published_Learning_Version_Decision__c = sharedAssignment.Last_Published_Learning_Version_Decision__c;
                        la.Learning_Version__c = sharedAssignment.Learning_Version__c;
                    }
                }
            }
        }

    }

    //Update approval fields
    public void processBeforeUpdates(Map<Id,Learning_Assignment__c> oldAssignmentsMap,Map<Id,Learning_Assignment__c> newAssignmentsMap){

        //Iterate over assignments to get trainin plan section item keys
        Map<Id,Boolean> tPlanSectionItemMap = new Map<Id,Boolean>();

        //Only process assignments that have changd
        for(Learning_Assignment__c la : newAssignmentsMap.values()){

            Learning_Assignment__c oldLA = oldAssignmentsMap.get(la.Id);

            if(la.Approved__c != oldLA.Approved__c && la.Progress__c == LMSConstants.ASSIGNMENT_STATUS_IN_REVIEW){
                la.Approved_By__c = UserInfo.getUserId();
                la.Progress__c = LMSConstants.ASSIGNMENT_STATUS_COMPLETED;
                la.Progress_Percentage__c = 100;
            }

            if(la.Training_Plan_Section_Item__c != null){
                tPlanSectionItemMap.put(la.Training_Plan_Section_Item__c,false);
            }
        }


        //Fetch optional attribute from related training plan section items
        if(tPlanSectionItemMap.size()>0){
            LearningAssignmentsHelper.WithoutSharingOps wosHelper = new LearningAssignmentsHelper.WithoutSharingOps();
            List<Training_Plan_Section_Item__c> tplanSectionItems = wosHelper.getTPlanSectionItemsWOS(tPlanSectionItemMap.keySet());
            for(Training_Plan_Section_Item__c tpsi : tplanSectionItems){
                Boolean isOptional = false;
                if(tpsi.Training_Plan_Section__r != null && tpsi.Training_Plan_Section__r.Optional__c){
                    isOptional = true;
                }else{
                    isOptional = tpsi.Optional__c;
                }
                tPlanSectionItemMap.put(tpsi.id,isOptional);
            }
        }

        //Update the optional field value at the learning assignment level
        for(Learning_Assignment__c la : newAssignmentsMap.values()){
            if(tPlanSectionItemMap.containsKey(la.Training_Plan_Section_Item__c) && (la.Optional__c != tPlanSectionItemMap.get(la.Training_Plan_Section_Item__c))){
                la.Optional__c = tPlanSectionItemMap.get(la.Training_Plan_Section_Item__c);
            }
        }

    }

    public void processBeforeDeletes(List<Learning_Assignment__c> oldAssignments){

        Set<Id> deletedUnSharedAssignments = new Set<Id>();

        //Delete responses for assignments that don't have a shared assignment
        for(Learning_Assignment__c la : oldAssignments){
            if(la.Shared_Learning_Assignment__c == null){
                deletedUnSharedAssignments.add(la.Id);
            }
        }

        //Retrieve related responses
        if(deletedUnSharedAssignments.size()>0){
            LearningAssignmentsHelper.WithoutSharingOps wosHelper = new LearningAssignmentsHelper.WithoutSharingOps();
            wosHelper.deleteResponsesForAssignmentWOS(deletedUnSharedAssignments);
        }

    }

    //Update section assignments status if the learning assignment was initialized through a shared assignment
    public void processAfterInserts(List<Learning_Assignment__c> newAssignments){
        Set<Id> updatedAssignmentsIds = new Set<Id>();

        for(Learning_Assignment__c la : newAssignments){
            if(!la.Is_Test_Assignment__c && la.Training_Plan_Section__c != null){
                updatedAssignmentsIds.add(la.Id);
            }
        }

        if(updatedAssignmentsIds.size()>0){
            updateSectionAssignments(updatedAssignmentsIds,null,null);
        }
    }

    //Update related shared progress for assignments
    public void processAfterUpdates(Map<Id,Learning_Assignment__c> oldAssignmentsMap,Map<Id,Learning_Assignment__c> newAssignmentsMap){

        Map<Id,Learning_Assignment__c> sharedAssignments = new Map<Id,Learning_Assignment__c>();
        List<Shared_Learning_Assignment__c> sharedAssignmentsForUpdate = new List<Shared_Learning_Assignment__c>();
        Set<Id> updatedAssignmentIds = new Set<Id>();

        //Only process assignments that have changd
        for(Learning_Assignment__c la : newAssignmentsMap.values()){

            Learning_Assignment__c oldLA = oldAssignmentsMap.get(la.Id);

            if(((la.Progress__c != oldLA.Progress__c) || (la.Optional__c != oldLA.Optional__c)) && !la.Is_Test_Assignment__c){
                //Add assignment id to completed list
                updatedAssignmentIds.add(la.Id);
            }

            //Only process changes for shared assignments if the current context is not "future"
            if(!System.isFuture() && !System.isBatch()){
                if(la.Shared_Learning_Assignment__c != null){

                    //Make sure we always keep these conditions in sync with the conditions defined in the shared Learning assignment helper class
                    if(!sharedAssignments.containsKey(la.Shared_Learning_Assignment__c)){
                        if(la.Progress__c != oldLA.Progress__c
                           || la.Progress_Percentage__c != oldLA.Progress_Percentage__c
                           || la.Last_Published_Learning_Version__c != oldLA.Last_Published_Learning_Version__c
                           || la.Last_Published_Learning_Version_Decision__c != oldLA.Last_Published_Learning_Version_Decision__c
                           || la.Approved__c != oldLA.Approved__c
                           || la.Approved_By__c != oldLA.Approved_By__c){

                            sharedAssignments.put(la.Shared_Learning_Assignment__c,la);
                        }
                    }
                }
            }else{
                //TODO: Analyze use cases and impact of not updating shared assignments in this scenario
                //It's important to understand that enabling this could potentially introduce an update loop
                System.debug('*** Blocked updating shared assignment progress since we are already in future context');
            }
        }

        //Update related shared assignments
        for(Id saId : sharedAssignments.keySet()){
            Learning_Assignment__c la = sharedAssignments.get(saId);
            Shared_Learning_Assignment__c sla = new Shared_Learning_Assignment__c(Id=saId);
            sla.Progress__c = la.Progress__c;
            sla.Progress_Percentage__c = la.Progress_Percentage__c;
            sla.Last_Published_Learning_Version__c = la.Last_Published_Learning_Version__c;
            sla.Last_Published_Learning_Version_Decision__c = la.Last_Published_Learning_Version_Decision__c;
            sla.Evaluation_Result__c = la.Evaluation_Result__c;
            sla.Evaluation_Score__c = la.Evaluation_Score__c;
            sla.Evaluation_Times_Taken__c = la.Evaluation_Times_Taken__c;
            //Set the triggering learning assignment in this field to prevent updating it again
            sla.Learning_Assignment_Last_Update__c = la.Id;
            sla.Approved__c = la.Approved__c;
            sla.Approved_By__c = la.Approved_By__c;
            sharedAssignmentsForUpdate.add(sla);
        }

        if(sharedAssignmentsForUpdate.size()>0){
            LearningAssignmentsHelper.WithoutSharingOps wosHelper = new LearningAssignmentsHelper.WithoutSharingOps();
            wosHelper.updateSharedAssignmentsWOS(sharedAssignmentsForUpdate);
        }

        //Run additional processes for modified assignments
        if(updatedAssignmentIds.size()>0){
            if(!System.isFuture() && !System.isBatch() && !LMSSettings.getDisableFutureProgressCalculation()){
                updateSectionAssignmentsInFuture(updatedAssignmentIds,null,null);
            }else{
                //Process section and training plan updates in the current (future/batch) transaction
                updateSectionAssignments(updatedAssignmentIds,null,null);
            }
        }
    }

    public void processAfterUnDeletes(List<Learning_Assignment__c> unDeletedAssignments){
        if(!System.isFuture() && !System.IsBatch()){
            Set<Id> updatedAssignmentIds = new Set<Id>();
            for(Learning_Assignment__c la : unDeletedAssignments){
                if(!la.Is_Test_Assignment__c){
                    updatedAssignmentIds.add(la.Id);
                }
            }
            updateSectionAssignmentsInFuture(updatedAssignmentIds,null,null);
        }else{
            System.debug('*** Unable to run processUnDeletes since we are already in future context');
        }
    }

    public void processAfterDeletes(List<Learning_Assignment__c> deletedAssignments){
        Set<Id> relatedTPlanSections = new Set<Id>();
        Set<Id> relatedUsers = new Set<Id>();
        for(Learning_Assignment__c la : deletedAssignments){
            if(!la.Is_Test_Assignment__c){
                relatedTPlanSections.add(la.Training_Plan_Section__c);
                relatedUsers.add(la.User__c);
            }
        }
        if(!System.isFuture() && !System.IsBatch()){
            updateSectionAssignmentsInFuture(new Set<Id>(),relatedTPlanSections,relatedUsers);
        }else{
            updateSectionAssignments(new Set<Id>(),relatedTPlanSections,relatedUsers);
        }
    }

    @future
    public static void updateSectionAssignmentsInFuture(Set<Id> updatedAssignmentIds, Set<Id> delTPSections, Set<Id> delUsers){
        updateSectionAssignments(updatedAssignmentIds,delTPSections,delUsers);
    }

    public static void updateSectionAssignments(Set<Id> updatedAssignmentIds, Set<Id> delTPSections, Set<Id> delUsers){
        LearningAssignmentsHelper.WithoutSharingOps wosHelper = new LearningAssignmentsHelper.WithoutSharingOps();
        wosHelper.updateSectionAssignmentsWOS(updatedAssignmentIds,delTPSections,delUsers);
    }

    public static void updateTrainingPlanAssignments(Set<Id> relatedTPlans,Set<Id> relatedUsers){
        LearningAssignmentsHelper.WithoutSharingOps wosHelper = new LearningAssignmentsHelper.WithoutSharingOps();
        wosHelper.updateTrainingPlanAssignmentsWOS(relatedTPlans,relatedUsers);
    }

    private without sharing class WithoutSharingOps{

        // We need to make sure progress recalculation has access to all assignment records even if some are not shared
        // with the running user
        public void updateTrainingPlanAssignmentsWOS(Set<Id> relatedTPlans,Set<Id> relatedUsers){

            Map<String,Map<String,Integer>> sectionAggregatedResults = new Map<String,Map<String,Integer>>();
            List<Training_Plan_Assignment__c> planAssignmentsToUpdate = new List<Training_Plan_Assignment__c>();

            if(relatedTPlans != null && relatedUsers != null && relatedTPlans.size()>0 && relatedUsers.size() >0){

                //Get aggregate information for associated section assignments
                AggregateResult[] tPlanGroupedResults = [select Training_Plan_Section__r.Training_Plan__c tplan
                                                         ,User__c
                                                         ,Status__c
                                                         ,count(Id) cnt
                                                         from Training_Plan_Section_Assignment__c
                                                         where User__c in :relatedUsers
                                                         and Training_Plan_Section__r.Training_Plan__c in :relatedTPlans
                                                         and Training_Plan_Section__r.Optional__c = false
                                                         group by Training_Plan_Section__r.Training_Plan__c,User__c,Status__c];

                //Update progress on related section assignments
                String ns = LMSUtils.getPackageNamespace();
                for(AggregateResult ar : tPlanGroupedResults){
                    String tPlanId = (String)ar.get('tplan');
                    String userId = (String)ar.get(ns+'User__c');
                    String statusType = (String)ar.get(ns+'Status__c');
                    Integer count = (Integer)ar.get('cnt');

                    String arKey = userId+'_'+tPlanId;

                    if(!sectionAggregatedResults.containsKey(arKey)){
                        Map<String,Integer> initMap = new Map<String,Integer>{
                            LMSConstants.ASSIGNMENT_STATUS_NOT_STARTED=>0,
                                LMSConstants.ASSIGNMENT_STATUS_IN_PROGRESS=>0,
                                LMSConstants.ASSIGNMENT_STATUS_COMPLETED=>0
                                };
                                    sectionAggregatedResults.put(arKey,initMap);
                    }
                    sectionAggregatedResults.get(arKey).put(statusType,count);
                }

                //Fetch training plan assignments
                for(Training_Plan_Assignment__c pa : [select id
                                                      ,User__c
                                                      ,Training_Plan__c
                                                      ,Status__c
                                                      from Training_Plan_Assignment__c
                                                      where User__c in :relatedUsers
                                                      and Training_Plan__c in :relatedTPlans]){


                    String asKey = pa.User__c+'_'+pa.Training_Plan__c;
                    if(sectionAggregatedResults.containsKey(asKey)){
                        Integer lNotStarted = sectionAggregatedResults.get(asKey).get(LMSConstants.ASSIGNMENT_STATUS_NOT_STARTED);
                        Integer lInProgress = sectionAggregatedResults.get(asKey).get(LMSConstants.ASSIGNMENT_STATUS_IN_PROGRESS);
                        Integer lCompleted = sectionAggregatedResults.get(asKey).get(LMSConstants.ASSIGNMENT_STATUS_COMPLETED);
                        String currentStatus = LMSConstants.ASSIGNMENT_STATUS_NOT_STARTED;

                        if(lInProgress >= 1 || (lCompleted > 0 && lNotStarted >= 1)){
                            currentStatus = LMSConstants.ASSIGNMENT_STATUS_IN_PROGRESS;
                        }else if(lInProgress == 0 && lNotStarted == 0 && lCompleted > 0){
                            currentStatus = LMSConstants.ASSIGNMENT_STATUS_COMPLETED;
                        }

                        pa.Status__c = currentStatus;
                        planAssignmentsToUpdate.add(pa);
                    }

                }

                //Update training plan assignments
                if(planAssignmentsToUpdate.size()>0){
                    update planAssignmentsToUpdate;
                }

            }
        }

        //We need to run this without sharing in case the running user doesn't have access to the parent training plan
        public List<Training_Plan_Section_Item__c> getTPlanSectionItemsWOS(Set<Id> tplanSectionItemIds){
            return [select id
                            ,Optional__c
                            ,Training_Plan_Section__r.Optional__c
                            from Training_Plan_Section_Item__c
                            where id in :tplanSectionItemIds];
        }

        //We need to run this without sharing in case the running use doesn't have View All access on the response object
        public void deleteResponsesForAssignmentWOS(Set<Id> assignmentIds){
            List<Response__c> relatedResponsesToDelete = [select id from Response__c where Learning_Assignment__c in :assignmentIds];
            if(relatedResponsesToDelete.size()>0){
                delete relatedResponsesToDelete;
            }
        }

        //We need to run this without sharing to make sure the running user has access to shared learning assignments that may have not been shared with him/her
        //This could happen when an approver, or delegated admin with limited access is creating assignments
        //Return a map of shared assignments for the specified learnings + user ids
        public Map<Id,Map<Id,Shared_Learning_Assignment__c>> getSharedAssignmentsForLearningsWOS(Set<Id> learningIds,Set<Id> userIds){

            Map<Id,Map<Id,Shared_Learning_Assignment__c>> results = new Map<Id,Map<Id,Shared_Learning_Assignment__c>>();

            //Create local scope vars for Dynamic SOQL binding
            Set<Id> lIds = learningIds;
            Set<Id> uIds = userIds;

            List<String> listSOQLFields = new List<String>{
                'Id'
                ,'Name'
                ,'Contact__c'
                ,'OwnerId'
                ,'User__c'
                ,'Learning__c'
                ,'Learning_Version__c'
                ,'Learning_Version__r.Version__c'
                ,'Learning_Version__r.Learning_Content_ID__c'
                ,'Progress__c'
                ,'Progress_Percentage__c'
                ,'Evaluation_Result__c'
                ,'Evaluation_Score__c'
                ,'Evaluation_Times_Taken__c'
                ,'Approved__c'
                ,'Approved_By__c'
                ,'Last_Published_Learning_Version__c'
                ,'Last_Published_Learning_Version_Decision__c'
            };

            String soqlQuery = 'select '+String.join(listSOQLFields,',')+' from Shared_Learning_Assignment__c where User__c in :uIds and Learning__c in :lIds';
            soqlQuery += ' order by CreatedDate desc';

            List<Shared_Learning_Assignment__c> sharedAssignments = (List<Shared_Learning_Assignment__c>)Database.query(soqlQuery);
            for(Shared_Learning_Assignment__c a : sharedAssignments){

                if(!results.containsKey(a.Learning__c)){
                    results.put(a.Learning__c, new Map<Id,Shared_Learning_Assignment__c>());
                }
                results.get(a.Learning__c).put(a.User__c,a);
            }

            return results;
        }

        //It's possible that a users with limited access to learnings is creating an assignment for another user, we need to make sure we still have access to read the learning data
        public List<Learning__c> getLearningDataWOS(Set<Id> referencedLearnings){
            return [select id,Current_Published_Version__c from Learning__c where id in :referencedLearnings and Sync_progress__c = true];
        }

        //We need to insert shared assignments without sharing since we're referencing learnings that may not be shared with the running user
        public void insertSharedAssignmentsWOS(List<Shared_Learning_Assignment__c> newSharedAssignments){
            insert newSharedAssignments;
        }

        //We need to insert shared assignments without sharing since we're referencing learnings that may not be shared with the running user
        public void updateSharedAssignmentsWOS(List<Shared_Learning_Assignment__c> updatedSharedAssignments){
            update updatedSharedAssignments;
        }

        // We need to update section assignments without sharing since it's possible that the training plan objects have not been shared with the running user
        public void updateSectionAssignmentsWOS(Set<Id> updatedAssignmentIds, Set<Id> delTPSections, Set<Id> delUsers){

            Map<String,Map<String,Integer>> learningAggregatedResults = new Map<String,Map<String,Integer>>();
            List<Training_Plan_Section_Assignment__c> sectionAssignmentsToUpdate = new List<Training_Plan_Section_Assignment__c>();

            Set<Id> relatedTPlans = new Set<Id>();
            Set<Id> relatedTPlanSections = new Set<Id>();
            Set<Id> relatedUsers = new Set<Id>();

            if(delTPSections != null && delUsers != null){
                relatedTPlanSections = delTPSections;
                relatedUsers = delUsers;
            }else{
                //Get additional assignment information
                for(Learning_Assignment__c la : [select id
                                                        ,User__c
                                                        ,Training_Plan_Section__c
                                                        from Learning_Assignment__c
                                                        where id in :updatedAssignmentIds]){

                    relatedTPlanSections.add(la.Training_Plan_Section__c);
                    relatedUsers.add(la.User__c);
                }
            }

            //Filter inactive users
            Set<Id> activeUserIds = new Set<Id>();
            for(User u : [select id from User where id in :relatedUsers and IsActive = true]){
                activeUserIds.add(u.Id);
            }
            relatedUsers = activeUserIds;

            //Get aggregate information for associated assignments
            AggregateResult[] groupedResults = [select Training_Plan_Section__c
                                                        ,User__c
                                                        ,Progress__c
                                                        ,Training_Plan_Section_Item__r.Optional__c opt
                                                        ,count(Id) cnt
                                                        from Learning_Assignment__c
                                                        where User__c in :relatedUsers
                                                        and Training_Plan_Section__c in :relatedTPlanSections
                                                        and Training_Plan_Section_Item__c != null
                                                        group by Training_Plan_Section__c,User__c,Progress__c,Training_Plan_Section_Item__r.Optional__c];

            String OPT_PREFIX = 'opt_';

            //Update progress on related section assignments
            String ns = LMSUtils.getPackageNamespace();
            for(AggregateResult ar : groupedResults){
                String tPlanSectionId = (String)ar.get(ns+'Training_Plan_Section__c');
                String userId = (String)ar.get(ns+'User__c');

                Integer count = (Integer)ar.get('cnt');

                String optionalItem = '';
                if(ar.get('opt') != null){
                	Boolean isOptional = (Boolean)ar.get('opt');
                	optionalItem = isOptional?OPT_PREFIX:'';
                }

                //Default value of the progress type is not started
                String progressType = LMSConstants.ASSIGNMENT_STATUS_NOT_STARTED;
                if(ar.get(ns+'Progress__c') != null){
                	progressType = (String)ar.get(ns+'Progress__c');
                }
                progressType = optionalItem+progressType;

                String arKey = userId+'_'+tPlanSectionId;

                if(!learningAggregatedResults.containsKey(arKey)){
                    Map<String,Integer> initMap = new Map<String,Integer>{
                        LMSConstants.ASSIGNMENT_STATUS_NOT_STARTED=>0,
                        LMSConstants.ASSIGNMENT_STATUS_IN_PROGRESS=>0,
                        LMSConstants.ASSIGNMENT_STATUS_IN_REVIEW=>0,
                        LMSConstants.ASSIGNMENT_STATUS_COMPLETED=>0,
                        ''+OPT_PREFIX+LMSConstants.ASSIGNMENT_STATUS_NOT_STARTED=>0,
                        ''+OPT_PREFIX+LMSConstants.ASSIGNMENT_STATUS_IN_PROGRESS=>0,
                        ''+OPT_PREFIX+LMSConstants.ASSIGNMENT_STATUS_IN_REVIEW=>0,
                        ''+OPT_PREFIX+LMSConstants.ASSIGNMENT_STATUS_COMPLETED=>0

                    };
                    learningAggregatedResults.put(arKey,initMap);
                }
                learningAggregatedResults.get(arKey).put(progressType,count);
            }

            //Fetch training plan section assignments
            for(Training_Plan_Section_Assignment__c sa : [select id
                                                                ,User__c
                                                                ,Training_Plan_Section__c
                                                                ,Training_Plan_Section__r.Training_Plan__c
                                                                ,Status__c
                                                                from Training_Plan_Section_Assignment__c
                                                                where User__c in :relatedUsers
                                                                and Training_Plan_Section__c in :relatedTPlanSections]){

                relatedTPlans.add(sa.Training_Plan_Section__r.Training_Plan__c);

                String asKey = sa.User__c+'_'+sa.Training_Plan_Section__c;
                if(learningAggregatedResults.containsKey(asKey)){

                    Integer lNotStarted = learningAggregatedResults.get(asKey).get(LMSConstants.ASSIGNMENT_STATUS_NOT_STARTED);
                    Integer lInProgress = learningAggregatedResults.get(asKey).get(LMSConstants.ASSIGNMENT_STATUS_IN_PROGRESS);
                    Integer lCompleted = learningAggregatedResults.get(asKey).get(LMSConstants.ASSIGNMENT_STATUS_COMPLETED);
                    Integer lNotStartedOpt = learningAggregatedResults.get(asKey).get(OPT_PREFIX+LMSConstants.ASSIGNMENT_STATUS_NOT_STARTED);
                    Integer lInProgressOpt = learningAggregatedResults.get(asKey).get(OPT_PREFIX+LMSConstants.ASSIGNMENT_STATUS_IN_PROGRESS);
                    Integer lCompletedOpt = learningAggregatedResults.get(asKey).get(OPT_PREFIX+LMSConstants.ASSIGNMENT_STATUS_COMPLETED);

                    if(learningAggregatedResults.get(asKey).get(LMSConstants.ASSIGNMENT_STATUS_IN_REVIEW) != null){
                    	lInProgress += learningAggregatedResults.get(asKey).get(LMSConstants.ASSIGNMENT_STATUS_IN_REVIEW);
                    }
                    if(learningAggregatedResults.get(asKey).get(OPT_PREFIX+LMSConstants.ASSIGNMENT_STATUS_IN_REVIEW) != null){
                    	lInProgressOpt += learningAggregatedResults.get(asKey).get(OPT_PREFIX+LMSConstants.ASSIGNMENT_STATUS_IN_REVIEW);
                    }

                    String currentStatus = LMSConstants.ASSIGNMENT_STATUS_NOT_STARTED;

                    if(lInProgress >= 1 || (lCompleted > 0 && lNotStarted >= 1) || (lInProgress == 0 && lCompleted == 0 && (lInProgressOpt >= 1 || (lCompletedOpt >= 1 && (lNotStartedOpt >= 1 || lNotStarted >= 1))))){
                        currentStatus = LMSConstants.ASSIGNMENT_STATUS_IN_PROGRESS;
                    }else if(lInProgress == 0 && lNotStarted == 0 && lCompleted > 0){
                        currentStatus = LMSConstants.ASSIGNMENT_STATUS_COMPLETED;
                    }else if (lInProgress == 0 && lNotStarted == 0 && lCompleted == 0 && lInProgressOpt == 0 && lNotStarted == 0 && lCompletedOpt >= 1){
                    	currentStatus = LMSConstants.ASSIGNMENT_STATUS_COMPLETED;
                    }

                    sa.Status__c = currentStatus;
                    sectionAssignmentsToUpdate.add(sa);

                }

            }

            //Update section assigments
            if(sectionAssignmentsToUpdate.size()>0){
                update sectionAssignmentsToUpdate;
            }

            //Clear unusued maps before we continue
            learningAggregatedResults.clear();
            groupedResults.clear();

            //Update Training Plan Assignments
            updateTrainingPlanAssignments(relatedTPlans,relatedUsers);
        }

        // We need to update section assignments without sharing since it's possible that the training plan objects have not been shared with the running user
        public Map<String,Id> createPlanAssignments(List<Learning_Assignment__c> newAssignments){

            Map<String,Id> results = new Map<String,Id>();
            Map<String,Training_Plan_Assignment__c> insertTPAs = new Map<String,Training_Plan_Assignment__c>();

            Set<Id> userIds = new Set<Id>();
            Set<Id> trainingPlanIds = new Set<Id>();
            for(Learning_Assignment__c la : newAssignments){
                if(la.Training_Plan__c != null && !la.Is_Test_Assignment__c){
                    results.put(la.User__c+'_'+la.Training_Plan__c,null);
                    userIds.add(la.User__c);
                    trainingPlanIds.add(la.Training_Plan__c);
                }
            }

            //Look for existing plan assignments
            for(Training_Plan_Assignment__c tpa : [select id
                                                            ,Status__c
                                                            ,User__c
                                                            ,Training_Plan__c
                                                            from Training_Plan_Assignment__c
                                                            where User__c in :userIds
                                                            and Training_Plan__c in :trainingPlanIds]){
                results.put(tpa.User__c+'_'+tpa.Training_Plan__c,tpa.Id);
            }

            //Create new plan assignments in case these are not present
            for(Learning_Assignment__c la : newAssignments){
                String laKey = la.User__c+'_'+la.Training_Plan__c;
                if(!la.Is_Test_Assignment__c && results.get(laKey) == null && !insertTPAs.containsKey(laKey)){
                    Training_Plan_Assignment__c newTPA = new Training_Plan_Assignment__c();
                    newTPA.User__c = la.User__c;
                    newTPA.OwnerId = la.User__c;
                    newTPA.Training_Plan__c = la.Training_Plan__c;
                    newTPA.Community_Id__c = la.Community_Id__c;
                    newTPA.Status__c = LMSConstants.ASSIGNMENT_STATUS_NOT_STARTED;
                    insertTPAs.put(laKey,newTPA);
                }
            }

            if(insertTPAs.size()>0){
                insert insertTPAs.values();
            }

            for(Training_Plan_Assignment__c tpa : insertTPAs.values()){
                results.put(tpa.User__c+'_'+tpa.Training_Plan__c,tpa.Id);
            }

            return results;

        }

        // We need to update section assignments without sharing since it's possible that the training plan objects have not been shared with the running user
        public Map<String,Id> createSectionAssignments(List<Learning_Assignment__c> newAssignments,Map<String,Id> planAssignments){

            Map<String,Id> results = new Map<String,Id>();
            Map<String,Training_Plan_Section_Assignment__c> insertTPSAs = new Map<String,Training_Plan_Section_Assignment__c>();

            Set<Id> userIds = new Set<Id>();
            Set<Id> trainingPlanSectionIds = new Set<Id>();
            for(Learning_Assignment__c la : newAssignments){
                if(la.Training_Plan_Section__c != null && !la.Is_Test_Assignment__c){
                    results.put(la.User__c+'_'+la.Training_Plan_Section__c,null);
                    userIds.add(la.User__c);
                    trainingPlanSectionIds.add(la.Training_Plan_Section__c);
                }
            }

            //Look for existing section assignments
            for(Training_Plan_Section_Assignment__c tpsa : [select id
                                                                    ,Status__c
                                                                    ,User__c
                                                                    ,Training_Plan_Section__c
                                                                    from Training_Plan_Section_Assignment__c
                                                                    where User__c in :userIds
                                                                    and Training_Plan_Section__c in :trainingPlanSectionIds]){
                results.put(tpsa.User__c+'_'+tpsa.Training_Plan_Section__c,tpsa.Id);
            }

            //Create new section assignments in case these are not present
            for(Learning_Assignment__c la : newAssignments){
                String laKey = la.User__c+'_'+la.Training_Plan_Section__c;
                if(!la.Is_Test_Assignment__c && results.get(laKey) == null && !insertTPSAs.containsKey(laKey)){
                    Training_Plan_Section_Assignment__c newTPSA = new Training_Plan_Section_Assignment__c();
                    newTPSA.User__c = la.User__c;
                    newTPSA.OwnerId = la.User__c;
                    newTPSA.Training_Plan_Section__c = la.Training_Plan_Section__c;
                    newTPSA.Status__c = LMSConstants.ASSIGNMENT_STATUS_NOT_STARTED;
                    newTPSA.Community_Id__c = la.Community_Id__c;
                    newTPSA.Training_Plan_Assignment__c = planAssignments.get(la.User__c+'_'+la.Training_Plan__c);
                    insertTPSAs.put(laKey,newTPSA);
                }
            }

            if(insertTPSAs.size()>0){
                insert insertTPSAs.values();
            }

            for(Training_Plan_Section_Assignment__c tpsa : insertTPSAs.values()){
                results.put(tpsa.User__c+'_'+tpsa.Training_Plan_Section__c,tpsa.Id);
            }

            return results;
        }

    }

}
