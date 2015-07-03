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
public with sharing class LMSExport{

    private Set<Id> trainingPlanIds;

    //Learning aux collections
    private Map<Id,Learning__c> learningsMap;
    private Map<String,List<Id>> learningIdsByType;

    //Lookup aux collections
    private Map<Id,Achievement__c> achievementsMap;
    private Set<Id> answerSequenceItemIds;
    private Set<Id> achievementCategoryIds;

    private Map<String,String> quizMappings = new Map<String,String>{
        'Name' => 'name'
        ,'Description__c' => 'description'
    };

    Map<String,String> learningMappings = new Map<String,String>{
        'Name' => 'name'
        ,'Duration__c' => 'duration'
        ,'Sync_progress__c' => 'sync-progress'
        ,'Description__c' => 'description'
    };

    Map<String,String> questionLineMappings = new Map<String,String>{
        'Name' => 'name'
        ,'Order__c' => 'order'
        ,'Description__c' => 'description'
    };

    Map<String,String> questionMappings = new Map<String,String>{
        'Order__c' => 'order'
        ,'Description__c' => 'description'
        ,'Type__c' => 'type'
        ,'Correct_Boolean__c' => 'correct-boolean'
        ,'Correct_Number__c' => 'correct-number'
        ,'Description_RTA__c' => 'description-rta'
    };

    Map<String,String> taskMappings = new Map<String,String>{
        'Name' => 'name'
        ,'External_Resource_Name__c' => 'resource-name'
        ,'External_Resource_URL__c' => 'resource-url'
        ,'External_Resource_Target__c' => 'resource-target'
        ,'Add_training_parameters_to_URL__c' => 'training-params-url'
        ,'Description__c' => 'description'
        ,'Description_RTA__c' => 'description-rta'
        ,'Enable_Image_Upload__c' => 'enable-image-upload'
        ,'Disable_Undo__c' => 'disable-undo'
        ,'Disable_Comments__c' => 'disable-comments'
    };

    Map<String,String> resourceMappings = new Map<String,String>{
        'Name' => 'name'
        ,'Resource_URL__c' => 'resource-url'
        ,'Add_training_parameters_to_URL__c' => 'training-params-url'
        ,'Description__c' => 'description'
        ,'Display_in_Iframe__c' => 'display-in-iframe'
    };

    Map<String,String> answerSequenceMappings = new Map<String,String>{
        'Order__c' => 'order'
        ,'Answer_Text__c' => 'answer-text'
        ,'Item_Id__c' => 'answer-id'
        ,'Is_Correct_Answer__c' => 'is-correct-answer'
    };

    Map<String,String> achievementMappings = new Map<String,String>{
        'Name' => 'name'
        ,'Type__c' => 'type'
        ,'Acquired_Image__c' => 'acquired-image'
        ,'Eligible_Image__c' => 'eligible-image'
        ,'Hidden__c' => 'hidden'
        ,'Is_Internal__c' => 'is-internal'
        ,'Override_Completed_Status__c' => 'override-completed-status'
        ,'Override_URL__c' => 'override-url'
        ,'Work_Badge_Message__c' => 'work-badge-message'
    };

    Map<String,String> trainingPlanMappings = new Map<String,String>{
        'Name' => 'name',
        'Description__c' => 'description',
        'Status__c' => 'status',
        'Intro_Video_URL__c' => 'intro-video-url',
        'Background_Image_URL__c' => 'background-image-url',
        'Background_Color__c' => 'background-color',
        'Text_Color__c' => 'text-color',
        'Enforce_Sequence__c' => 'enforce-sequence',
        'Enable_Self_Registration__c' => 'enable-self-registration',
        'Self_Registration_Access__c' => 'self-registration-access',
        'Hide_Chatter_Photos__c' => 'hide-chatter-photos',
        'Optional_Feedback_Comments__c' => 'optional-feedback-comments',
        'Custom_Notification_Message__c' => 'custom-notification-message',
        'Hide_After_End_Date__c' => 'hide-after-end-date'
    };

    Map<String,String> trainingPlanSectionMappings = new Map<String,String>{
        'Name' => 'name',
        'Order__c' => 'order',
        'Optional__c' => 'optional'
    };

    Map<String,String> trainingPlanSectionItemMappings = new Map<String,String>{
        'Order__c' => 'order',
        'Optional__c' => 'optional'
    };

    Map<String,String> trainingPlanAchievementMappings = new Map<String,String>{
        'Main_Achievement__c' => 'main-achievement'
    };

    public static String trainingPlanToJSON(Id trainingPlanId, Boolean serializePretty){
        LMSExport exprt = new LMSExport();
        Map<String,Object> exportResults = exprt.exportTrainingPlans(new Set<Id>{trainingPlanId});
        if(serializePretty){
            return JSON.serializePretty(exportResults);
        }
        return JSON.serialize(exportResults);
    }

    public class LMSExportException extends Exception{}

    public LMSExport(){
        this.learningsMap = new Map<Id,Learning__c>();
        this.achievementsMap = new Map<Id,Achievement__c>();
        this.answerSequenceItemIds = new Set<Id>();
        this.achievementCategoryIds = new Set<Id>();
        this.learningIdsByType = new Map<String,List<Id>>();
    }

    public Map<String, Object> exportTrainingPlans(Set<Id> trainingPlanIds){
        this.trainingPlanIds = trainingPlanIds;
        List<Object> learningObjects = buildLearningObjects();
        List<Object> achievementObjects = buildAchievementObjects();
        List<Object> planObjects = buildPlanObjects();
        List<Object> lookupObjects = buildLookupObjects();

        Map<String, Object> tPlanExportResults = new Map<String, Object>();
        tPlanExportResults.put('learning-objects',learningObjects);
        tPlanExportResults.put('lookup-objects',lookupObjects);
        tPlanExportResults.put('achievement-objects',achievementObjects);
        tPlanExportResults.put('plan-objects',planObjects);
        return tPlanExportResults;
    }

    private Set<Id> getLearningIds(){
        Set<Id> learningIds = new Set<Id>();
        for(Training_Plan_Section_Item__c tpi : [select id
                                                        ,Learning__c
                                                        from Training_Plan_Section_Item__c
                                                        where Training_Plan_Section__r.Training_Plan__c in :trainingPlanIds]){
            if(tpi.Learning__c != null){
                learningIds.add(tpi.Learning__c);
            }
        }
        return learningIds;
    }

    private Set<Id> getAchievementIds(){
        Set<Id> achievementIds = new Set<Id>();
        for(Training_Plan_Achievement__c tpa : [select id
                                                        ,Achievement__c
                                                        from Training_Plan_Achievement__c
                                                        where Training_Plan__c in :trainingPlanIds]){
            if(tpa.Achievement__c != null){
                achievementIds.add(tpa.Achievement__c);
            }
        }
        return achievementIds;
    }

    private List<Object> buildAchievementObjects(){
        Set<Id> achievementIds = getAchievementIds();
        List<Object> results = new List<Object>();
        for(Achievement__c a : [select id
                                    ,Name
                                    ,Achievement_Category__c
                                    ,Achievement_Category__r.Name
                                    ,Acquired_Image__c
                                    ,Eligible_Image__c
                                    ,Expiration_Date__c
                                    ,Override_Completed_Status__c
                                    ,Override_URL__c
                                    ,Type__c
                                    ,Work_Badge_Message__c
                                    ,Hidden__c
                                    ,Is_Internal__c
                                    from Achievement__c where id in :achievementIds]){
            achievementsMap.put(a.Id, a);
        }

        for(Achievement__c a : achievementsMap.values()){
            Map<String,Object> achievementObject = mapSObject(a, achievementMappings);
            if(a.Achievement_Category__c != null){
                achievementCategoryIds.add(a.Achievement_Category__c);
                achievementObject.put('achievement-category', a.Achievement_Category__r.Name);
            }
            if(a.Expiration_Date__c != null){
                achievementObject.put('expiration-date', formatDateForExport(a.Expiration_Date__c));
            }
            results.add(achievementObject);
        }

        return results;
    }

    private List<Object> buildLearningObjects(){
        Set<Id> learningIds = getLearningIds();
        List<Object> results = new List<Object>();
        for(Learning__c l : [select id
                            ,name
                            ,RecordType.DeveloperName
                            ,Duration__c
                            ,Description__c
                            ,Sync_progress__c
                            from Learning__c where id in :learningIds]){
            learningsMap.put(l.Id,l);
            if(!learningIdsByType.containsKey(l.RecordType.DeveloperName)){
                learningIdsByType.put(l.RecordType.DeveloperName, new List<Id>());
            }
            learningIdsByType.get(l.RecordType.DeveloperName).add(l.Id);
        }
        results.addAll(buildQuizLearningsContent());
        results.addAll(buildTaskLearningsContent());
        results.addAll(buildResourceLearningsContent());
        return results;
    }

    private List<Object> buildResourceLearningsContent(){

        List<Object> result = new List<Object>();
        List<Id> resourceLearningIds = learningIdsByType.get('Resource');

        if(resourceLearningIds == null || resourceLearningIds.size() == 0){
            return result;
        }

        Map<Id,Training_Resource__c> resourcesMap = new Map<Id,Training_Resource__c>();

        //Fetch Resource Info
        for(Training_Resource__c tr : [select Id
                            ,Name
                            ,Resource_URL__c
                            ,Add_training_parameters_to_URL__c
                            ,Description__c
                            ,Display_in_Iframe__c
                            ,Learning__c
                            from Training_Resource__c
                            where Learning__c in :resourceLearningIds]){
            resourcesMap.put(tr.Id,tr);
        }

        for(Training_Resource__c tr : resourcesMap.values()){
            Map<String,Object> learningObject = initLearningObject(learningsMap.get(tr.Learning__c));
            Map<String,Object> resourceObject = mapSObject(tr,resourceMappings);
            learningObject.put('content', resourceObject);
            result.add(learningObject);
        }

        return result;
    }

    private List<Object> buildTaskLearningsContent(){

        List<Object> result = new List<Object>();
        List<Id> taskLearningIds = learningIdsByType.get('Task');

        if(taskLearningIds == null || taskLearningIds.size() == 0){
            return result;
        }

        Map<Id,Task__c> tasksMap = new Map<Id,Task__c>();

        //Fetch Task Info
        for(Task__c t : [select Id
                            ,Name
                            ,External_Resource_Name__c
                            ,External_Resource_URL__c
                            ,External_Resource_Target__c
                            ,Requires_Manager_Approval__c
                            ,Disable_Undo__c
                            ,Description_RTA__c
                            ,Description__c
                            ,Disable_Comments__c
                            ,Add_training_parameters_to_URL__c
                            ,Enable_Image_Upload__c
                            ,Learning__c
                            from Task__c
                            where Learning__c in :taskLearningIds]){
            tasksMap.put(t.Id,t);
        }

        for(Task__c t : tasksMap.values()){
            Map<String,Object> learningObject = initLearningObject(learningsMap.get(t.Learning__c));
            Map<String,Object> taskObject = mapSObject(t,taskMappings);
            learningObject.put('content', taskObject);
            result.add(learningObject);
        }

        return result;

    }

    private List<Object> buildQuizLearningsContent(){

        List<Object> result = new List<Object>();
        List<Id> quizLearningIds = learningIdsByType.get('Quiz');
        Map<Id, List<Id>> questionLinesForQuiz = new Map<Id, List<Id>>();
        Map<Id, Question_Line__c> questionLinemap = new Map<Id, Question_Line__c>();
        Map<Id, List<Id>> questionsForQuestionLine = new Map<Id, List<Id>>();
        Map<Id, Question__c> questionMap = new Map<Id, Question__c>();

        if(quizLearningIds == null || quizLearningIds.size() == 0){
            return result;
        }

        Map<Id,Quiz__c> quizzesMap = new Map<Id,Quiz__c>();

        //Fetch Quiz Info
        for(Quiz__c q : [select Id
                            ,Name
                            ,Passing_Score__c
                            ,Max_Attempts__c
                            ,Description__c
                            ,Learning__c
                            from Quiz__c
                            where Learning__c in :quizLearningIds]){
            quizzesMap.put(q.Id,q);
        }

        //Fetch Question Lines
        for(Question_Line__c ql : [select Id
                                        ,Name
                                        ,Order__c
                                        ,Description__c
                                        ,Quiz__c
                                        from Question_Line__c
                                        where Quiz__c in :quizzesMap.keySet()]){

            questionLinemap.put(ql.Id,ql);
            if(!questionLinesForQuiz.containsKey(ql.Quiz__c)){
                questionLinesForQuiz.put(ql.Quiz__c, new List<Id>());
            }
            questionLinesForQuiz.get(ql.Quiz__c).add(ql.Id);
        }
        //Fetch Questions
        for(Question__c q : [select Id
                                    ,Name
                                    ,Order__c
                                    ,Description__c
                                    ,Description_RTA__c
                                    ,Type__c
                                    ,Correct_Boolean__c
                                    ,Correct_Number__c
                                    ,Answer_Sequence__c
                                    ,Question_Line__c
                                    from Question__c
                                    where Question_Line__c in :questionLinemap.keySet()]){

            questionMap.put(q.Id,q);
            if(q.Answer_Sequence__c != null){
                answerSequenceItemIds.add(q.Answer_Sequence__c);
            }
            if(!questionsForQuestionLine.containsKey(q.Question_Line__c)){
                questionsForQuestionLine.put(q.Question_Line__c, new List<Id>());
            }
            questionsForQuestionLine.get(q.Question_Line__c).add(q.Id);
        }

        for(Quiz__c q : quizzesMap.values()){
            Map<String,Object> learningObject = initLearningObject(learningsMap.get(q.Learning__c));
            Map<String,Object> quizObject = mapSObject(q, quizMappings);

            List<Object> questionLines = new List<Object>();
            for(Id qlId : questionLinesForQuiz.get(q.Id)){
                Question_Line__c ql = questionLinemap.get(qlId);
                Map<String,Object> questionLineObject = mapSObject(ql, questionLineMappings);
                questionLines.add(questionLineObject);

                List<Object> questionLineQuestions = new List<Object>();
                for(Id qsId : questionsForQuestionLine.get(ql.Id)){
                    Question__c qs = questionMap.get(qsId);
                    Map<String,Object> questionObject = mapSObject(qs, questionMappings);
                    questionObject.put('answer-sequence',qs.Answer_Sequence__c);
                    questionLineQuestions.add(questionObject);
                }
                questionLineObject.put('questions', questionLineQuestions);
            }

            quizObject.put('question-lines',questionLines);
            learningObject.put('content', quizObject);
            result.add(learningObject);
        }

        return result;

    }

    private Map<String,Object> initLearningObject(Learning__c l){
        // Add lookup information
        Map<String,Object> result = mapSObject(l, learningMappings);
        result.put('record-type', l.RecordType.DeveloperName);
        return result;
    }

    private List<Object> buildLookupObjects(){
        List<Object> results = new List<Object>();
        results.addAll(buildAnswerSequenceLookups());
        results.addAll(buildAchievementCategoryLookups());
        return results;
    }

    private List<Object> buildAchievementCategoryLookups(){
        List<Object> results = new List<Object>();

        if(achievementCategoryIds.size() == 0){
            return results;
        }

        Map<Id,Achievement_Category__c> achievementCategoryMap = new Map<Id,Achievement_Category__c>();

        for(Achievement_Category__c ac : [select Id
                                            ,Name
                                            from Achievement_Category__c
                                            where id in :achievementCategoryIds]){
            achievementCategoryMap.put(ac.Id, ac);
        }

        for(Achievement_Category__c ac : achievementCategoryMap.values()){
            Map<String,Object> acObject = new Map<String,Object>();
            acObject.put('type','achievement-category');
            acObject.put('name', ac.Name);
            acObject.put('content',new Map<String,Object>());
            results.add(acObject);
        }

        return results;
    }

    private List<Object> buildAnswerSequenceLookups(){
        List<Object> results = new List<Object>();

        if(answerSequenceItemIds.size() == 0){
            return results;
        }

        Map<Id,Answer_Sequence__c> answerSequenceMap = new Map<Id,Answer_Sequence__c>();
        Map<Id,Answer_Sequence_Item__c> answerSequenceItemMap = new Map<Id,Answer_Sequence_Item__c>();
        Map<Id, List<Id>> itemsForAnswerSequence = new Map<Id, List<Id>>();

        for(Answer_Sequence__c aseq : [select Id
                                            ,Name
                                            ,Internal_Notes__c
                                            from Answer_Sequence__c
                                            where id in :answerSequenceItemIds]){
            answerSequenceMap.put(aseq.Id, aseq);
        }

        for(Answer_Sequence_Item__c asi : [select Id
                                            ,Name
                                            ,Answer_Text__c
                                            ,Is_Correct_Answer__c
                                            ,Item_Id__c
                                            ,Order__c
                                            ,Answer_Sequence__c
                                            from Answer_Sequence_Item__c
                                            where Answer_Sequence__c in :answerSequenceMap.keySet()]){

            answerSequenceItemMap.put(asi.Id, asi);
            if(!itemsForAnswerSequence.containsKey(asi.Answer_Sequence__c)){
                itemsForAnswerSequence.put(asi.Answer_Sequence__c, new List<Id>());
            }
            itemsForAnswerSequence.get(asi.Answer_Sequence__c).add(asi.Id);
        }

        for(Answer_Sequence__c aseq : answerSequenceMap.values()){
            Map<String,Object> asObject = new Map<String,Object>();
            asObject.put('type','answer-sequence');
            asObject.put('name', aseq.Id);

            Map<String,Object> asOptions = new Map<String,Object>();
            List<Object> asItems = new List<Object>();
            for(Id asId : itemsForAnswerSequence.get(aseq.Id)){
                Answer_Sequence_Item__c asi = answerSequenceItemMap.get(asId);
                asItems.add(mapSObject(asi, answerSequenceMappings));
            }
            asOptions.put('options',asItems);
            asObject.put('content',asOptions);
            results.add(asObject);
        }

        return results;
    }

    private List<Object> buildPlanObjects(){
        List<Object> results = new List<Object>();

        Map<Id, Training_Plan__c> trainingPlansMap = new Map<Id, Training_Plan__c>();
        Map<Id, Training_Plan_Section__c> trainingSectionsMap = new Map<Id, Training_Plan_Section__c>();
        Map<Id, List<Id>> sectionsForTrainingPlan = new Map<Id, List<Id>>();
        Map<Id, Training_Plan_Section_Item__c> trainingSectionItemsMap = new Map<Id, Training_Plan_Section_Item__c>();
        Map<Id, List<Id>> itemsForTrainingPlanSection = new Map<Id, List<Id>>();
        Map<Id, Training_Plan_Achievement__c> trainingPlanAchievementsMap = new Map<Id, Training_Plan_Achievement__c>();
        Map<Id, List<Id>> achievementsForTrainingPlan = new Map<Id, List<Id>>();

        //Fetch training plans
        for(Training_Plan__c tp : [select Id
                                        ,Name
                                        ,Description__c
                                        ,Status__c
                                        ,Intro_Video_URL__c
                                        ,Background_Image_URL__c
                                        ,Background_Color__c
                                        ,Text_Color__c
                                        ,Enforce_Sequence__c
                                        ,Enable_Self_Registration__c
                                        ,Self_Registration_Access__c
                                        ,Hide_Chatter_Photos__c
                                        ,Optional_Feedback_Comments__c
                                        ,Custom_Notification_Message__c
                                        ,Hide_After_End_Date__c
                                        ,Start_Date__c
                                        ,End_Date__c
                                        from Training_Plan__c
                                        where id in :trainingPlanIds]){
            trainingPlansMap.put(tp.Id, tp);
        }

        //Fetch training plan achievements
        for(Training_Plan_Achievement__c tpa : [select Id
                                        ,Name
                                        ,Achievement__c
                                        ,Achievement__r.Name
                                        ,Main_Achievement__c
                                        ,Training_Plan_Section__c
                                        ,Training_Plan_Section__r.Name
                                        ,Training_Plan__c
                                        ,Type__c
                                        from Training_Plan_Achievement__c
                                        where Training_Plan__c in :trainingPlanIds]){
            trainingPlanAchievementsMap.put(tpa.Id, tpa);
            if(!achievementsForTrainingPlan.containsKey(tpa.Training_Plan__c)){
                achievementsForTrainingPlan.put(tpa.Training_Plan__c, new List<Id>());
            }
            achievementsForTrainingPlan.get(tpa.Training_Plan__c).add(tpa.Id);
        }

        //Fetch training plan sections
        for(Training_Plan_Section__c tps : [select Id
                                                    ,Name
                                                    ,Order__c
                                                    ,Optional__c
                                                    ,Training_Plan__c
                                                    from Training_Plan_Section__c
                                                    where Training_Plan__c in :trainingPlanIds]){
            trainingSectionsMap.put(tps.Id, tps);
            if(!sectionsForTrainingPlan.containsKey(tps.Training_Plan__c)){
                sectionsForTrainingPlan.put(tps.Training_Plan__c, new List<Id>());
            }
            sectionsForTrainingPlan.get(tps.Training_Plan__c).add(tps.Id);
        }

        //Fetch training plan section items
        for(Training_Plan_Section_Item__c tpsi : [select Id
                                                    ,Order__c
                                                    ,Learning__c
                                                    ,Learning__r.Name
                                                    ,Training_Plan_Section__c
                                                    ,Optional__c
                                                    from Training_Plan_Section_Item__c
                                                    where Training_Plan_Section__c in :trainingSectionsMap.keySet()]){
            trainingSectionItemsMap.put(tpsi.Id, tpsi);
            if(!itemsForTrainingPlanSection.containsKey(tpsi.Training_Plan_Section__c)){
                itemsForTrainingPlanSection.put(tpsi.Training_Plan_Section__c, new List<Id>());
            }
            itemsForTrainingPlanSection.get(tpsi.Training_Plan_Section__c).add(tpsi.Id);
        }

        for(Training_Plan__c tp : trainingPlansMap.values()){
            Map<String,Object> planObject = mapSObject(tp, trainingPlanMappings);
            if(tp.Start_Date__c != null){
                planObject.put('start-date', formatDateForExport(tp.Start_Date__c));
            }
            if(tp.End_Date__c != null){
                planObject.put('end-date', formatDateForExport(tp.End_Date__c));
            }

            List<Object> tplanSectionObjects = new List<Object>();
            for(Id tpsId : sectionsForTrainingPlan.get(tp.Id)){
                Training_Plan_Section__c tps = trainingSectionsMap.get(tpsId);
                Map<String,Object> sectionObject = mapSObject(tps, trainingPlanSectionMappings);
                List<Object> tplanSectionItemObjects = new List<Object>();
                for(Id tpsiId : itemsForTrainingPlanSection.get(tps.Id)){
                    Training_Plan_Section_Item__c tpsi = trainingSectionItemsMap.get(tpsiId);
                    Map<String,Object> sectionItemObject = mapSObject(tpsi, trainingPlanSectionItemMappings);
                    sectionItemObject.put('learning', tpsi.Learning__r.Name);
                    tplanSectionItemObjects.add(sectionItemObject);
                }
                sectionObject.put('items',tplanSectionItemObjects);
                tplanSectionObjects.add(sectionObject);
            }

            List<Object> tplanAchievementObjects = new List<Object>();
            for(Id tpaId : achievementsForTrainingPlan.get(tp.Id)){
                Training_Plan_Achievement__c tpa = trainingPlanAchievementsMap.get(tpaId);
                if(tpa.Achievement__c == null){
                    continue;
                }
                Map<String,Object> tPlanAchievementObject = mapSObject(tpa, trainingPlanAchievementMappings);
                tPlanAchievementObject.put('achievement',tpa.Achievement__r.Name);
                if(tpa.Training_Plan_Section__c != null){
                    tPlanAchievementObject.put('section',tpa.Training_Plan_Section__r.Name);
                }
                tplanAchievementObjects.add(tPlanAchievementObject);
            }
            planObject.put('sections', tplanSectionObjects);
            planObject.put('achievements', tplanAchievementObjects);
            results.add(planObject);
        }

        return results;
    }

    private List<Object> mapSObjects(List<SObject> sobjects, Map<String,String> mappings){
        List<Object> result =  new List<Object>();
        for(Sobject obj : sobjects){
            result.add(mapSObject(obj,mappings));
        }
        return result;
    }

    private Map<String,Object> mapSObject(SObject obj, Map<String,String> mappings){
        Map<String,Object> result =  new Map<String,Object>();
        for(String key : mappings.keySet()){
            result.put(mappings.get(key), obj.get(key));
        }
        return result;
    }

    private String formatDateForExport(Date dt){
        String monthValue = String.valueOf(dt.month());
        monthValue = monthValue.length()==1?'0'+monthValue:monthValue;
        String dayValue = String.valueOf(dt.day());
        dayValue = dayValue.length()==1?'0'+dayValue:dayValue;
        String dateValue = dt.year()+'-'+monthValue+'-'+dayValue;
        return dateValue;
    }

}
