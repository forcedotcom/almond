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
public with sharing class SharedLearningAssignmentsHelper{

    public static Set<Id> processedSharedAssignmentIds;

    public static void processAfterUpdate(Map<Id,Shared_Learning_Assignment__c> oldSAssignments, Map<Id,Shared_Learning_Assignment__c> newSAssigments){
        updateRelatedAssignments(oldSAssignments,newSAssigments);
    }

    public static void updateRelatedAssignments(Map<Id,Shared_Learning_Assignment__c> oldSAssignments, Map<Id,Shared_Learning_Assignment__c> newSAssigments){

        if(processedSharedAssignmentIds == null){
            processedSharedAssignmentIds = new Set<Id>();
        }

        Set<Id> sharedAssignmentsForUpdate = new Set<Id>();
        for(Shared_Learning_Assignment__c newSLA  : newSAssigments.values()){
            Shared_Learning_Assignment__c oldSLA = oldSAssignments.get(newSLA.Id);

            //Make sure we always keep these conditions in sync with the conditions defined in the Learning assignment helper class
            if(newSLA.Progress__c != oldSLA.Progress__c
                   || newSLA.Progress_Percentage__c != oldSLA.Progress_Percentage__c
                   || newSLA.Last_Published_Learning_Version__c != oldSLA.Last_Published_Learning_Version__c
                   || newSLA.Last_Published_Learning_Version_Decision__c != oldSLA.Last_Published_Learning_Version_Decision__c
                   || newSLA.Approved__c != oldSLA.Approved__c
                   || newSLA.Approved_By__c != oldSLA.Approved_By__c){

                //Make sure we don't process the same shared assignment twice in a single transaction
                if(!processedSharedAssignmentIds.contains(newSLA.id)){
                    sharedAssignmentsForUpdate.add(newSLA.id);
                    processedSharedAssignmentIds.add(newSLA.id);
                }
            }
        }

        if(sharedAssignmentsForUpdate.size()>0){

            if(!System.isFuture() && !System.isBatch()){
                doRelatedAssigmentsUpdateInFuture(sharedAssignmentsForUpdate);
            }else{
                doRelatedAssigmentsUpdate(sharedAssignmentsForUpdate);
            }
        }
    }

    @future
    public static void doRelatedAssigmentsUpdateInFuture(Set<Id> sharedAssignmentIds){
        doRelatedAssigmentsUpdate(sharedAssignmentIds);
    }

    public static void doRelatedAssigmentsUpdate(Set<Id> sharedAssignmentIds){
        SharedLearningAssignmentsHelper.WithoutSharingOps wosHelper = new SharedLearningAssignmentsHelper.WithoutSharingOps();
        wosHelper.doRelatedAssigmentsUpdateWOS(sharedAssignmentIds);
    }

    private without sharing class WithoutSharingOps{

        // We need to execute this without sharing as the running user may not have access to other learning assignments
        // For example, an approver is updating a learning assignment and this causes a progress recalculation
        public void doRelatedAssigmentsUpdateWOS(Set<Id> sharedAssignmentIds){

            //Get Shared Assignment information
            Map<Id,Shared_Learning_Assignment__c> sharedAssingments = new Map<Id,Shared_Learning_Assignment__c>();
            List<Learning_Assignment__c> learningAssignmentsForUpdate = new List<Learning_Assignment__c>();
            Set<Id> updatedLearningAssignments = new Set<Id>();

            for(Shared_Learning_Assignment__c sla : [select id
                                                            ,Progress__c
                                                            ,Progress_Percentage__c
                                                            ,Last_Published_Learning_Version__c
                                                            ,Last_Published_Learning_Version_Decision__c
                                                            ,Learning_Assignment_Last_Update__c
                                                            ,Approved__c
                                                            ,Approved_By__c
                                                            from Shared_Learning_Assignment__c
                                                            where id in :sharedAssignmentIds]){

                sharedAssingments.put(sla.Id,sla);

            }

            //Get related assignments
            for(Learning_Assignment__c la : [select id
                                                    ,Progress__c
                                                    ,Progress_Percentage__c
                                                    ,Last_Published_Learning_Version__c
                                                    ,Last_Published_Learning_Version_Decision__c
                                                    ,Shared_Learning_Assignment__c
                                                    ,Approved__c
                                                    ,Approved_By__c
                                                    from Learning_Assignment__c
                                                    where Shared_Learning_Assignment__c in :sharedAssingments.keySet()]){

                Shared_Learning_Assignment__c sla = sharedAssingments.get(la.Shared_Learning_Assignment__c);
                if(la.Id != sla.Learning_Assignment_Last_Update__c){

                    if(sla.Progress__c != la.Progress__c){
                        updatedLearningAssignments.add(la.Id);
                    }

                    la.Progress__c = sla.Progress__c;
                    la.Progress_Percentage__c = sla.Progress_Percentage__c;
                    la.Last_Published_Learning_Version__c = sla.Last_Published_Learning_Version__c;
                    la.Last_Published_Learning_Version_Decision__c = sla.Last_Published_Learning_Version_Decision__c;
                    la.Approved__c = sla.Approved__c;
                    la.Approved_By__c = sla.Approved_By__c;
                    learningAssignmentsForUpdate.add(la);
                }
            }

            if(learningAssignmentsForUpdate.size()>0){
                update learningAssignmentsForUpdate;
            }

        }
    }
}
