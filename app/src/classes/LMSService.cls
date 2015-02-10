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
public with sharing class LMSService{

    //Return a list of aggregate plan progress results for the specified progress filters and user based on Plan Assignments
    public static List<AggregateResult> getTrainingPlansAssignmentStatus(Set<String> statusFilter,String userId){

        //BEGIN Access Check
        Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
            relatedFieldsObjects.put(Training_Plan_Assignment__c.sObjectType,new List<String>{
                'Training_Plan__c'
            });
            LMS_ESAPI.isAuthorizedToView(relatedFieldsObjects);
        //END Access Check
        AggregateResult[] groupedResults = [select Training_Plan__c
                                                    ,count(Id) cnt
                                                    from Training_Plan_Assignment__c
                                                    where User__c = :userId
                                                    and Status__c in :statusFilter
                                                    group by Training_Plan__c];
        return groupedResults;

    }

    //Return a list of all training plans with "Not Started" status for the specified user
    public static List<Training_Plan__c> getNewTrainingPlans(String userId, Boolean isPortalUser){

        Set<Id> trainingPlanIds = new Set<Id>();
        String ns = LMSUtils.getPackageNamespace();

        List<AggregateResult> groupedResultsNotStarted = getTrainingPlansAssignmentStatus(new Set<String>{LMSConstants.TPLAN_STATUS_NOT_STARTED},userId);

        for (AggregateResult ar : groupedResultsNotStarted)  {
            if((Integer)ar.get('cnt') > 0){
                trainingPlanIds.add((String)ar.get(ns+'Training_Plan__c'));
            }
        }

        return getTrainingPlans(trainingPlanIds, isPortalUser);

    }

    //Return a list of all training plans with "In Progress" status for the specified user
    public static List<Training_Plan__c> getInProgressTrainingPlans(String userId, Boolean isPortalUser){

        String ns = LMSUtils.getPackageNamespace();
        List<AggregateResult> groupedResults = getTrainingPlansAssignmentStatus(new Set<String>{LMSConstants.TPLAN_STATUS_IN_PROGRESS},userId);

        Set<Id> trainingPlanIds = new Set<Id>();
        for (AggregateResult ar : groupedResults)  {
            if((Integer)ar.get('cnt') > 0){
                trainingPlanIds.add((String)ar.get(ns+'Training_Plan__c'));
            }
        }

        return getTrainingPlans(trainingPlanIds, isPortalUser);

    }

    //Return a list of all training plans with "Completed" status for the specified user
    public static List<Training_Plan__c> getCompletedTrainingPlans(String userId, Boolean isPortalUser){

        String ns = LMSUtils.getPackageNamespace();
        List<AggregateResult> groupedResultsCompleted = getTrainingPlansAssignmentStatus(new Set<String>{LMSConstants.TPLAN_STATUS_COMPLETED},userId);

        Set<Id> trainingPlanIds = new Set<Id>();

        for (AggregateResult ar : groupedResultsCompleted)  {
            if((Integer)ar.get('cnt') > 0){
                trainingPlanIds.add((String)ar.get(ns+'Training_Plan__c'));
            }
        }

        return getTrainingPlans(trainingPlanIds, isPortalUser);
    }

    //Return a list of training plans for the specified training plan ids
    public static List<Training_Plan__c> getTrainingPlans(Set<Id> trainingPlanIds, Boolean isPortalUser){

        //BEGIN Access Check
        Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
        relatedFieldsObjects.put(Training_Plan__c.sObjectType,new List<String>{
            'Id'
            ,'Name'
            ,'Description__c'
            ,'Enable_Self_Registration__c'
            ,'Self_Registration_Access__c'
            ,'Enforce_Sequence__c'
            ,'Status__c'
            ,'Start_Date__c'
            ,'End_Date__c'
            ,'Background_Image_URL__c'
            ,'Intro_Video_URL__c'
            ,'Background_Color__c'
            ,'Text_Color__c'
            ,'Training_Plan_Rating__c'
            ,'Hide_Chatter_Photos__c'
            ,'Optional_Feedback_Comments__c'
        });
        LMS_ESAPI.isAuthorizedToView(relatedFieldsObjects);
        //END Access Check

        List<Training_Plan__c> results = new List<Training_Plan__c>();

        //Create local scope vars for Dynamic SOQL binding
        Set<Id> tpIds = trainingPlanIds;

        List<String> listSOQLFields = new List<String>{
            'Id'
            ,'Name'
            ,'Description__c'
            ,'Enable_Self_Registration__c'
            ,'Self_Registration_Access__c'
            ,'Enforce_Sequence__c'
            ,'Status__c'
            ,'Start_Date__c'
            ,'End_Date__c'
            ,'Intro_Video_URL__c'
            ,'Background_Image_URL__c'
            ,'Background_Color__c'
            ,'Text_Color__c'
            ,'Training_Plan_Rating__c'
            ,'Hide_Chatter_Photos__c'
            ,'Optional_Feedback_Comments__c'
        };

        if(isPortalUser){
            LMSCommunitiesService.WithoutSharingOps commwsops = new LMSCommunitiesService.WithoutSharingOps();
            tpIds = commwsops.filterTrainingPlansForAccount(tpIds,LMSUtils.getUserAccountId());
        }

        String soqlQuery = 'select '+String.join(listSOQLFields,',')+' from Training_Plan__c where Id in :tpIds';
        soqlQuery += ' order by SystemModStamp desc';

        if(isPortalUser){
            LMSService.WithoutSharingOps wsops = new LMSService.WithoutSharingOps();
            results = wsops.queryTrainingPlans(soqlQuery,tpIds, null);
        }else{
            results = (List<Training_Plan__c>)Database.query(soqlQuery);
        }

        return results;

    }

    //Return a list of training plans enabled for preview for the specified training plan ids
    public static List<Training_Plan__c> getPreviewTrainingPlans(Set<Id> trainingPlanIds,Boolean isPortalUser){

        //BEGIN Access Check
        Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
        relatedFieldsObjects.put(Training_Plan__c.sObjectType,new List<String>{
            'Id'
            ,'Name'
            ,'Description__c'
            ,'Enable_Self_Registration__c'
            ,'Self_Registration_Access__c'
            ,'Enforce_Sequence__c'
            ,'Status__c'
            ,'Start_Date__c'
            ,'End_Date__c'
            ,'Background_Image_URL__c'
            ,'Intro_Video_URL__c'
            ,'Background_Color__c'
            ,'Text_Color__c'
            ,'Training_Plan_Rating__c'
            ,'Hide_Chatter_Photos__c'
            ,'Optional_Feedback_Comments__c'
        });
        LMS_ESAPI.isAuthorizedToView(relatedFieldsObjects);
        //END Access Check

        List<Training_Plan__c> results = new List<Training_Plan__c>();

        //Create local scope vars for Dynamic SOQL binding
        Set<Id> tpIds = trainingPlanIds;

        List<String> listSOQLFields = new List<String>{
            'Id'
            ,'Name'
            ,'Description__c'
            ,'Enable_Self_Registration__c'
            ,'Self_Registration_Access__c'
            ,'Enforce_Sequence__c'
            ,'Status__c'
            ,'Start_Date__c'
            ,'End_Date__c'
            ,'Intro_Video_URL__c'
            ,'Background_Image_URL__c'
            ,'Background_Color__c'
            ,'Text_Color__c'
            ,'Training_Plan_Rating__c'
            ,'Hide_Chatter_Photos__c'
            ,'Optional_Feedback_Comments__c'
        };

        String registrationAccess = LMSConstants.TPLAN_PUBLIC_EXTERNAL;
        String soqlQuery = 'select '+String.join(listSOQLFields,',')+' from Training_Plan__c where Id in :tpIds';
        soqlQuery += ' and Enable_Self_Registration__c = true';

        if(isPortalUser){
            LMSCommunitiesService.WithoutSharingOps commwsops = new LMSCommunitiesService.WithoutSharingOps();
            tpIds = commwsops.filterTrainingPlansForAccount(tpIds,LMSUtils.getUserAccountId());
            if(tpIds.size() == 0){
                soqlQuery += ' and Self_Registration_Access__c = :registrationAccess';
            }
        }

        soqlQuery += ' order by CreatedDate desc';

        if(isPortalUser){
            LMSService.WithoutSharingOps wsops = new LMSService.WithoutSharingOps();
            results = wsops.queryTrainingPlans(soqlQuery, tpIds, registrationAccess);
        }else{
            results = (List<Training_Plan__c>)Database.query(soqlQuery);
        }

        return results;

    }

    //Get a list of training plan ids that are linked to the specified learning category ids
    public static List<Id> getTrainingPlanIdsForCategory(Set<Id> categoryIds){

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
        Map<Id,List<Id>> categoryTplanMap = getCategoryTrainingPlanMap(categoryIds);
        for(Id cId : categoryTplanMap.keySet()){
            if(categoryTplanMap.get(cId) != null){
                matchedTplanIds.addAll(categoryTplanMap.get(cId));
            }
        }

        return matchedTplanIds;
    }

    //Get a list of training plan ids grouped by learning category Id
    public static Map<Id,List<Id>> getCategoryTrainingPlanMap(Set<Id> categoryIds){

        Map<Id,List<Id>> result = new Map<Id,List<Id>>();
        Set<Id> catIds = categoryIds;

        //Get training plan ids from training plan category ids
        String soqlQuery = 'select Learning_Category__c,Training_Plan__c from Training_Plan_Category__c where Learning_Category__c in :catIds order by Order__c asc NULLS LAST';
        for (Training_Plan_Category__c tpc : (List<Training_Plan_Category__c>)Database.query(soqlQuery)){
            if(tpc.Training_Plan__c != null){
                if(result.get(tpc.Learning_Category__c) == null){
                    result.put(tpc.Learning_Category__c, new List<Id>{tpc.Training_Plan__c});
                }else{
                    result.get(tpc.Learning_Category__c).add(tpc.Training_Plan__c);
                }
            }
        }

        return result;
    }

    //Get training plan main achievement
    public static Map<Id,Achievement__c> getTrainingMainAchievements(Set<Id> trainingPlanIds){

        Map<Id,Achievement__c> results = new Map<Id,Achievement__c>();
        Map<Id,List<Training_Plan_Achievement__c>> trainingPlanAchievementsMap = getTrainingPlanAchievements(trainingPlanIds,'Plan');
        Map<Id,List<Training_Plan_Achievement__c>> trainingPlanSectionAchievementsMap = getTrainingPlanAchievements(trainingPlanIds,'Section');

        if(trainingPlanAchievementsMap.size()>0 || trainingPlanSectionAchievementsMap.size()>0){
            for(Id trainingPlanId : trainingPlanIds){

                List<Training_Plan_Achievement__c> tpAchievements = trainingPlanAchievementsMap.get(trainingPlanId);
                Achievement__c mainAchievement = null;

                if(tpAchievements != null && tpAchievements.size()>0){

                    //Set main achievement, default to the first entry
                    mainAchievement = tpAchievements.get(0).Achievement__r;

                    if(tpAchievements.size()>1){
                        for(Training_Plan_Achievement__c tpa : tpAchievements){
                            if(tpa.Main_Achievement__c){
                                mainAchievement = tpa.Achievement__r;
                                break;
                            }
                        }
                    }
                }

                //If we couldn't find an achievement at the training plan level then look for one at the section level
                if(mainAchievement == null){

                    if(trainingPlanSectionAchievementsMap.size()>0){

                        tpAchievements = trainingPlanSectionAchievementsMap.get(trainingPlanId);

                        if(tpAchievements != null && tpAchievements.size()>0){

                            //Set main achievement, default to the first entry
                            mainAchievement = tpAchievements.get(0).Achievement__r;

                            if(tpAchievements.size()>1){
                                for(Training_Plan_Achievement__c tpa : tpAchievements){
                                    if(tpa.Main_Achievement__c){
                                        mainAchievement = tpa.Achievement__r;
                                        break;
                                    }
                                }
                            }

                        }
                    }

                }

                if(mainAchievement != null){
                    results.put(trainingPlanId,mainAchievement);
                }

            }
        }

        return results;
    }

    //Return a map of training plan sections for the specified training plan ids
    public static Map<Id,List<Training_Plan_Section__c>> getTrainingPlanSections(Set<Id> trainingPlanIds, Boolean isPortalUser){

        //BEGIN Access Check
        Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
        relatedFieldsObjects.put(Training_Plan_Section__c.sObjectType,new List<String>{
            'Id'
            ,'Name'
            ,'Order__c'
            ,'Optional__c'
            ,'Training_Plan__c'
        });
        LMS_ESAPI.isAuthorizedToView(relatedFieldsObjects);
        //END Access Check

        Map<Id,List<Training_Plan_Section__c>> results = new Map<Id,List<Training_Plan_Section__c>>();

        //Create local scope vars for Dynamic SOQL binding
        Set<Id> tpIds = trainingPlanIds;

        List<String> listSOQLFields = new List<String>{
            'Id'
            ,'Name'
            ,'Order__c'
            ,'Optional__c'
            ,'Training_Plan__c'
        };

        String soqlQuery = 'select '+String.join(listSOQLFields,',')+' from Training_Plan_Section__c where Training_Plan__c in :tpIds';
        soqlQuery += ' order by Order__c asc,CreatedDate desc';

        List<Training_Plan_Section__c> tpSections = new List<Training_Plan_Section__c>();
        if(isPortalUser){
            LMSService.WithoutSharingOps wsops = new LMSService.WithoutSharingOps();
            tpSections = wsops.queryTrainingPlanSections(soqlQuery, tpIds);
        }else{
            tpSections = (List<Training_Plan_Section__c>)Database.query(soqlQuery);
        }

        for(Training_Plan_Section__c tpSection : tpSections){

            if(!results.containsKey(tpSection.training_plan__c)){
                results.put(tpSection.training_plan__c, new List<Training_Plan_Section__c>());
            }
            results.get(tpSection.training_plan__c).add(tpSection);
        }

        return results;

    }

    //Return a map of assignments for the specified learnings + user ids
    public static Map<Id,List<Learning_Assignment__c>> getAssignmentsForLearnings(Set<Id> learningIds, Id trainingPlanFilter,Set<Id> userIds){

        //BEGIN Access Check
        Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
        relatedFieldsObjects.put(Learning_Assignment__c.sObjectType,new List<String>{
            'Id'
            ,'Name'
            ,'User__c'
            ,'OwnerId'
            ,'Learning__c'
            ,'Learning_Version__c'
            ,'Progress__c'
            ,'Progress_Percentage__c'
            ,'Approved__c'
            ,'Approved_By__c'
            ,'Evaluation_Result__c'
            ,'Evaluation_Score__c'
            ,'Evaluation_Times_Taken__c'
            ,'Training_Plan__c'
            ,'Training_Plan_Section__c'
            ,'Training_Plan_Section_Item__c'
            ,'Last_Published_Learning_Version__c'
            ,'Last_Published_Learning_Version_Decision__c'
            ,'Shared_Learning_Assignment__c'
        });
        relatedFieldsObjects.put(Shared_Learning_Assignment__c.sObjectType,new List<String>{
            'Progress__c'
            ,'Progress_Percentage__c'
            ,'Learning_Version__c'
        });

        LMS_ESAPI.isAuthorizedToView(relatedFieldsObjects);
        //END Access Check

        Map<Id,List<Learning_Assignment__c>> results = new Map<Id,List<Learning_Assignment__c>>();

        //Create local scope vars for Dynamic SOQL binding
        Set<Id> lIds = learningIds;
        Set<Id> uIds = userIds;
        Id tpId = trainingPlanFilter;

        List<String> listSOQLFields = new List<String>{
            'Id'
            ,'Name'
            ,'Contact__c'
            ,'User__c'
            ,'OwnerId'
            ,'Learning__c'
            ,'Learning_Version__c'
            ,'Progress__c'
            ,'Progress_Percentage__c'
            ,'Approved__c'
            ,'Approved_By__c'
            ,'Optional__c'
            ,'Evaluation_Result__c'
            ,'Evaluation_Score__c'
            ,'Evaluation_Times_Taken__c'
            ,'Training_Plan__c'
            ,'Training_Plan_Section__c'
            ,'Training_Plan_Section_Item__c'
            ,'Last_Published_Learning_Version__c'
            ,'Last_Published_Learning_Version_Decision__c'
            ,'Shared_Learning_Assignment__c'
            ,'Shared_Learning_Assignment__r.Progress__c'
            ,'Shared_Learning_Assignment__r.Progress_Percentage__c'
            ,'Shared_Learning_Assignment__r.Learning_Version__c'
            ,'Training_Plan_Section_Assignment__r.Training_Plan_Assignment__c'
        };

        String soqlQuery = 'select '+String.join(listSOQLFields,',')+' from Learning_Assignment__c where User__c in :uIds and Learning__c in :lIds';
        if(trainingPlanFilter != null){
            soqlQuery +=' and (Training_Plan__c = :tpId) ';
        }
        soqlQuery += ' order by CreatedDate desc';

        List<Learning_Assignment__c> assignments = (List<Learning_Assignment__c>)Database.query(soqlQuery);
        for(Learning_Assignment__c a : assignments){

            if(!results.containsKey(a.Learning__c)){
                results.put(a.Learning__c, new List<Learning_Assignment__c>());
            }
            results.get(a.Learning__c).add(a);
        }

        return results;
    }

    //Return a map of shared assignments for the specified learnings + user ids
    public static Map<Id,Map<Id,Shared_Learning_Assignment__c>> getSharedAssignmentsForLearnings(Set<Id> learningIds,Set<Id> userIds){

        Map<Id,Map<Id,Shared_Learning_Assignment__c>> results = new Map<Id,Map<Id,Shared_Learning_Assignment__c>>();

        //BEGIN Access Check
        Map<Schema.sObjectType,List<String>> relatedFieldsObjectsView = new Map<Schema.sObjectType,List<String>>();
        relatedFieldsObjectsView.put(Shared_Learning_Assignment__c.sObjectType,new List<String>{
            'Id'
            ,'Name'
            ,'OwnerId'
            ,'User__c'
            ,'Learning__c'
            ,'Learning_Version__c'
            ,'Progress__c'
            ,'Progress_Percentage__c'
            ,'Evaluation_Result__c'
            ,'Evaluation_Score__c'
            ,'Evaluation_Times_Taken__c'
            ,'Approved__c'
            ,'Approved_By__c'
            ,'Last_Published_Learning_Version__c'
            ,'Last_Published_Learning_Version_Decision__c'
        });
        LMS_ESAPI.isAuthorizedToView(relatedFieldsObjectsView);
        //END Access Check

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

    //Return the plan assignment for users + training plan  specified
    public static Map<Id,Map<Id,Training_Plan_Assignment__c>> getTrainingPlanAssignments(Set<Id> userIds, Set<Id> tPlans){

        //BEGIN Access Check
        Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
        relatedFieldsObjects.put(Training_Plan_Assignment__c.sObjectType,new List<String>{
            'Id'
            ,'User__c'
            ,'Status__c'
            ,'Training_Plan__c'
        });
        LMS_ESAPI.isAuthorizedToView(relatedFieldsObjects);
        //END Access Check

        Map<Id,Map<Id,Training_Plan_Assignment__c>> results = new Map<Id,Map<Id,Training_Plan_Assignment__c>>();

        //Create local scope vars for Dynamic SOQL binding
        Set<Id> tpIds = tPlans;
        Set<Id> uIds = userIds;

        List<String> listSOQLFields = new List<String>{
            'Id'
            ,'User__c'
            ,'Status__c'
            ,'Training_Plan__c'
        };

        String soqlQuery = 'select '+String.join(listSOQLFields,',')+' from Training_Plan_Assignment__c where User__c in :uIds and Training_Plan__c in :tpIds';
        soqlQuery += ' order by CreatedDate asc';

        List<Training_Plan_Assignment__c> planAssignments = (List<Training_Plan_Assignment__c>)Database.query(soqlQuery);
        for(Training_Plan_Assignment__c tpa : planAssignments){

            if(!results.containsKey(tpa.User__c)){
                results.put(tpa.User__c, new Map<Id,Training_Plan_Assignment__c>());
            }

            results.get(tpa.User__c).put(tpa.Training_Plan__c,tpa);
        }


        return results;

    }

    //Return the section assignment for users + training plan sections specified
    public static Map<Id,Map<Id,Training_Plan_Section_Assignment__c>> getTrainingPlanSectionAssignments(Set<Id> userIds, Set<Id> tPlanSections){

        //BEGIN Access Check
        Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
        relatedFieldsObjects.put(Training_Plan_Section_Assignment__c.sObjectType,new List<String>{
            'Id'
            ,'User__c'
            ,'Status__c'
            ,'Training_Plan_Section__c'
        });
        LMS_ESAPI.isAuthorizedToView(relatedFieldsObjects);
        //END Access Check

        Map<Id,Map<Id,Training_Plan_Section_Assignment__c>> results = new Map<Id,Map<Id,Training_Plan_Section_Assignment__c>>();

        //Create local scope vars for Dynamic SOQL binding
        Set<Id> sIds = tPlanSections;
        Set<Id> uIds = userIds;

        List<String> listSOQLFields = new List<String>{
            'Id'
            ,'User__c'
            ,'Status__c'
            ,'Training_Plan_Section__c'
        };

        String soqlQuery = 'select '+String.join(listSOQLFields,',')+' from Training_Plan_Section_Assignment__c where User__c in :uIds and Training_Plan_Section__c in :sIds';
        soqlQuery += ' order by CreatedDate asc';

        List<Training_Plan_Section_Assignment__c> sectionAssignments = (List<Training_Plan_Section_Assignment__c>)Database.query(soqlQuery);
        for(Training_Plan_Section_Assignment__c tpsa : sectionAssignments){

            if(!results.containsKey(tpsa.User__c)){
                results.put(tpsa.User__c, new Map<Id,Training_Plan_Section_Assignment__c>());
            }

            results.get(tpsa.User__c).put(tpsa.Training_Plan_Section__c,tpsa);
        }


        return results;

    }

    //Return a map that contains training plan achievements of type for the specified training plans
    public static Map<Id,List<Training_Plan_Achievement__c>> getTrainingPlanAchievements(Set<Id> trainingPlanIds,String planAchievementType){

        //BEGIN Access Check
        Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
        relatedFieldsObjects.put(Training_Plan_Achievement__c.sObjectType,new List<String>{
            'Id'
            ,'Name'
            ,'Training_Plan__c'
            ,'Training_Plan_Section__c'
            ,'Type__c'
            ,'Main_Achievement__c'
            ,'Achievement__c'
        });
        relatedFieldsObjects.put(Achievement__c.sObjectType,new List<String>{
            'Id'
            ,'Acquired_Image__c'
            ,'Eligible_Image__c'
            ,'Work_Badge_Id__c'
            ,'Work_Badge_Image_URL__c'
        });
        LMS_ESAPI.isAuthorizedToView(relatedFieldsObjects);
        //END Access Check

        Map<Id,List<Training_Plan_Achievement__c>> results = new Map<Id,List<Training_Plan_Achievement__c>>();

        //Create local scope vars for Dynamic SOQL binding
        Set<Id> tplIds = trainingPlanIds;
        String tpaType = planAchievementType;

        if(tpaType == null){
            tpaType = 'Plan';
        }

        List<String> listSOQLFields = new List<String>{
            'Id'
            ,'Name'
            ,'Training_Plan__c'
            ,'Training_Plan_Section__c'
            ,'Type__c'
            ,'Main_Achievement__c'
            ,'Achievement__c'
            ,'Achievement__r.Id'
            ,'Achievement__r.Acquired_Image__c'
            ,'Achievement__r.Eligible_Image__c'
            ,'Achievement__r.Work_Badge_Id__c'
            ,'Achievement__r.Work_Badge_Image_URL__c'
        };

        String soqlQuery = 'select '+String.join(listSOQLFields,',')+' from Training_Plan_Achievement__c where Training_Plan__c in :tplIds and Type__c = :tpaType';
        soqlQuery += ' order by CreatedDate desc';

        LMSService.WithoutSharingOps wsops = new LMSService.WithoutSharingOps();
        List<Training_Plan_Achievement__c> tplanAchievements = wsops.queryTrainingPlanAchievements(soqlQuery, tplIds, tpaType);

        for(Training_Plan_Achievement__c tpa : tplanAchievements){
            if(!results.containsKey(tpa.Training_Plan__c)){
                results.put(tpa.Training_Plan__c, new List<Training_Plan_Achievement__c>());
            }
            results.get(tpa.Training_Plan__c).add(tpa);
        }

        return results;
    }

    //Return a map that contains training plan achievements of type for the specified training plan sections
    public static Map<Id,List<Training_Plan_Achievement__c>> getTrainingPlanSectionAchievements(Set<Id> trainingPlanSectionIds,String planAchievementType){

        //BEGIN Access Check
        Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
        relatedFieldsObjects.put(Training_Plan_Achievement__c.sObjectType,new List<String>{
            'Id'
            ,'Name'
            ,'Training_Plan__c'
            ,'Training_Plan_Section__c'
            ,'Type__c'
            ,'Main_Achievement__c'
            ,'Achievement__c'
        });
        relatedFieldsObjects.put(Achievement__c.sObjectType,new List<String>{
            'Id'
            ,'Acquired_Image__c'
            ,'Eligible_Image__c'
            ,'Work_Badge_Id__c'
            ,'Work_Badge_Image_URL__c'
        });
        LMS_ESAPI.isAuthorizedToView(relatedFieldsObjects);
        //END Access Check

        Map<Id,List<Training_Plan_Achievement__c>> results = new Map<Id,List<Training_Plan_Achievement__c>>();

        //Create local scope vars for Dynamic SOQL binding
        Set<Id> tpsIds = trainingPlanSectionIds;
        String tpaType = planAchievementType;

        if(tpaType == null){
            tpaType = 'Section';
        }

        List<String> listSOQLFields = new List<String>{
            'Id'
            ,'Name'
            ,'Training_Plan__c'
            ,'Training_Plan_Section__c'
            ,'Type__c'
            ,'Main_Achievement__c'
            ,'Achievement__c'
            ,'Achievement__r.Id'
            ,'Achievement__r.Acquired_Image__c'
            ,'Achievement__r.Eligible_Image__c'
            ,'Achievement__r.Work_Badge_Id__c'
            ,'Achievement__r.Work_Badge_Image_URL__c'
        };

        String soqlQuery = 'select '+String.join(listSOQLFields,',')+' from Training_Plan_Achievement__c where Training_Plan_Section__c in :tpsIds and Type__c = :tpaType';
        soqlQuery += ' order by CreatedDate desc';

        LMSService.WithoutSharingOps wsops = new LMSService.WithoutSharingOps();
        List<Training_Plan_Achievement__c> tplanAchievements = wsops.queryTrainingPlanSectionAchievements(soqlQuery, tpsIds, tpaType);

        for(Training_Plan_Achievement__c tpa : tplanAchievements){
            if(!results.containsKey(tpa.Training_Plan_Section__c)){
                results.put(tpa.Training_Plan_Section__c, new List<Training_Plan_Achievement__c>());
            }
            results.get(tpa.Training_Plan_Section__c).add(tpa);
        }

        return results;
    }

    //Return a map that contains achievement assignments for the specified users + plan achievements
    public static Map<String,List<Achievement_Assignment__c>> getAchievementAssignmentforTrainingPlanAchievements(Set<Id> userIds,Set<Id> tplanIds){

        //BEGIN Access Check
        Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
        relatedFieldsObjects.put(Achievement_Assignment__c.sObjectType,new List<String>{
            'Id'
            ,'Name'
            ,'Status__c'
            ,'User__c'
            ,'Training_Plan_Achievement__c'
            ,'Achievement__c'
        });
        relatedFieldsObjects.put(Training_Plan_Achievement__c.sObjectType,new List<String>{
            'Training_Plan__c'
            ,'Training_Plan_Section__c'
        });
        relatedFieldsObjects.put(Achievement__c.sObjectType,new List<String>{
            'Override_Completed_Status__c'
        });
        LMS_ESAPI.isAuthorizedToView(relatedFieldsObjects);
        //END Access Check

        Map<String,List<Achievement_Assignment__c>> results = new Map<String,List<Achievement_Assignment__c>>();

        //Create local scope vars for Dynamic SOQL binding
        Set<Id> uIds = userIds;
        Set<Id> tpIds = tplanIds;

        List<String> listSOQLFields = new List<String>{
            'Id'
            ,'Name'
            ,'Status__c'
            ,'User__c'
            ,'Contact__c'
            ,'Training_Plan_Achievement__c'
            ,'Achievement__c'
            ,'Achievement__r.Override_Completed_Status__c'
        };

        String soqlQuery = 'select '+String.join(listSOQLFields,',')+' from Achievement_Assignment__c where Training_Plan_Achievement__c in :tplanIds and User__c in :uIds';
        soqlQuery += ' order by CreatedDate desc';


        List<Achievement_Assignment__c> achievementAssignments = (List<Achievement_Assignment__c>)Database.query(soqlQuery);

        Set<Id> tplanAchievementIds = new Set<Id>();

        //Extract tplan achievement data
        for(Achievement_Assignment__c aa : achievementAssignments){
            if(aa.Training_Plan_Achievement__c != null){
                tplanAchievementIds.add(aa.Training_Plan_Achievement__c);
            }
        }

        //Query training plan achievemnt information
        LMSService.WithoutSharingOps wsops = new LMSService.WithoutSharingOps();
        Map<Id,Training_Plan_Achievement__c> tplanAchievementsMap = wsops.getTrainingPlanAchievementDetails(tplanAchievementIds);

        for(Achievement_Assignment__c aa : achievementAssignments){
            String key = aa.User__c+'_';
            Training_Plan_Achievement__c tplanAchievement = tplanAchievementsMap.get(aa.Training_Plan_Achievement__c);

            if(tplanAchievement == null){
                continue;
            }

            if(tplanAchievement.Training_Plan__c == null){
                continue;
            }else{
                if(tplanAchievement.Training_Plan_Section__c != null){
                    key+=tplanAchievement.Training_Plan_Section__c;
                }else{
                    key+=tplanAchievement.Training_Plan__c;
                }
            }

            if(!results.containsKey(key)){
                results.put(key, new List<Achievement_Assignment__c>());
            }
            results.get(key).add(aa);
        }

        return results;
    }

    //Return additional user information for the specified set of user ids
    public static Map<Id,User> getAdditionalUserInfo(Set<Id> userIds){

        //No need to enforce CRUD/FLS on User + standard fields

        Map<Id,User> results = new Map<Id,User>();

        for(User u : [select Id
                            ,ContactId
                            ,Email
                            ,isActive
                            ,ProfileId
                            ,UserType
                            from User
                            where Id in :userIds]){
            results.put(u.Id,u);
        }
        return results;
    }

    //Return the ids of users that have achievement assignments for the specified achievement Id
    public static List<User> getUsersForAchievement(Id achievementId,String status,Integer maxRecords){

        //BEGIN Access Check
        Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
        relatedFieldsObjects.put(Achievement_Assignment__c.sObjectType,new List<String>{
            'Id'
            ,'User__c'
        });
        LMS_ESAPI.isAuthorizedToView(relatedFieldsObjects);
        //END Access Check

        List<User> results = new List<User>();
        Set<Id> uIds = new Set<Id>();

        //Query AA records
        for(Achievement_Assignment__c aa : [select Id
                                            ,User__c
                                            from Achievement_Assignment__c
                                            where Achievement__c = :achievementId
                                            and Status__c = :status
                                            order by SystemModStamp desc
                                            limit :maxRecords]){

            if(aa.User__c != null){
                uIds.add(aa.User__c);
            }
        }

        //Get user info
        results = [select Id
                        ,Name
                        ,FullPhotoUrl
                        ,SmallPhotoUrl
                        from User
                        where id in :uIds];
        return results;
    }

    //Upsert learning assignments for the specified users under the specified training plan Id
    public static Map<Id,List<Learning_Assignment__c>> upsertAssignments(Set<Id> userIds, Id trainingPlanId, Id communityId){

        //Ignore inactive users
        Set<Id> activeUserIds = new Set<Id>();
        for(User u : [select id from User where id in :userIds and IsActive = true]){
            activeUserIds.add(u.Id);
        }

        //Auxiliary collections
        Map<Id,List<Learning_Assignment__c>> results = new Map<Id,List<Learning_Assignment__c>>();
        List<Learning_Assignment__c> assignmentsToInsert = new List<Learning_Assignment__c>();
        Set<Id> newUsersWithAssignments = new Set<Id>();
        Map<Id,Set<String>> excludedLearnings = new Map<Id,Set<String>>();
        Map<Id,Training_Plan_Assignment__c> planAssignmentsToUpdate = new Map<Id,Training_Plan_Assignment__c>();

        //Get all the learning ids under the specified training plan
        Map<Id,Learning_Assignment__c> updatedOptionalAssignments = new  Map<Id,Learning_Assignment__c>();

        LMSService.WithoutSharingOps wsops = new LMSService.WithoutSharingOps();

        Map<Id,Set<Id>> trainingPlanLearnings = wsops.getTrainingPlanLearningIds(new Set<Id>{trainingPlanId});

        //Get existing assignments for the user + learnings under the training plan, and add them to excluded learnings
        if(trainingPlanLearnings.get(trainingPlanId) != null){

            //Fetch additional information for related training plan section items
            Map<Id,List<Training_Plan_Section_Item__c>> tPlanSectionItems = wsops.getTrainingPlanSectionItemsFromTrainingPlans(new Set<Id>{trainingPlanId});

            //Fetch optional attribute from related training plan section and section items
            Map<Id,Boolean> tPlanSectionItemMap = new Map<Id,Boolean>();
            if(tPlanSectionItems.get(trainingPlanId) != null){
                List<Training_Plan_Section_Item__c> sectionItems = tPlanSectionItems.get(trainingPlanId);
                for(Training_Plan_Section_Item__c tpsi : sectionItems){
                    Boolean isOptional = false;
                    if(tpsi.Training_Plan_Section__r != null && tpsi.Training_Plan_Section__r.Optional__c){
                        isOptional = true;
                    }else{
                        isOptional = tpsi.Optional__c;
                    }
                    tPlanSectionItemMap.put(tpsi.id,isOptional);
                }
            }

            Set<Id> learnings = trainingPlanLearnings.get(trainingPlanId);

            Map<Id,List<Learning_Assignment__c>> mapLearningAssignments = getAssignmentsForLearnings(learnings,trainingPlanId,activeUserIds);

            //Look for learnings that already have assignments and add to excluded map
            for(Id learningId : mapLearningAssignments.keySet()){
                List<Learning_Assignment__c> existingUserAssignments = mapLearningAssignments.get(learningId);
                for(Learning_Assignment__c la : existingUserAssignments){

                    Id sectionItemId = la.Training_Plan_Section_Item__c;

                    //Get the training plan assignment Id and store it, we'll update the Last Updated field here
                    Id tPlanAssignmentId = la.Training_Plan_Section_Assignment__r.Training_Plan_Assignment__c;
                    if(tPlanAssignmentId!= null && !planAssignmentsToUpdate.containsKey(tPlanAssignmentId)){
                        planAssignmentsToUpdate.put(tPlanAssignmentId,new Training_Plan_Assignment__c(id=tPlanAssignmentId,Last_Updated__c = DateTime.now()));
                    }

                    //Initialize the set of excluded Learnings with the user id as key
                    if(!excludedLearnings.containsKey(la.User__c)){
                        excludedLearnings.put(la.User__c,new Set<String>());
                    }
                    //The value of the user key is a combination of learning and sectionItemId
                    excludedLearnings.get(la.User__c).add(learningId+'_'+sectionItemId);

                    //Update optional attributes if related section or section item has changed
                    if(tPlanSectionItemMap.containsKey(la.Training_Plan_Section_Item__c)){
                        if(la.Optional__c != tPlanSectionItemMap.get(la.Training_Plan_Section_Item__c)){
                            la.Optional__c = tPlanSectionItemMap.get(la.Training_Plan_Section_Item__c);
                            updatedOptionalAssignments.put(la.Id,la);
                        }
                    }

                }
            }

            //Get additional training plan information
            Map<Id,User> addUserInfo = getAdditionalUserInfo(activeUserIds);

            for(List<Training_Plan_Section_Item__c> sectionItems : tPlanSectionItems.values()){

                for(Training_Plan_Section_Item__c sectionItem : sectionItems){

                    if(sectionItem.Learning__c != null){
                        for(Id userId : activeUserIds){

                            if(!excludedLearnings.containsKey(userId) || (excludedLearnings.containsKey(userId) && !excludedLearnings.get(userId).contains(sectionItem.Learning__c+'_'+sectionItem.Id))){

                                User uInfo = addUserInfo.get(userId);
                                //Add learning to insert map
                                Learning_Assignment__c newLA = new Learning_Assignment__c();
                                newLA.OwnerId = userId;
                                newLA.User__c = userId;
                                newLA.Learning__c = sectionItem.Learning__c;
                                newLA.Learning_Version__c = sectionItem.Learning__r.Current_Published_Version__c;
                                newLA.Training_Plan__c = sectionItem.Training_Plan_Section__r.Training_Plan__c;
                                newLA.Progress__c= LMSConstants.ASSIGNMENT_STATUS_NOT_STARTED;
                                newLA.Progress_Percentage__c = 0;
                                newLA.Training_Plan_Section__c = sectionItem.Training_Plan_Section__c;
                                newLA.Training_Plan_Section_Item__c = sectionItem.Id;
                                newLA.Contact__c = uInfo.ContactId;
                                newLA.Optional__c = sectionItem.Optional__c;
                                if(communityId != null){
                                    newLA.Community_Id__c = communityId;
                                }
                                if(!results.containsKey(userId)){
                                    results.put(userId,new List<Learning_Assignment__c>());
                                }

                                assignmentsToInsert.add(newLA);
                                // Only share the training plan with supported licenses
                                if(uInfo.UserType == 'Standard' || uInfo.UserType == 'CsnOnly'){
                                    newUsersWithAssignments.add(userId);
                                }

                                results.get(userId).add(newLA);
                            }
                        }
                    }
                }
            }
        }

        if(newUsersWithAssignments.size()>0){
            //Share the training and learnings with corresponding users
            wsops.shareTrainingPlanWithUsers(newUsersWithAssignments,new Set<Id>{trainingPlanId});
        }

        // Regular users dont' have permissions to insert these objects, however it's possible that they create assignments
        // for training plans with self-registration enabled. Therefore, we leave CRUD/FLS enforcement to the caller
        // We need to insert these records in without sharing context to prevent insufficient cross reference errors since we don't
        // share the learnings associated to the assignments due to limitations with portal users
        if(assignmentsToInsert.size()>0){
            wsops.insertAssignments(assignmentsToInsert);
        }

        // Update optional flag for assignments where the parent section item or section has changed
        // We need to update these records in without sharing context to prevent insufficient cross reference errors since we don't
        // share the learnings associated to the assignments due to limitations with portal users
        if(updatedOptionalAssignments.size()>0){
            wsops.updateAssignments(updatedOptionalAssignments.values());
        }


        if(planAssignmentsToUpdate.size()>0){
            wsops.updateTrainingPlanAssignments(planAssignmentsToUpdate.values());
        }

        // Create Badge Assignments
        upsertAchievementAssignments(activeUserIds,trainingPlanId);

        return results;
    }

    //Upsert badge assignments for the specified users under the specified training plan Id
    public static Map<Id,List<Achievement_Assignment__c>> upsertAchievementAssignments(Set<Id> userIds, Id trainingPlanId){

        //Ignore inactive users
        Set<Id> activeUserIds = new Set<Id>();
        for(User u : [select id from User where id in :userIds and IsActive = true]){
            activeUserIds.add(u.Id);
        }

        Map<Id,List<Achievement_Assignment__c>> results = new Map<Id,List<Achievement_Assignment__c>>();
        List<Achievement_Assignment__c> aasToInsert = new List<Achievement_Assignment__c>();
        Map<Id,Set<Id>> existingAATrainingPlanBadges = new Map<Id,Set<Id>>();

        LMSService.WithoutSharingOps wsops = new LMSService.WithoutSharingOps();

        //Fetch training plan achievements associated to the specified training plan
        List<Training_Plan_Achievement__c> tPlanAchievements = wsops.getTrainingPlanAchievements(trainingPlanId);
        Map<Id,Training_Plan_Achievement__c> tpasMap = new Map<Id,Training_Plan_Achievement__c>(tPlanAchievements);

        if(tpasMap != null && tpasMap.size()>0){

            //Fetch existing achievement assignments for current users
            for(Achievement_Assignment__c aa : [select id
                                                        ,User__c
                                                        ,Training_Plan_Achievement__c
                                                        ,Achievement__c
                                                from Achievement_Assignment__c
                                                where User__c in :activeUserIds
                                                and Training_Plan_Achievement__c in :tpasMap.keySet()]){
                if(aa.User__c != null){
                    if(!existingAATrainingPlanBadges.containsKey(aa.User__c)){
                        existingAATrainingPlanBadges.put(aa.User__c,new Set<Id>());
                    }
                    existingAATrainingPlanBadges.get(aa.User__c).add(aa.Training_Plan_Achievement__c);
                }
            }

            //Create new AA records
            Id currentNetworkId = LMSUtils.getCurrentNetworkId();

            for(Training_Plan_Achievement__c tpa : tpasMap.values()){

                for(Id uId : activeUserIds){
                    Set<Id> existingUserAAs = existingAATrainingPlanBadges.get(uId);

                    if(existingUserAAs == null || !existingUserAAs.contains(tpa.Id)){
                        Achievement_Assignment__c aa = new Achievement_Assignment__c();
                        aa.User__c = uId;
                        aa.Training_Plan_Achievement__c = tpa.Id;
                        aa.Achievement__c = tpa.Achievement__c;
                        aa.Status__c = LMSConstants.AA_ELIGIBLE_STATUS;
                        aa.OwnerId = uId;
                        if(currentNetworkId != null){
                            aa.Community_Id__c = currentNetworkId;
                        }
                        aasToInsert.add(aa);
                        if(!results.containsKey(uId)){
                            results.put(uId,new List<Achievement_Assignment__c>());
                        }
                        results.get(uId).add(aa);

                    }
                }
            }

            if(aasToInsert.size()>0){
                wsops.insertAchievementAssignments(aasToInsert);
            }

        }

        return results;

    }

    //Return true if the specified training plan is public and if the user has access to this dev plan
    public static Boolean isPublicTrainingPlanAvailable(String trainingPlanId, String userId, Boolean isPortalUser){

        //BEGIN Access Check
        Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
        relatedFieldsObjects.put(Training_Plan__c.sObjectType,new List<String>{
            'Id'
        });
        LMS_ESAPI.isAuthorizedToView(relatedFieldsObjects);
        //END Access Check

        Set<Id> tpIds = new Set<Id>{trainingPlanId};
        String registrationAccess = LMSConstants.TPLAN_PUBLIC_EXTERNAL;

        String soqlQuery = 'select Id from Training_Plan__c where Id in :tpIds';
        soqlQuery += ' and Enable_Self_Registration__c = true and Total_Section_Items__c > 0';

        //Get training plans marked as public, but exclude the ones that are contained in the previous set
        List<Training_Plan__c> tplans = new List<Training_Plan__c> ();

        if(isPortalUser){

            LMSCommunitiesService.WithoutSharingOps commwsops = new LMSCommunitiesService.WithoutSharingOps();
            tpIds = commwsops.filterTrainingPlansForAccount(tpIds,LMSUtils.getUserAccountId());
            if(tpIds.size() == 0){
                soqlQuery += ' and Self_Registration_Access__c = :registrationAccess';
            }

            LMSService.WithoutSharingOps wsops = new LMSService.WithoutSharingOps();
            tplans = wsops.queryTrainingPlans(soqlQuery, tpIds, registrationAccess);
        }else{
            tplans = (List<Training_Plan__c>)Database.query(soqlQuery);
        }

        if(tplans.size()>0){
            return true;
        }else{
            return false;
        }

    }

    //Return a list of all public training plans that are not associated to the current user
    public static List<Training_Plan__c> getTrainingPlansWithItems(String userId,Set<Id> trainingPlanIds, Boolean publicOnly, Boolean isPortalUser){

        //BEGIN Access Check
        Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
        relatedFieldsObjects.put(Training_Plan_Assignment__c.sObjectType,new List<String>{
            'Id'
            ,'Training_Plan__c'
        });
        relatedFieldsObjects.put(Training_Plan__c.sObjectType,new List<String>{
            'Id'
        });
        LMS_ESAPI.isAuthorizedToView(relatedFieldsObjects);
        //END Access Check

        Set<Id> availableTrainingPlans = new Set<Id>();
        String registrationAccess = LMSConstants.TPLAN_PUBLIC_EXTERNAL;

        //Get training plans marked as public, but exclude the ones that are contained in the previous set
        Set<Id> tpIds = trainingPlanIds;
        String soqlQuery = 'select id from Training_Plan__c where Total_Section_Items__c > 0';
        if(publicOnly){
            soqlQuery += ' and Enable_Self_Registration__c = true';
        }

        if(isPortalUser){
            soqlQuery += ' and Self_Registration_Access__c = :registrationAccess';
        }

        if(tpIds != null && tpIds.size()>0){
            soqlQuery+=' and id in :tpIds';
        }

        List<Training_Plan__c> tplans = new List<Training_Plan__c>();
        if(isPortalUser){
            LMSService.WithoutSharingOps wsops = new LMSService.WithoutSharingOps();
            tplans = wsops.queryTrainingPlans(soqlQuery, tpIds, registrationAccess);
        }else{
            tplans = (List<Training_Plan__c>)Database.query(soqlQuery);
        }

        for(Training_Plan__c tp : tplans){
            availableTrainingPlans.add(tp.Id);
        }

        return getTrainingPlans(availableTrainingPlans,isPortalUser);

    }

    //Return a list of training plan access request for the specified user + training plan + statuses
    public static List<Training_Plan_Access_Request__c> fetchTrainingPlanAccessRequest(Id userId, Id tplanId, Set<String> statuses, Boolean isPortalUser){

        //BEGIN Access Check
        Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
        relatedFieldsObjects.put(Training_Plan_Access_Request__c.sObjectType,new List<String>{
            'Id'
            ,'Status__c'
            ,'Comments__c'
        });
        LMS_ESAPI.isAuthorizedToView(relatedFieldsObjects);
        //END Access Check

        List<Training_Plan_Access_Request__c> results;

        //Create local scope vars
        Id uId = userId;
        Id tpId = tplanId;

        List<String> listSOQLFields = new List<String>{
            'Id'
            ,'toLabel(Status__c)'
            ,'Comments__c'
        };

        String soqlQuery = 'select '+String.join(listSOQLFields,',')+' from Training_Plan_Access_Request__c where User__c = :uId and Training_Plan__c = :tplanId';

        if(statuses != null && statuses.size()>0){
            soqlQuery += ' and Status__c in :statuses';
        }
        soqlQuery += ' order by CreatedDate desc';

        if(isPortalUser){
            LMSService.WithoutSharingOps wsops = new LMSService.WithoutSharingOps();
            results = wsops.queryTrainingPlanAccessRequests(soqlQuery,uId,tplanId, statuses);
        }else{
            results = (List<Training_Plan_Access_Request__c>)Database.query(soqlQuery);
        }

        return results;

    }

    //Insert a Training Plan Access Request for the specified user + training plan combination
    public static Training_Plan_Access_Request__c createTrainingPlanAccessRequest(Id userId, Id tplanId,String comments, Boolean isPortalUser){

        //BEGIN Access Check
        Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
        relatedFieldsObjects.put(Training_Plan_Access_Request__c.sObjectType,new List<String>{
            'Training_Plan__c'
            ,'Comments__c'
        });
        LMS_ESAPI.isAuthorizedToCreate(relatedFieldsObjects);
        //END Access Check

        List<Training_Plan_Access_Request__c> existingRequests = fetchTrainingPlanAccessRequest(userId,tplanId,new Set<String>{'Pending'},isPortalUser);

        if(existingRequests.size()>0){
            return existingRequests.get(0);
        }else{
            Training_Plan_Access_Request__c tpar = new Training_Plan_Access_Request__c();
            tpar.User__c = userId;
            tpar.OwnerId = userId;
            tpar.Training_Plan__c = tplanId;
            tpar.Comments__c = comments;
            tpar.Status__c = 'Pending';
            if(isPortalUser){
                LMSService.WithoutSharingOps wsops = new LMSService.WithoutSharingOps();
                wsops.insertTPlanAccessRequest(new List<Training_Plan_Access_Request__c>{tpar});
            }else{
                insert tpar;
            }

            return tpar;
        }

    }

    //Get the latest feedack for the specified user
    public static List<Training_Plan_Feedback__c> getTrainingPlanFeedback(Id userId, Id tPlanId, Boolean ratingOnly){

        //BEGIN Access Check
        Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
        relatedFieldsObjects.put(Training_Plan_Feedback__c.sObjectType,new List<String>{
            'Id'
            ,'Name'
            ,'Rating__c'
            ,'Comments__c'
            ,'User__c'
        });
        LMS_ESAPI.isAuthorizedToView(relatedFieldsObjects);
        //END Access Check

        List<Training_Plan_Feedback__c> results;

        //Create local scope vars
        Id uId = userId;
        Id tpId = tplanId;

        List<String> listSOQLFields = new List<String>{
            'Id'
            ,'Name'
            ,'Rating__c'
            ,'Comments__c'
            ,'User__c'
            ,'User__r.Name'
            ,'User__r.SmallPhotoUrl'

        };

        String soqlQuery = 'select '+String.join(listSOQLFields,',')+' from Training_Plan_Feedback__c where User__c = :uId and Training_Plan__c = :tplanId';

        if(ratingOnly){
            soqlQuery+=' and Rating__c > 0';
        }
        soqlQuery+=' order by CreatedDate desc';

        results = (List<Training_Plan_Feedback__c>)Database.query(soqlQuery);
        return results;

    }

    //Return true if the current user is allowed to view the training plan details and feedback
    public static Boolean isAllowedToViewTrainingPlan(Id tplanId,Id userId, Boolean isPortalUser){

        Boolean result = false;

        if(tplanId != null){

            LMSService.WithoutSharingOps wsops = new LMSService.WithoutSharingOps();
            List<Training_Plan__c> tplans = wsops.queryTrainingPlanAccessLevel(tplanId);

            if(tplans.size()>0){

                Training_Plan__c tplan = tplans.get(0);

                if(tplan.Enable_Self_Registration__c){
                    //This plan is publicly available
                    return true;
                }else{
                    //This is not a publicly availble training plan,
                    //verify the current user has been assigned to this training plan
                    Integer asgmtCount = [select count() from Training_Plan_Assignment__c where User__c = :userId and Training_Plan__c = :tplanId limit 1];
                    if(asgmtCount >0){
                        return true;
                    }
                }
            }
        }

        return result;

    }

    //Insert a training plan feedback record
    public static void insertTrainingPlanFeedback(List<Training_Plan_Feedback__c> feedback){

        //BEGIN Access Check
        List<String> lvFields =  new List<String>{'Rating__c','Comments__c'};
        Map<Schema.sObjectType,List<String>> relatedFieldsObjectsCreate = new Map<Schema.sObjectType,List<String>>();
        relatedFieldsObjectsCreate.put(Training_Plan_Feedback__c.sObjectType,lvFields);

        LMS_ESAPI.isAuthorizedToCreate(relatedFieldsObjectsCreate);
        //END Access Check

        LMSService.WithoutSharingOps wsops = new LMSService.WithoutSharingOps();
        wsops.insertFeedback(feedback);


    }

    //Get a list of learning categories
    public static List<Learning_Category__c> getLearningCategories(String categoryId){

        List<Learning_Category__c> results = new List<Learning_Category__c>();
        String catId = categoryId;

        //BEGIN Access Check
        Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
        relatedFieldsObjects.put(Learning_Category__c.sObjectType,new List<String>{
            'Id'
            ,'Name'
            ,'Background_Image_URL__c'
            ,'Logo__c'
            ,'Text_Color__c'
            ,'Hide_From_Catalog_Home__c'
            ,'Order__c'
            ,'Is_Internal__c'
        });
        LMS_ESAPI.isAuthorizedToView(relatedFieldsObjects);
        //END Access Check

        List<String> listSOQLFields = new List<String>{
            'Id'
            ,'Name'
            ,'Background_Image_URL__c'
            ,'Logo__c'
            ,'Text_Color__c'
            ,'Total_Training_Plans__c'
            ,'Hide_From_Catalog_Home__c'
            ,'Order__c'
            ,'Is_Internal__c'
        };

        String soqlQuery = 'select '+String.join(listSOQLFields,',')+' from Learning_Category__c';
        if(catId != null){
            soqlQuery+= ' where id = :catId';
        }else{
            soqlQuery+= ' where Total_Training_Plans__c > 0 and Hide_From_Catalog_Home__c = false';
        }

        if(LMSUtils.isPortalUser() || LMSUtils.getCurrentNetworkId() != null){
            soqlQuery+= ' and Is_Internal__c = false';
        }

        soqlQuery+= ' order by Order__c asc NULLS LAST';

        results = (List<Learning_Category__c>)Database.query(soqlQuery);
        return results;

    }

    //Return training trackas based on status
    public static List<Training_Track__c> getTrainingTracks(String status, String trackFilter, Boolean isPortalUser){

        List<Training_Track__c> results = new List<Training_Track__c>();
        String filterStatus = String.isBlank(status)?'Active':status;
        Set<Id> trIds = new Set<Id>();

        //BEGIN Access Check
        Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
        relatedFieldsObjects.put(Training_Track__c.sObjectType,new List<String>{
            'Id'
            ,'Name'
            ,'Background_Color__c'
            ,'Background_Image_URL__c'
            ,'Description__c'
            ,'Text_Color__c'
            ,'Status__c'
        });
        relatedFieldsObjects.put(Achievement__c.sObjectType,new List<String>{
            'Acquired_Image__c'
            ,'Eligible_Image__c'
            ,'Work_Badge_Id__c'
            ,'Work_Badge_Image_URL__c'
        });
        LMS_ESAPI.isAuthorizedToView(relatedFieldsObjects);
        //END Access Check

        List<String> listSOQLFields = new List<String>{
            'Id'
            ,'Name'
            ,'Background_Color__c'
            ,'Background_Image_URL__c'
            ,'Description__c'
            ,'Text_Color__c'
            ,'Status__c'
            ,'Achievement__c'
            ,'Achievement__r.Acquired_Image__c'
            ,'Achievement__r.Eligible_Image__c'
            ,'Achievement__r.Work_Badge_Id__c'
            ,'Achievement__r.Work_Badge_Image_URL__c'
        };

        String soqlQuery = 'select '+String.join(listSOQLFields,',')+' from Training_Track__c where Status__c = :filterStatus';

        if(trackFilter != 'All'){
            if(isPortalUser){
                LMSCommunitiesService.WithoutSharingOps commwsops = new LMSCommunitiesService.WithoutSharingOps();
                trIds = commwsops.filterTrainingTracksForAccount(new Set<Id>{trackFilter},LMSUtils.getUserAccountId(), filterStatus);
                if(trIds.size() == 0){
                    return results;
                }
            }else{
                trIds = new Set<Id>{trackFilter};
            }
            soqlQuery +=' and id in :trIds';
        }else{
            if(isPortalUser){
                LMSCommunitiesService.WithoutSharingOps commwsops = new LMSCommunitiesService.WithoutSharingOps();
                trIds = commwsops.getAccountTrainingTracks(LMSUtils.getUserAccountId());
                soqlQuery +=' and (Enable_all_external_accounts__c = true or Id in :trIds)';
            }
        }

        soqlQuery+=' order by Order__c asc NULLS LAST';

        if(isPortalUser){
            LMSService.WithoutSharingOps wsops = new LMSService.WithoutSharingOps();
            results = wsops.queryTrainingTracks(soqlQuery,filterStatus,trIds);
        }else{
            results = (List<Training_Track__c>)Database.query(soqlQuery);
        }

        return results;

    }

    //Return a list of list of triaining track items grouped by level
    public static List<Training_Track_Level__c> getTrainingTrackLevels(String trackId, Boolean isPortalUser){

        List<Training_Track_Level__c> results = new List<Training_Track_Level__c>();

        //BEGIN Access Check
        Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
        relatedFieldsObjects.put(Training_Track_Level__c.sObjectType,new List<String>{
            'Id'
            ,'Name'
            ,'Order__c'
            ,'Description__c'
        });
        relatedFieldsObjects.put(Training_Track_Level_Item__c.sObjectType,new List<String>{
            'Id'
            ,'Name'
            ,'Training_Plan__c'
        });
        relatedFieldsObjects.put(Training_Plan__c.sObjectType,new List<String>{
            'Name'
            ,'Description__c'
            ,'Enable_Self_Registration__c'
            ,'Self_Registration_Access__c'
            ,'Status__c'
            ,'Start_Date__c'
            ,'End_Date__c'
            ,'Background_Image_URL__c'
            ,'Intro_Video_URL__c'
            ,'Background_Color__c'
            ,'Text_Color__c'
        });
        LMS_ESAPI.isAuthorizedToView(relatedFieldsObjects);
        //END Access Check

        List<String> listLevelSOQLFields = new List<String>{
            'Id'
            ,'Name'
            ,'Order__c'
            ,'Description__c'
            ,'Training_Track__c'
        };

        List<String> listItemSOQLFields = new List<String>{
            'Id'
            ,'Name'
            ,'Training_Plan__c'
            ,'Training_Track_Level__c'
            ,'Training_Plan__r.Name'
            ,'Training_Plan__r.Description__c'
            ,'Training_Plan__r.Status__c'
            ,'Training_Plan__r.Start_Date__c'
            ,'Training_Plan__r.End_Date__c'
            ,'Training_Plan__r.Background_Image_URL__c'
            ,'Training_Plan__r.Intro_Video_URL__c'
            ,'Training_Plan__r.Background_Color__c'
            ,'Training_Plan__r.Text_Color__c'
            ,'Training_Plan__r.Enable_Self_Registration__c'
            ,'Training_Plan__r.Self_Registration_Access__c'
        };

        Id trId = trackId;

        String soqlQuery = 'select '+String.join(listLevelSOQLFields,',')+',(select '+String.join(listItemSOQLFields,',')+' from Training_Track_Level_Items__r order by Order__c asc) from Training_Track_Level__c where Training_Track__c = :trId';
        soqlQuery+=' order by Order__c asc';

        if(isPortalUser){
            LMSCommunitiesService.WithoutSharingOps commwsops = new LMSCommunitiesService.WithoutSharingOps();
            Set<Id> trIds = commwsops.filterTrainingTracksForAccount(new Set<Id>{trackId},LMSUtils.getUserAccountId(), null);
            if(trIds.size()>0){
                LMSService.WithoutSharingOps wsops = new LMSService.WithoutSharingOps();
                results = wsops.queryTrainingTrackLevels(soqlQuery,trId);
            }
        }else{
            results = (List<Training_Track_Level__c>)Database.query(soqlQuery);
        }

        return results;

    }

    //Fetch resource assignment information, learnings won't be shared with end-users so we need to by-pass sharing rules
    public static Learning_Assignment__c getLearningAssignmentDetails(String assignmentId, Id userId){
        //BEGIN Access Check
        Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
        relatedFieldsObjects.put(Learning_Assignment__c.sObjectType,new List<String>{
            'Id'
            ,'Name'
            ,'User__c'
            ,'Learning__c'
            ,'Progress__c'
            ,'Training_Plan__c'
            ,'Shared_Learning_Assignment__c'
        });
        LMS_ESAPI.isAuthorizedToView(relatedFieldsObjects);
        //END Access Check

        Learning_Assignment__c assignment = [select id
                                                  ,User__c
                                                  ,Contact__c
                                                  ,Name
                                                  ,Learning__c
                                                  ,Learning_Version__c
                                                  ,Progress__c
                                                  ,Progress_Percentage__c
                                                  ,Evaluation_Result__c
                                                  ,Evaluation_Score__c
                                                  ,Evaluation_Times_Taken__c
                                                  ,Training_Plan__c
                                                  ,Training_Plan_Section__c
                                                  ,Shared_Learning_Assignment__c
                                                  ,Approver_Notes__c
                                                  from Learning_Assignment__c
                                                  where id = :assignmentId
                                                  and User__c = :userId
                                                  limit 1];
          return assignment;
    }

    //Without sharing operations
    public without sharing class WithoutSharingOps{

        //Needs to run without sharing otherwise we get field not writable exceptions
        //Create sharing entries for the specifies users + training plans
        public void shareTrainingPlanWithUsers(Set<Id> userIds, Set<Id> trainingPlanIds){
            List<Training_Plan__Share> results = new List<Training_Plan__Share>();
            for(Id tPlanId : trainingPlanIds){
                for(Id uId : userIds){
                    Training_Plan__Share tPlanShare = new Training_Plan__Share();
                    tPlanShare.UserOrGroupId = uId;
                    tPlanShare.ParentId = tPlanId;
                    tPlanShare.AccessLevel = 'read';
                    tPlanShare.RowCause = Schema.Training_Plan__Share.RowCause.LMS_Sharing__c;
                    results.add(tPlanShare);
                }
            }

            if(results.size()>0){
                insert results;
            }
        }

        //Needs to run without sharing otherwise we get field not writable exceptions
        //Create sharing entries for the specifies users + learnings
        public void shareLearningsWithApprovers(Map<Id,Set<Id>> learningsUserSharing){
            List<Learning__Share> results = new List<Learning__Share>();
            //Iterate over learnings and create apex sharing for the corresponding users
            for(Id learningId : learningsUserSharing.keySet()){
                for(Id uId : learningsUserSharing.get(learningId)){
                    Learning__Share learningShare = new Learning__Share();
                    learningShare.UserOrGroupId = uId;
                    learningShare.ParentId = learningId;
                    learningShare.AccessLevel = 'read';
                    learningShare.RowCause = Schema.Learning__Share.RowCause.LMS_Approval_Sharing__c;
                    results.add(learningShare);
                }
            }
            if(results.size()>0){
                insert results;
            }
        }

        //Needs to run without sharing otherwise we get field not writable exceptionss
        //Share the specified learning with the corresponding approvers
        public void shareLearningAssignmentsWithApprovers(Set<Id> approverIds, Set<Id> learningAssignmentIds){

            if(approverIds.size()>0 && learningAssignmentIds.size()>0){

                List<Learning_Assignment__Share> sharingRecords = new List<Learning_Assignment__Share>();

                for(Id learningAssignmentId : learningAssignmentIds){
                    for(Id approverId : approverIds){
                        Learning_Assignment__Share laShare = new Learning_Assignment__Share();
                        laShare.UserOrGroupId = approverId;
                        laShare.ParentId = learningAssignmentId;
                        laShare.AccessLevel = 'edit';
                        laShare.RowCause = Schema.Learning_Assignment__Share.RowCause.LMS_Approval_Sharing__c;
                        sharingRecords.add(laShare);
                    }
                }

                //By-passing CRUD/FLS checks here as user's trigger this operation and they don't have access to create share records
                if(sharingRecords.size()>0){
                    insert sharingRecords;
                }

                //Make sure that the approvers also have access to the learnings
                Set<Id> learningIds = new Set<Id>();
                List<Learning_Assignment__c> assignments = [select id
                                                                    ,Learning__c
                                                                    from Learning_Assignment__c
                                                                    where id in :learningAssignmentIds];
                for(Learning_Assignment__c la : assignments){
                    if(la.Learning__c != null){
                        learningIds.add(la.Learning__c);
                    }
                }

                if(learningIds.size()>0){

                    Map<Id,Set<Id>> learningsUserSharing = new Map<Id,Set<Id>>();

                    for(Id lid : learningIds){
                        for(Id approverId : approverIds){
                            if(!learningsUserSharing.containsKey(lid)){
                                learningsUserSharing.put(lid,new Set<Id>{approverId});
                            }else{
                                learningsUserSharing.get(lid).add(approverId);
                            }
                        }
                    }

                    if(learningsUserSharing.size()>0){
                        shareLearningsWithApprovers(learningsUserSharing);
                    }

                }

            }

        }

        /*
        * We're running this query without sharing due to our data model design
        * We need to fetch data from learnings that still haven't been shared with the user. If we run this query with sharing
        * we won't get all the necessary data used to create the corresponding assignment records
        */
        //Return a map of training plan section items for the specified training plan section ids
        public Map<Id,List<Training_Plan_Section_Item__c>> getTrainingPlanSectionItems(Set<Id> trainingPlanSectionIds){

            //BEGIN Access Check
            Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
            relatedFieldsObjects.put(Training_Plan_Section_Item__c.sObjectType,new List<String>{
                'Id'
                ,'Name'
                ,'Training_Plan_Section__c'
                ,'Order__c'
                ,'Optional__c'
                ,'Duration__c'
                ,'Duration_hours__c'
                ,'Learning__c'
            });
            relatedFieldsObjects.put(Learning__c.sObjectType,new List<String>{
                'Name'
                ,'Description__c'
                ,'Custom_Preview_URL__c'
                ,'Sync_progress__c'
                ,'Current_Published_Version__c'
            });
            relatedFieldsObjects.put(Learning_Version__c.sObjectType,new List<String>{
                'Version__c'
                ,'Learning_Content_ID__c'
                ,'Version_selection_behavior__c'
            });
            LMS_ESAPI.isAuthorizedToView(relatedFieldsObjects);
            //END Access Check

            Map<Id,List<Training_Plan_Section_Item__c>> results = new Map<Id,List<Training_Plan_Section_Item__c>>();

            //Create local scope vars for Dynamic SOQL binding
            Set<Id> tpsIds = trainingPlanSectionIds;

            List<String> listSOQLFields = new List<String>{
                'Id'
                ,'Name'
                ,'Training_Plan_Section__c'
                ,'Order__c'
                ,'Optional__c'
                ,'Duration__c'
                ,'Duration_hours__c'
                ,'Learning__c'
                ,'Learning__r.Name'
                ,'Learning__r.Description__c'
                ,'Learning__r.RecordType.DeveloperName'
                ,'Learning__r.Custom_Preview_URL__c'
                ,'Learning__r.Sync_progress__c'
                ,'Learning__r.Current_Published_Version__c'
                ,'Learning__r.Current_Published_Version__r.Version__c'
                ,'Learning__r.Current_Published_Version__r.Learning_Content_ID__c'
                ,'Learning__r.Current_Published_Version__r.Version_selection_behavior__c'
            };

            String soqlQuery = 'select '+String.join(listSOQLFields,',')+' from Training_Plan_Section_Item__c where Training_Plan_Section__c in :tpsIds';
            soqlQuery += ' order by Order__c asc,CreatedDate desc';

            List<Training_Plan_Section_Item__c> sectionItems = (List<Training_Plan_Section_Item__c>)Database.query(soqlQuery);

            for(Training_Plan_Section_Item__c tpSectionItem : sectionItems){

                if(!results.containsKey(tpSectionItem.Training_Plan_Section__c)){
                    results.put(tpSectionItem.Training_Plan_Section__c, new List<Training_Plan_Section_Item__c>());
                }
                results.get(tpSectionItem.Training_Plan_Section__c).add(tpSectionItem);
            }

            return results;
        }

        /*
        * We're running this query without sharing due to our data model design
        * We need to fetch data from learnings that still haven't been shared with the user. If we run this query with sharing
        * we won't get all the necessary data used to create the corresponding assignment records
        */
        //Return a list of training plan section items for the specified training plan Ids
        public Map<Id,List<Training_Plan_Section_Item__c>> getTrainingPlanSectionItemsFromTrainingPlans(Set<Id> trainingPlanIds){

            //BEGIN Access Check
            Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
            relatedFieldsObjects.put(Training_Plan_Section_Item__c.sObjectType,new List<String>{
                'Id'
                ,'Name'
                ,'Training_Plan_Section__c'
                ,'Order__c'
                ,'Duration__c'
                ,'Learning__c'
                ,'Optional__c'
            });
            relatedFieldsObjects.put(Training_Plan_Section__c.sObjectType,new List<String>{
                'Training_Plan__c'
                ,'Optional__c'
            });
            relatedFieldsObjects.put(Learning__c.sObjectType,new List<String>{
                'Name'
                ,'Description__c'
                ,'Custom_Preview_URL__c'
                ,'Sync_progress__c'
                ,'Current_Published_Version__c'
            });
            relatedFieldsObjects.put(Learning_Version__c.sObjectType,new List<String>{
                'Version__c'
                ,'Learning_Content_ID__c'
            });
            LMS_ESAPI.isAuthorizedToView(relatedFieldsObjects);
            //END Access Check

            Map<Id,List<Training_Plan_Section_Item__c>> results = new Map<Id,List<Training_Plan_Section_Item__c>>();

            //Create local scope vars for Dynamic SOQL binding
            Set<Id> tpIds = trainingPlanIds;

            List<String> listSOQLFields = new List<String>{
                'Id'
                ,'Name'
                ,'Training_Plan_Section__c'
                ,'Training_Plan_Section__r.Training_Plan__c'
                ,'Training_Plan_Section__r.Optional__c'
                ,'Order__c'
                ,'Duration__c'
                ,'Optional__c'
                ,'Learning__c'
                ,'Learning__r.Name'
                ,'Learning__r.Description__c'
                ,'Learning__r.RecordType.DeveloperName'
                ,'Learning__r.Sync_progress__c'
                ,'Learning__r.Current_Published_Version__c'
                ,'Learning__r.Current_Published_Version__r.Version__c'
                ,'Learning__r.Current_Published_Version__r.Learning_Content_ID__c'
            };

            String soqlQuery = 'select '+String.join(listSOQLFields,',')+' from Training_Plan_Section_Item__c where Training_Plan_Section__r.Training_Plan__c in :tpIds';
            soqlQuery += ' order by Training_Plan_Section__c desc';

            List<Training_Plan_Section_Item__c> sectionItems = (List<Training_Plan_Section_Item__c>)Database.query(soqlQuery);

            for(Training_Plan_Section_Item__c tpSectionItem : sectionItems){
                if(!results.containsKey(tpSectionItem.Training_Plan_Section__r.Training_Plan__c)){
                    results.put(tpSectionItem.Training_Plan_Section__r.Training_Plan__c, new List<Training_Plan_Section_Item__c>());
                }
                results.get(tpSectionItem.Training_Plan_Section__r.Training_Plan__c).add(tpSectionItem);
            }

            return results;
        }

        public Map<Id,Set<Id>> getTrainingPlanLearningIds(Set<Id> trainingPlanIds){

            //BEGIN Access Check
            Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
            relatedFieldsObjects.put(Training_Plan_Section_Item__c.sObjectType,new List<String>{
                'Id'
                ,'Name'
                ,'Learning__c'
                ,'Training_Plan_Section__c'
            });
            relatedFieldsObjects.put(Learning__c.sObjectType,new List<String>{
                'Id'
                ,'Name'
            });
            relatedFieldsObjects.put(Training_Plan_Section__c.sObjectType,new List<String>{
                'Training_Plan__c'
            });
            LMS_ESAPI.isAuthorizedToView(relatedFieldsObjects);
            //END Access Check

            Map<Id,Set<Id>> results = new Map<Id,Set<Id>>();

            //Create local scope vars for Dynamic SOQL binding
            Set<Id> tpIds = trainingPlanIds;

            List<String> listSOQLFields = new List<String>{
                'Id'
                ,'Name'
                ,'Learning__c'
                ,'Training_Plan_Section__r.Training_Plan__c'
            };

            String soqlQuery = 'select '+String.join(listSOQLFields,',')+' from Training_Plan_Section_Item__c where Training_Plan_Section__r.Training_Plan__c in :tpIds';
            soqlQuery += ' order by CreatedDate desc';

            List<Training_Plan_Section_Item__c> items = (List<Training_Plan_Section_Item__c>)Database.query(soqlQuery);

            for(Training_Plan_Section_Item__c i : items){

                if(!results.containsKey(i.Training_Plan_Section__r.Training_Plan__c)){
                    results.put(i.Training_Plan_Section__r.Training_Plan__c, new Set<Id>());
                }

                if(i.Learning__c != null){
                    results.get(i.Training_Plan_Section__r.Training_Plan__c).add(i.Learning__c);
                }
            }

            return results;
        }

        /*
        * We're running this query without sharing due to our data model design
        * answer sequence is not a child of question, this is due to the limit of max M-D relations has already been reached
        * instead, question has a lookup field to answer sequence and we don't want to create sharing for these records
        * additionally, we dont want end-users to be looking at the answer options through any other entry points so
        * giving "view-all" access is also not acceptable
        */
        //Fetch the list of sequences for the specified questions
        public Map<Id,Answer_Sequence__c> fetchAnswerSequences(Set<Id> answerQuestionIds){

            //BEGIN Access Check
            Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
            relatedFieldsObjects.put(Answer_Sequence__c.sObjectType,new List<String>{
                'Id'
                ,'Name'
            });
            relatedFieldsObjects.put(Answer_Sequence_Item__c.sObjectType,new List<String>{
                'Id'
                ,'Name'
                ,'Answer_Sequence__c'
                ,'Item_Id__c'
            });
            //NOTE: We know users don't have access to see the "Is Correct Answer" field so we're excluding it from the FLS check
            //This field should only be used at the controller level to validate answer
            LMS_ESAPI.isAuthorizedToView(relatedFieldsObjects);
            //END Access Check

            if(answerQuestionIds != null && answerQuestionIds.size()>0){
                Map<id,Answer_Sequence__c> resultsMap = new map<id,Answer_Sequence__c>(
                        [Select Id
                                ,Name
                                ,(select Id
                                        ,Name
                                        ,Answer_Sequence__c
                                        ,Answer_Text__c
                                        ,Item_Id__c
                                        ,Is_Correct_Answer__c
                                        from Answer_Sequence_Items__r order by Order__c asc)
                                from Answer_Sequence__c
                                where id in :answerQuestionIds ]);

                return resultsMap;
            }else{
                return new Map<Id,Answer_Sequence__c>();
            }
        }

        //Get a list of the task approvers for a specific task.
        //No CRUD/FLS is applied here as end-users shouldn't have access to this object
        public List<Task_Approver__c> getTaskApprovers(Id taskId){
            List<Task_Approver__c>  results =  [select id
                                                        ,User__c
                                                        ,User__r.IsActive
                                                        ,Task__c
                                                    from Task_Approver__c
                                                    where Task__c = :taskId];
            return results;
        }


        public List<Question_Line__c> getQuizQuestionLines(Id quizId){

            //BEGIN Access Check
            Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
            relatedFieldsObjects.put(Question_Line__c.sObjectType,new List<String>{
                'Id'
                ,'Name'
                ,'Order__c'
                ,'Description__c'
            });
            LMS_ESAPI.isAuthorizedToView(relatedFieldsObjects);
            //END Access Check

            List<Question_Line__c> results = new List<Question_Line__c>();

            results = [select id
                            ,Name
                            ,Order__c
                            ,Description__c
                            from Question_Line__c
                            where Quiz__c = :quizId
                            order by Order__c asc,CreatedDate asc];

            return results;

        }

        public List<Question_Line__c> getQuizOrderedQuestionLines(Id quizId, Id questionLineId, Decimal questionLineOrder){

            //BEGIN Access Check
            Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
            relatedFieldsObjects.put(Question_Line__c.sObjectType,new List<String>{
                'Id'
                ,'Name'
                ,'Order__c'
                ,'Quiz__c'
            });
            LMS_ESAPI.isAuthorizedToView(relatedFieldsObjects);
            //END Access Check

            List<Question_Line__c> results = new List<Question_Line__c>();

            results = [select id
                            ,Name
                            ,Order__c
                            ,Quiz__c
                            from Question_Line__c
                            where Order__c >= :questionLineOrder
                            and Quiz__c = :quizId
                            and id != :questionLineId
                            order by order__c asc,CreatedDate asc];

            return results;

        }

        public Question_Line__c getQuestionLineDetails(Id quizId, Id questionLineId){
            //BEGIN Access Check
            Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
            relatedFieldsObjects.put(Question_Line__c.sObjectType,new List<String>{
                'Id'
                ,'Name'
                ,'Order__c'
                ,'Description__c'
            });
            LMS_ESAPI.isAuthorizedToView(relatedFieldsObjects);
            //END Access Check

            //Retrieve question line information
            Question_Line__c questionLine = [select Id
                                                    ,Name
                                                    ,Quiz__c
                                                    ,Quiz__r.Name
                                                    ,Order__c
                                                    ,Description__c
                                                    from Question_Line__c
                                                    where id =:questionLineId
                                                    and Quiz__c = :quizId limit 1];
            return questionLine;
        }

        public List<Question__c> getQuestionsForQuestionLine(Id questionLineId){

            //BEGIN Access Check
            Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
            relatedFieldsObjects.put(Question__c.sObjectType,new List<String>{
                'Id'
                ,'Name'
                ,'Description_RTA__c'
                ,'Description__c'
                ,'Type__c'
            });
            LMS_ESAPI.isAuthorizedToView(relatedFieldsObjects);
            //END Access Check

            List<Question__c> results = new List<Question__c>();

            results = [select id
                            ,Name
                            ,Answer_Sequence__c
                            ,Description__c
                            ,Description_RTA__c
                            ,Type__c
                            from Question__c
                            where Question_Line__c = :questionLineId
                            order by Order__c asc,CreatedDate asc];

            return results;
        }

        //Fetch all questions for the specified quiz
        public Map<Id,Question__c> getQuestionsForQuiz(Id quizId){

            //BEGIN Access Check
            Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
            relatedFieldsObjects.put(Question__c.sObjectType,new List<String>{
                'Id'
                ,'Name'
                ,'Type__c'
            });
            LMS_ESAPI.isAuthorizedToView(relatedFieldsObjects);
            //END Access Check

            Map<Id,Question__c> results = new Map<Id,Question__c>();
            for(Question__c q : [select id
                                        ,Answer_Sequence__c
                                        ,Correct_Boolean__c
                                        ,Correct_Number__c
                                        ,Type__c
                                        from Question__c
                                        where Question_Line__r.Quiz__c = :quizId]){
                results.put(q.Id,q);
            }

            return results;
        }

        //Retrieve existing responses for a Quiz assignment
        public List<Response__c> getQuizResponses(Id quizId, Id questionLineId, Id assignmentId, Id sharedAssignmentId){

            //Local vars for dynamic binding
            Id aid = assignmentId;
            Id qlid = questionLineId;
            Id qid = quizId;
            Id said = sharedAssignmentId;

            //BEGIN Access Check
            Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
            relatedFieldsObjects.put(Response__c.sObjectType,new List<String>{
                'Id'
                ,'Name'
                ,'Question__c'
                ,'Question_Type__c'
                ,'User__c'
                ,'Number_Response__c'
                ,'Boolean_Response__c'
                ,'Response_Answer_Sequence_Long__c'
                ,'Response_Answer_Sequence_Label__c'
                ,'Response_Text_Long__c'
                });
            LMS_ESAPI.isAuthorizedToView(relatedFieldsObjects);
            //END Access Check

            List<String> listSOQLFields = new List<String>{
                'Id'
                ,'Name'
                ,'Number_Response__c'
                ,'Boolean_Response__c'
                ,'Question__c'
                ,'Question_Type__c'
                ,'Question__r.Question_Line__c'
                ,'Response_Answer_Sequence_Long__c'
                ,'Response_Answer_Sequence_Label__c'
                ,'Response_Text_Long__c'
                ,'User__c'
                ,'Contact__c'
                ,'Correct_Response__c'
            };

            String soqlQuery = 'select '+String.join(listSOQLFields,',')+' from Response__c where';

            if(said != null){
                soqlQuery+= ' Shared_Learning_Assignment__c = :said';
            }else{
                soqlQuery+= ' Learning_Assignment__c = :aid';
            }

            if(qid != null){
                soqlQuery += ' and Question__r.Question_Line__r.Quiz__c = :qid';
            }else{
                soqlQuery += ' and Question__r.Question_Line__c = :qlid';
            }

            List<Response__c> responses = (List<Response__c>)Database.query(soqlQuery);
            return responses;
        }

        // Upsert responses, this has to be done in a WOS as the response has reference to Quiz objects that are not visible to the learner
        public void upsertResponses(List<Response__c> tosave){

            //BEGIN Access Check
            Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
            relatedFieldsObjects.put(Response__c.sObjectType,new List<String>{
                'Response_Answer_Sequence_Long__c'
                ,'Response_Answer_Sequence_Label__c'
                ,'Number_Response__c'
                ,'Response_Text_Long__c'
                ,'Boolean_Response__c'
                });
            LMS_ESAPI.isAuthorizedToUpdate(relatedFieldsObjects);
            //END Access Check

            upsert tosave;
        }

        //Get the total number of response count for a specific quiz assignment
        public Integer getAssignmentResponseCount(Id assignmentId, Id quizId){
            Integer respCount = [select count()
                                        from Response__c
                                        where Learning_Assignment__c = :assignmentId
                                        and Question__r.Question_Line__r.Quiz__c = :quizId];
            return respCount;
        }

        //Insert assignments
        public void insertAssignments(List<Learning_Assignment__c> assignments){
            insert assignments;
        }

        //Update assignments
        public void updateAssignments(List<Learning_Assignment__c> assignments){
            update assignments;
        }

        //Update training plan assignments
        public void updateTrainingPlanAssignments(List<Training_Plan_Assignment__c> assignments){
            update assignments;
        }

        public void insertAchievementAssignments(List<Achievement_Assignment__c> achievementAssignments){
            insert achievementAssignments;
        }

        public List<Training_Plan_Achievement__c> getTrainingPlanAchievements(Id trainingPlanId){
            List<Training_Plan_Achievement__c>  results = [select id
                                                                ,Type__c
                                                                ,Training_Plan__c
                                                                ,Achievement__c
                                                                from Training_Plan_Achievement__c
                                                                where Training_Plan__c = :trainingPlanId];
            return results;
        }

        //Query training Plans
        public List<Training_Plan__c> queryTrainingPlans(String soqlQuery,Set<Id> tpIds, String registrationAccess){
            return (List<Training_Plan__c>)Database.query(soqlQuery);
        }

        //Query training plan achievements
        public List<Training_Plan_Achievement__c> queryTrainingPlanAchievements(String soqlQuery, Set<Id> tplIds, String tpaType){
            return (List<Training_Plan_Achievement__c>)Database.query(soqlQuery);
        }

        //Query training plan section achievements
        public List<Training_Plan_Achievement__c> queryTrainingPlanSectionAchievements(String soqlQuery, Set<Id> tpsIds, String tpaType){
            return (List<Training_Plan_Achievement__c>)Database.query(soqlQuery);
        }

        public List<Training_Plan_Section__c> queryTrainingPlanSections(String soqlQuery,Set<Id> tpIds){
            return (List<Training_Plan_Section__c>)Database.query(soqlQuery);
        }

        public List<Training_Plan__c> queryTrainingPlanAccessLevel(Id tplanId){
            return [select id,Enable_Self_Registration__c,Self_Registration_Access__c from Training_Plan__c where id = :tplanId];
        }

        public List<Training_Plan_Access_Request__c> queryTrainingPlanAccessRequests(String soqlQuery,Id uId,Id tplanId,Set<String> statuses){
            return (List<Training_Plan_Access_Request__c>)Database.query(soqlQuery);
        }

        //Return a map of assignments for the specified learnings + user ids
        public Map<Id,Learning_Version__c> getLearningVersionDetails(Set<Id> learningIds){

            //BEGIN Access Check
            Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
            relatedFieldsObjects.put(Learning_Version__c.sObjectType,new List<String>{
              'Version__c'
              ,'Learning_Content_ID__c'
            });
            LMS_ESAPI.isAuthorizedToView(relatedFieldsObjects);
            //END Access Check

            Map<Id,Learning_Version__c> results = new Map<Id,Learning_Version__c>();

            List<String> listSOQLFields = new List<String>{
              'Id'
              ,'Version__c'
              ,'Learning_Content_ID__c'
            };

            Set<Id> lIds = learningIds;

            String soqlQuery = 'select '+String.join(listSOQLFields,',')+' from Learning_Version__c where Learning__c in :lIds';
            List<Learning_Version__c> versions = (List<Learning_Version__c>)Database.query(soqlQuery);
            for(Learning_Version__c lv : versions){
                results.put(lv.Id,lv);
            }

            return results;
        }

        //Fetch learning version information, learnings won't be shared with end-users so we need to by-pass sharing rules
        public Learning_Version__c getLearningVersionDetails(Id learningVersionId, String learningType){
            //BEGIN Access Check
            Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
            relatedFieldsObjects.put(Learning_Version__c.sObjectType,new List<String>{
              'Id'
              ,'Training_Resource__c'
              ,'Task__c'
              ,'Quiz__c'
            });
            LMS_ESAPI.isAuthorizedToView(relatedFieldsObjects);
            //END Access Check

            Learning_Version__c learningVersion = null;

            if(learningType == 'Resource'){
                learningVersion = [select id
                                        ,Training_Resource__c
                                        ,Training_Resource__r.Id
                                        ,Training_Resource__r.Name
                                        ,Training_Resource__r.Resource_URL__c
                                        ,Training_Resource__r.Add_training_parameters_to_URL__c
                                        ,Training_Resource__r.Prevent_completion_on_launch__c
                                        from Learning_Version__c
                                        where id = :learningVersionId
                                        limit 1];
            }else if(learningType == 'Task'){
                learningVersion = [select id
                                        ,Task__c
                                        ,Task__r.Id
                                        ,Task__r.Name
                                        ,Task__r.External_Resource_Target__c
                                        ,Task__r.External_Resource_URL__c
                                        ,Task__r.External_Resource_Name__c
                                        ,Task__r.Description__c
                                        ,Task__r.Description_RTA__c
                                        ,Task__r.Add_training_parameters_to_URL__c
                                        ,Task__r.Requires_Manager_Approval__c
                                        ,Task__r.Enable_Image_Upload__c
                                        ,Task__r.Disable_Undo__c
                                        from Learning_Version__c
                                        where id = :learningVersionId
                                        limit 1];
            }else if(learningType == 'Quiz'){
                learningVersion = [select id
                                        ,Quiz__c
                                        ,Quiz__r.Id
                                        ,Quiz__r.Name
                                        ,Quiz__r.Description__c
                                        ,Quiz__r.Passing_Score__c
                                        ,Quiz__r.Total_Questions__c
                                        ,Quiz__r.Max_Attempts__c
                                        from Learning_Version__c
                                        where id = :learningVersionId
                                        limit 1];
            }else{

            }

            return learningVersion;
        }

        //Fetch learning information, learnings won't be shared with end-users so we need to by-pass sharing rules
        public Learning__c getLearningDetails(Id learningId){
            //BEGIN Access Check
            Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
            relatedFieldsObjects.put(Learning__c.sObjectType,new List<String>{
                'Id'
                ,'Name'
                ,'Description__c'
                ,'Current_Published_Version__c'
            });
            LMS_ESAPI.isAuthorizedToView(relatedFieldsObjects);
            //END Access Check

            Learning__c learning = [select id
                                            ,Name
                                            ,Description__c
                                            ,Current_Published_Version__r.Training_Resource__r.Display_in_Iframe__c
                                            ,Current_Published_Version__r.Training_Resource__r.Resource_URL__c
                                            from Learning__c
                                            where id = :learningId];
            return learning;
        }

        public List<Training_Track__c> queryTrainingTracks(String soqlQuery, String filterStatus, Set<Id> trIds){
            return (List<Training_Track__c>)Database.query(soqlQuery);
        }

        public List<Training_Track_Level__c> queryTrainingTrackLevels(String soqlQuery, Id trId){
            return (List<Training_Track_Level__c>)Database.query(soqlQuery);
        }

        public Map<Id,Training_Plan_Achievement__c> getTrainingPlanAchievementDetails(Set<Id> tplanAchievementIds){
            Map<Id,Training_Plan_Achievement__c> results = new Map<Id,Training_Plan_Achievement__c>();
            for(Training_Plan_Achievement__c tpa : [select id
                                                          ,Training_Plan__c
                                                          ,Training_Plan_Section__c
                                                          from Training_Plan_Achievement__c
                                                          where id in :tplanAchievementIds]){
                results.put(tpa.Id,tpa);

            }
            return results;
        }

        //Insert feedback records
        public void insertFeedback(List<Training_Plan_Feedback__c> feedbacks){
            insert feedbacks;
        }

        //Insert training plan access records
        public void insertTPlanAccessRequest(List<Training_Plan_Access_Request__c> tplanRequests){
            insert tplanRequests;
        }

        //Check if the current user has previous incomplete sections
        public Boolean hasIncompleteTPlanSectionAssignments(Set<Id> tPlanSectionIds, Id userId){
            List<Training_Plan_Section_Assignment__c> tpsas = [select Status__c
                                                                    from Training_Plan_Section_Assignment__c
                                                                    where Training_Plan_Section__c in :tPlanSectionIds
                                                                    and User__c = :userId
                                                                    and Status__c != :LMSConstants.TPLAN_STATUS_COMPLETED
                                                                    order by CreatedDate desc
                                                                    limit 1];
            if(tpsas.size()>0){
                return true;
            }else{
                return false;
            }
        }

        //Check if the specified user has previous incomplete learning assignments
        public Boolean hasIncompleteLearningAssignment(Id tPlanSectionItemId, Id userId){
            List<Learning_Assignment__c> lass = [select Progress__c
                                                        from Learning_Assignment__c
                                                        where Training_Plan_Section_Item__c = :tPlanSectionItemId
                                                        and User__c = :userId
                                                        order by CreatedDate desc
                                                        limit 1];

            if(lass.size() > 0 && lass.get(0).Progress__c != LMSConstants.TPLAN_STATUS_COMPLETED){
                return true;
            }else{
                return false;
            }
        }

    }

}
