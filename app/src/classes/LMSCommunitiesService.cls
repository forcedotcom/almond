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
public with sharing class LMSCommunitiesService{


    //Get a list of training plan ids that are linked to the specified learning category ids
    public static List<Id> getTrainingPlanIdsForCategory(Set<Id> categoryIds, Id accountId){

        //BEGIN Access Check
        Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
        relatedFieldsObjects.put(Training_Plan__c.sObjectType,new List<String>{
            'Id'
            ,'Name'
        });
        LMS_ESAPI.isAuthorizedToView(relatedFieldsObjects);
        //END Access Check

        List<Id> matchedTplanIds = new List<Id>();

        //Get training plan ids from training plan category ids
        LMSCommunitiesService.WithoutSharingOps wsops = new LMSCommunitiesService.WithoutSharingOps();
        Map<Id,List<Id>> categoryTplanMap = wsops.getCategoryTrainingPlanMap(categoryIds, accountId);

        for(Id cId : categoryTplanMap.keySet()){
            if(categoryTplanMap.get(cId) != null){
                matchedTplanIds.addAll(categoryTplanMap.get(cId));
            }
        }

        return matchedTplanIds;
    }


    //Without sharing operations, see justifications below
    public without sharing class WithoutSharingOps{

        //Get a list of training plan ids grouped by learning category Id
        public Map<Id,List<Id>> getCategoryTrainingPlanMap(Set<Id> categoryIds, Id accountId){

            Map<Id,List<Id>> result = new Map<Id,List<Id>>();
            Set<Id> catIds = categoryIds;

            //Get training plan ids from training plan category ids
            String soqlQuery = 'select Learning_Category__c,Training_Plan__c from Training_Plan_Category__c where Learning_Category__c in :catIds order by Order__c asc NULLS LAST';
            Set<Id> relatedTPlanIds = new Set<Id>();

            List<Training_Plan_Category__c> tplanCategories = (List<Training_Plan_Category__c>)Database.query(soqlQuery);

            for (Training_Plan_Category__c tpc : tplanCategories){
                if(tpc.Training_Plan__c != null){
                    relatedTPlanIds.add(tpc.Training_Plan__c);
                }
            }

            Set<Id> filteredTrainingPlans = filterTrainingPlansForAccount(relatedTPlanIds,accountId);

            if(filteredTrainingPlans.size()>0){
                for (Training_Plan_Category__c tpc : tplanCategories){
                    if(tpc.Training_Plan__c != null && filteredTrainingPlans.contains(tpc.Training_Plan__c)){
                        if(result.get(tpc.Learning_Category__c) == null){
                            result.put(tpc.Learning_Category__c, new List<Id>{tpc.Training_Plan__c});
                        }else{
                            result.get(tpc.Learning_Category__c).add(tpc.Training_Plan__c);
                        }
                    }
                }
            }

            return result;
        }

        public Set<Id> getTrainingPlanIdsForAccount(Id accountId){
            Set<Id> validAccountTrainingPlanIds = new Set<Id>();
            if(accountId != null){
                for(Training_Plan_Account__c tpa : [select Id,
                                                            Training_Plan__c
                                                            from Training_Plan_Account__c
                                                            where Account__c = :accountId]){
                    validAccountTrainingPlanIds.add(tpa.Training_Plan__c);
                }
            }
            return validAccountTrainingPlanIds;
        }

        public Set<Id> filterTrainingPlansForAccount(Set<Id> tplanIds, Id accountId){
            Set<Id> validAccountTrainingPlanIds = new Set<Id>();
            if(tplanIds != null && tplanIds.size()>0){

                for(Training_Plan_Account__c tpa : [select Id,
                                                            Training_Plan__c
                                                            from Training_Plan_Account__c
                                                            where Training_Plan__c in :tplanIds
                                                            and Account__c = :accountId]){
                    validAccountTrainingPlanIds.add(tpa.Training_Plan__c);
                }

                if(validAccountTrainingPlanIds.size() != tplanIds.size()){
                    //Run additional query for all externally available plans
                    for(Training_Plan__c tp : [select Id
                                                    from Training_Plan__c
                                                    where Id in :tplanIds
                                                    and Enable_Self_Registration__c = true
                                                    and Self_Registration_Access__c = :LMSConstants.TPLAN_PUBLIC_EXTERNAL]){
                        validAccountTrainingPlanIds.add(tp.Id);
                    }
                }
            }
            return validAccountTrainingPlanIds;
        }

        public Set<Id> filterTrainingTracksForAccount(Set<Id> trackIds, Id accountId, String filterStatus){
            Set<Id> validAccountTrainingTrackIds = new Set<Id>();
            if(trackIds != null && trackIds.size()>0){

                for(Training_Track_Account__c tpa : [select Id,
                                                            Training_Track__c
                                                            from Training_Track_Account__c
                                                            where Training_Track__c in :trackIds
                                                            and Account__c = :accountId]){
                    validAccountTrainingTrackIds.add(tpa.Training_Track__c);
                }

                if(validAccountTrainingTrackIds.size() != trackIds.size()){

                    String soqlQuery = 'select Id from Training_Track__c where Enable_all_external_accounts__c = true';
                    if(filterStatus != null){
                        soqlQuery += ' and Status__c = :filterStatus';
                    }
                    List<Training_Track__c> ttracks = (List<Training_Track__c>)Database.query(soqlQuery);
                    for(Training_Track__c ttk : ttracks){
                        validAccountTrainingTrackIds.add(ttk.Id);
                    }
                }
            }
            return validAccountTrainingTrackIds;
        }

        public Set<Id> getAccountTrainingTracks(Id accountId){
            Set<Id> validAccountTrainingTrackIds = new Set<Id>();

            for(Training_Track_Account__c tpa : [select Id,
                                                        Training_Track__c
                                                        from Training_Track_Account__c
                                                        where Account__c = :accountId]){
                validAccountTrainingTrackIds.add(tpa.Training_Track__c);
            }

            return validAccountTrainingTrackIds;
        }

    }

}
