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
public with sharing class LMSWrappersService{

    //Get wrapper object with all training plan info
    public static TrainingPlan getTrainingPlanDetails(String trainingPlanId,Id userId,Boolean isPreview, Boolean includeSectionDetails){

        TrainingPlan result = null;
        List<Training_Plan__c> tPlans = new List<Training_Plan__c>();

        if(isPreview){
            tPlans = LMSService.getPreviewTrainingPlans(new Set<Id>{trainingPlanId});
        }else{
            tPlans = LMSService.getTrainingPlans(new Set<Id>{trainingPlanId});
        }

        if(tPlans.size()>0){
            result = new TrainingPlan();
            result.trainingPlan = tPlans.get(0);

            if(includeSectionDetails){
                result.sections = getTrainingPlanSectionsDetails(trainingPlanId,userId,isPreview);

                for(TrainingPlanSection s : result.sections){
                    result.totalMins += s.totalMins;
                }

                if(result.totalMins != null){
                    result.totalDuration = LMSUtils.getMinutesToHours(result.totalMins);
                }
            }

            //Set achievement information
            Map<Id,List<Training_Plan_Achievement__c>> trainingPlanAchievementsMap = LMSService.getTrainingPlanAchievements(new Set<Id>{trainingPlanId},'Plan');
            if(trainingPlanAchievementsMap.size()>0){

                List<Training_Plan_Achievement__c> tpAchievements = trainingPlanAchievementsMap.get(trainingPlanId);

                if(tpAchievements != null && tpAchievements.size()>0){
                    //result.badges = tpBadges;
                    result.achievements = tpAchievements;

                    //Set main achievement, default to the first entry
                    Achievement__c mainAchievement = tpAchievements.get(0).Achievement__r;

                    if(tpAchievements.size()>1){
                        for(Training_Plan_Achievement__c tpa : tpAchievements){
                            if(tpa.Main_Achievement__c){
                                mainAchievement = tpa.Achievement__r;
                                break;
                            }
                        }
                    }

                    result.mainAchievement = mainAchievement;
                }
            }

            //If we couldn't find an achievement at the training plan level then look for one at the section level
            if(result.mainAchievement == null){

                Map<Id,List<Training_Plan_Achievement__c>> trainingPlanSectionAchievementsMap = LMSService.getTrainingPlanAchievements(new Set<Id>{trainingPlanId},'Section');
                if(trainingPlanSectionAchievementsMap.size()>0){

                    List<Training_Plan_Achievement__c> tpAchievements = trainingPlanSectionAchievementsMap.get(trainingPlanId);

                    if(tpAchievements != null && tpAchievements.size()>0){

                        //Set main achievement, default to the first entry
                        Achievement__c mainAchievement = tpAchievements.get(0).Achievement__r;

                        if(tpAchievements.size()>1){
                            for(Training_Plan_Achievement__c tpa : tpAchievements){
                                if(tpa.Main_Achievement__c){
                                    mainAchievement = tpa.Achievement__r;
                                    break;
                                }
                            }
                        }

                        result.mainAchievement = mainAchievement;
                    }
                }
            }
        }

        return result;
    }

    //Get wrapper objects with all training plan section and assignments info
    public static List<TrainingPlanSection> getTrainingPlanSectionsDetails(String trainingPlanId,String userId, Boolean isPreview){
        List<TrainingPlanSection> result = new List<TrainingPlanSection>();

        //Get training plan section custom object records
        Map<Id,List<Training_Plan_Section__c>> tPlansSections = LMSService.getTrainingPlanSections(new Set<Id>{trainingPlanId});

        //If matches are found, continue creating wrapper objects
        if(tPlansSections.size()>0){

            Map<Id,TrainingPlanSection> sectionsMap = new Map<Id,TrainingPlanSection>();
            List<Training_Plan_Section__c> sections = tPlansSections.get(trainingPlanId);

            //Create wrapper objects for all the training plan sections and init map
            Id previousSection = null;
            Boolean previousSectionOptional = false;
            for(Training_Plan_Section__c s : sections){
                TrainingPlanSection tps = new TrainingPlanSection();
                tps.trainingPlanSection = s;
                tps.previousSectionId = previousSection;
                tps.previousSectionOptional = previousSectionOptional;
                result.add(tps);
                sectionsMap.put(s.Id,tps);
                previousSection = s.Id;
                previousSectionOptional = s.Optional__c;
            }

            //Add achievement information
            Map<Id,List<Training_Plan_Achievement__c>> trainingPlanSectionAchievementsMap = LMSService.getTrainingPlanSectionAchievements(sectionsMap.keySet(),'Section');

            //Add section item info
            if(sectionsMap.size() > 0){

                //Get assignment information
                Map<Id,Map<Id,Training_Plan_Section_Assignment__c>> trainingPlanSectionAssignmentsMap = LMSService.getTrainingPlanSectionAssignments(new Set<Id>{userId},sectionsMap.keySet());

                LMSService.WithoutSharingOps wsops = new LMSService.WithoutSharingOps();
                Map<Id,List<Training_Plan_Section_Item__c>> tPlansSectionItems = wsops.getTrainingPlanSectionItems(sectionsMap.keySet());

                Set<Id> learningIds = new Set<Id>();

                //Set all info related to the training plan section
                for(String sectionKey : tPlansSectionItems.keySet()){

                    List<Training_Plan_Section_Item__c> sectionItems = tPlansSectionItems.get(sectionKey);
                    Id previousSectionItem = null;
                    Boolean previousSectionItemOptional = false;

                    for(Training_Plan_Section_Item__c si : sectionItems){
                        TrainingPlanSection tps = sectionsMap.get(si.Training_Plan_Section__c);
                        if(tps != null){
                            TrainingPlanSectionItem tpsi = new TrainingPlanSectionItem();
                            tpsi.trainingPlanSectionItem = si;
                            tpsi.latestLearningVersionId = si.Learning__r.Current_Published_Version__c;

                            if(si.Learning__c != null){
                                tpsi.learning = si.Learning__r;
                                learningIds.add(si.Learning__c);
                            }
                            tps.items.add(tpsi);
                            if(si.Duration__c != null){
                                tps.totalMins += (Integer)si.Duration__c;
                            }

                            if(!previousSectionItemOptional){
                            	tpsi.previousSectionItemId = previousSectionItem;
                            }else{
                            	tpsi.previousOptionalSectionItemId = previousSectionItem;
                            }
                            tpsi.previousSectionItemOptional = si.Optional__c;
                            previousSectionItem = si.Id;
                            previousSectionItemOptional = si.Optional__c;

                            if(!si.Optional__c){
                            	tps.totalRequiredItems++;
                            }else{
                            	tps.totalOptionalItems++;
                            }
                        }
                    }
                }

                //Get assignment info for all the training plan sections
                Map<Id,List<Learning_Assignment__c>> assignments = new Map<Id,List<Learning_Assignment__c>>();
                Map<Id,Map<Id,Shared_Learning_Assignment__c>> sharedAssignments = new Map<Id,Map<Id,Shared_Learning_Assignment__c>>();

                if(!isPreview){
                    assignments = LMSService.getAssignmentsForLearnings(learningIds, trainingPlanId,new Set<Id>{userId});
                    sharedAssignments = LMSService.getSharedAssignmentsForLearnings(learningIds,new Set<Id>{userId});
                }

                //Update training plan sections with achievement info / assignment progress and section items with assignment info
                for(String sectionKey : sectionsMap.keySet()){

                    TrainingPlanSection tps = sectionsMap.get(sectionKey);
                    if(tps != null){

                        if(tps.trainingPlanSection != null && trainingPlanSectionAssignmentsMap.size()>0){
                            Map<Id,Training_Plan_Section_Assignment__c> userSectionAssignments = trainingPlanSectionAssignmentsMap.get(userId);

                            if(userSectionAssignments != null && userSectionAssignments.size()>0){
                                Training_Plan_Section_Assignment__c tpsasgmt = userSectionAssignments.get(tps.trainingPlanSection.Id);
                                tps.sectionAssignment = tpsasgmt;
                            }

                        }

                        Double totalProgress = 0;

                        //Set total hour duration
                        if(tps.totalMins != null){
                            tps.totalDuration = LMSUtils.getMinutesToHours(tps.totalMins);
                        }

                        //Set achievement information
                        List<Training_Plan_Achievement__c> tpsAchievements = trainingPlanSectionAchievementsMap.get(sectionKey);
                        if(tpsAchievements != null && tpsAchievements.size()>0){

                            //Set main achievement, default to the first entry
                            Achievement__c mainAchievement = tpsAchievements.get(0).Achievement__r;

                            if(tpsAchievements.size()>1){
                                for(Training_Plan_Achievement__c tpa : tpsAchievements){
                                    if(tpa.Main_Achievement__c){
                                        mainAchievement = tpa.Achievement__r;
                                        break;
                                    }
                                }
                            }

                            tps.mainAchievement = mainAchievement;
                        }

                        if(assignments != null && assignments.size() > 0){

                            //Set assignment information
                            for(TrainingPlanSectionItem sItem : tps.items){

                                if(sItem.learning != null && sItem.learning.Id != null){
                                    //Get training plan assignments
                                    sItem.assignments = assignments.get(sItem.learning.Id);

                                    if(sItem.assignments != null){

                                        //Get user's latest/oldest versions from assignments
                                        for(Learning_Assignment__c a : sItem.assignments){

                                            if(!sItem.learning.Sync_progress__c && a.Training_Plan_Section_Item__c != sItem.trainingPlanSectionItem.Id){
                                                continue;
                                            }

                                            if(sItem.latestAssignment == null && sItem.oldestAssignment == null){
                                                sItem.latestAssignment = a;
                                                sItem.oldestAssignment = a;
                                            }else{
                                                if(a.Learning_Version__r.Version__c > sItem.latestAssignment.Learning_Version__r.Version__c){
                                                    sItem.latestAssignment = a;
                                                }else if(a.Learning_Version__r.Version__c < sItem.oldestAssignment.Learning_Version__r.Version__c){
                                                    sItem.oldestAssignment = a;
                                                }
                                            }

                                            //Only count non-optional for progress
                                            if(!sItem.trainingPlanSectionItem.Optional__c){
                                                if(sItem.latestAssignment != null && sItem.latestAssignment.Progress_Percentage__c != null){
                                                    totalProgress+=sItem.latestAssignment.Progress_Percentage__c;
                                                }
                                            }


                                        }

                                        //Update total progress at tht training plan section level
                                        if(tps.totalRequiredItems > 0){
                                            tps.totalProgress = totalProgress/tps.totalRequiredItems;
                                        }

                                        //Turn on the outdatedAssignment flag if latest version is behind the learning current version
                                        if(sItem.latestAssignment.Learning_Version__r.Version__c < sItem.trainingPlanSectionItem.Learning__r.Current_Published_Version__r.Version__c){
                                            sItem.outdatedAssignment = true;

                                            //Get the latest version decision
                                            if(sItem.latestAssignment.Last_Published_Learning_Version__c == sItem.latestLearningVersionId){
                                                sItem.latestVersionDecision = sItem.latestAssignment.Last_Published_Learning_Version_Decision__c;
                                            }else{
                                                sItem.latestVersionDecision = LMSConstants.LV_DECISION_PENDING;
                                            }
                                        }

                                        if(sItem.outdatedAssignment){

                                            //If the decision for a latest version assignment is pending, ask for the user details
                                            if(sItem.latestVersionDecision == LMSConstants.LV_DECISION_PENDING){

                                                if(sItem.learning.Current_Published_Version__r.Version_selection_behavior__c == LMSConstants.LV_ASK_VERSION){
                                                    sItem.launchBehavior = 'ask_user';
                                                }else if(sItem.learning.Current_Published_Version__r.Version_selection_behavior__c == LMSConstants.LV_UPDATE_ON_LAUNCH){
                                                    sItem.launchBehavior = 'update_version';
                                                }

                                            }else{
                                                sItem.launchBehavior = null;
                                            }

                                        }

                                        //Add shared assignments info to the wrapper object

                                        if(sItem.sharedAssignments == null){
                                            sItem.sharedAssignments = new List<Shared_Learning_Assignment__c>();
                                        }
                                        if(sharedAssignments.get(sItem.learning.Id)!= null){
                                            sItem.sharedAssignments.add(sharedAssignments.get(sItem.learning.Id).get(userId));
                                        }

                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        return result;
    }

    public static List<TrainingTrackLevel> getTrainingTrackLevels(List<Training_Track_Level__c> levels){

        List<TrainingTrackLevel> result = new List<TrainingTrackLevel>();

        //Extract training plan ids from the track items
        Set<Id> tplanIds = new Set<Id>();
        for(Training_Track_Level__c ttl : levels){
            for(Training_Track_Level_Item__c ti : ttl.Training_Track_Level_Items__r){
                if(ti.Training_Plan__c != null){
                    tplanIds.add(ti.Training_Plan__c);
                }
            }
        }

        //Get main achievements for the related training plans
        Map<Id,Achievement__c> mainAchievements = LMSService.getTrainingMainAchievements(tplanIds);

        //Get training plan assignments for the current user
        Map<Id,Map<Id,Training_Plan_Assignment__c>> userTPlanAssignments = LMSService.getTrainingPlanAssignments(new Set<Id>{UserInfo.getUserId()},tplanIds);
        Map<Id,Training_Plan_Assignment__c> tPlanAssignments = userTPlanAssignments.get(UserInfo.getUserId());


        //Create a wrapper object for each track level
        for(Training_Track_Level__c ttl : levels){

            TrainingTrackLevel levelWrapper = new TrainingTrackLevel();
            levelWrapper.name = ttl.Name;
            levelWrapper.description = ttl.Description__c;
            levelWrapper.order = ttl.Order__c;

            for(Training_Track_Level_Item__c ttli : ttl.Training_Track_Level_Items__r){
                if(ttli.Training_Plan__c != null && ttli.Training_Plan__r != null){
                    Achievement__c ach = mainAchievements.get(ttli.Training_Plan__c);

                    TrainingTrackItem tiwrapper = new TrainingTrackItem();
                    tiwrapper.trackItem = ttli;
                    tiwrapper.mainAchievement = ach;

                    if(tPlanAssignments != null && tPlanAssignments.get(ttli.Training_Plan__c) != null){
                        tiwrapper.tplanAssignment = tPlanAssignments.get(ttli.Training_Plan__c);
                    }
                    levelWrapper.trackItems.add(tiwrapper);
                }
            }

            result.add(levelWrapper);
        }

        return result;

    }

}
