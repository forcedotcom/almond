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
public with sharing class LMSInit{

    public class LMSInitException extends Exception{}

    public static String fetchInitData(String resourceName){
        if(UserInfo.getLanguage() != 'en_US'){
            String translatedResourceName = resourceName+'_'+UserInfo.getLanguage();
            List<StaticResource> sResources = [select id from StaticResource where Name = :translatedResourceName];
            if(sResources.size()>0){
              resourceName = translatedResourceName;
            }
        }
        Blob body = [select body from StaticResource where Name = :resourceName limit 1].body;
        return body.toString();
    }

    public static void initData(String jsonData, Boolean addTimeStamp){

        if(jsonData == null){
            throw new LMSInitException(System.Label.ALMS_Invalid_Import_Data);
        }

        //BEGIN Access Check
        Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
        relatedFieldsObjects.put(Learning__c.sObjectType,new List<String>{'Name'});
        relatedFieldsObjects.put(Training_Resource__c.sObjectType,new List<String>{'Name'});
        relatedFieldsObjects.put(Task__c.sObjectType,new List<String>{'Name'});
        relatedFieldsObjects.put(Quiz__c.sObjectType,new List<String>{'Name'});
        relatedFieldsObjects.put(Achievement__c.sObjectType,new List<String>{'Name'});
        relatedFieldsObjects.put(Training_Plan__c.sObjectType,new List<String>{'Name'});
        relatedFieldsObjects.put(Training_Plan_Section__c.sObjectType,new List<String>{'Name','Training_Plan__c'});
        relatedFieldsObjects.put(Training_Plan_Section_Item__c.sObjectType,new List<String>{'Training_Plan_Section__c'});
        relatedFieldsObjects.put(Training_Plan_Achievement__c.sObjectType,new List<String>{'Training_Plan__c'});
        relatedFieldsObjects.put(Training_Track__c.sObjectType,new List<String>{'Name'});
        relatedFieldsObjects.put(Training_Track_Level__c.sObjectType,new List<String>{'Name','Training_Track__c'});
        LMS_ESAPI.isAuthorizedToCreate(relatedFieldsObjects);
        //END Access Check

        Savepoint sp = Database.setSavepoint();

        try{

            String ts = '_'+getTimeStamp();
            Map<String,Object> dataMap = (Map<String,Object>)JSON.deserializeUntyped(jsonData);

            //Aux maps
            Map<String,Answer_Sequence__c> answerSequences = new Map<String,Answer_Sequence__c>();
            Map<String,Answer_Sequence_Item__c> answerSequenceItems = new Map<String,Answer_Sequence_Item__c>();
            Map<String,Learning__c> learnings = new Map<String,Learning__c>();
            Map<String,Training_Resource__c> resources = new Map<String,Training_Resource__c>();
            Map<String,Task__c> tasks = new Map<String,Task__c>();
            Map<String,Quiz__c> quizzes = new Map<String,Quiz__c>();
            Map<String,Question_Line__c> questionLines = new Map<String,Question_Line__c>();
            Map<String,Question__c> questions = new Map<String,Question__c>();
            Map<String,Achievement__c> achievements = new Map<String,Achievement__c>();
            Map<String,Training_Plan__c> plans = new Map<String,Training_Plan__c>();
            Map<String,Training_Plan_Section__c> sections = new Map<String,Training_Plan_Section__c>();
            Map<String,Training_Plan_Section_Item__c> sectionItems = new Map<String,Training_Plan_Section_Item__c>();
            Map<String,Training_Plan_Achievement__c> planAchievements = new Map<String,Training_Plan_Achievement__c>();
            Map<String,Training_Track__c> tracks = new Map<String,Training_Track__c>();
            Map<String,Training_Track_Level__c> levels = new Map<String,Training_Track_Level__c>();
            Map<String,Training_Track_Level_Item__c> trackItems = new Map<String,Training_Track_Level_Item__c>();

            //Check for existing lookups
            Map<String,Map<String,String>> existingRecordsMap = new Map<String,Map<String,String>>();
            List<Object> lookupObjects = getObjectList(dataMap,'lookup-objects');

            for(Object lo : lookupObjects){
                Map<String,Object> lHeader = (Map<String,Object>)lo;
                String name = addTimeStamp?(String)lHeader.get('name')+ts:(String)lHeader.get('name');
                String type = (String)lHeader.get('type');
                if(!existingRecordsMap.containsKey(type)){
                    existingRecordsMap.put(type,new Map<String,String>());
                }
                existingRecordsMap.get(type).put(name,null);

                // Always create answer sequence lookups
                if(type == 'answer-sequence'){
                    Answer_Sequence__c aseq = new Answer_Sequence__c();
                    answerSequences.put(name,aseq);
                }

            }

            //Insert missing lookups
            if(existingRecordsMap.get('achievement-category') != null){

                Map<String,Achievement_Category__c> acMap = new Map<String,Achievement_Category__c>();

                for(Achievement_Category__c extAC : [select id,name from Achievement_Category__c where Name = :existingRecordsMap.get('achievement-category').keySet()]){
                    existingRecordsMap.get('achievement-category').put(extAC.name, extAC.id);
                }
                //Insert missing values
                for(String acKey : existingRecordsMap.get('achievement-category').keySet()){
                    if(existingRecordsMap.get('achievement-category').get(acKey) == null){
                      Achievement_Category__c ac = new Achievement_Category__c();
                      ac.Name = acKey;
                      acMap.put(ac.name,ac);
                    }
                }
                // Update existing mappings map
                if(acMap.size()>0){
                    insert acMap.values();
                    for(Achievement_Category__c ac : acMap.values()){
                        existingRecordsMap.get('achievement-category').put(ac.name, ac.id);
                    }
                }
            }
            if(answerSequences.size() > 0){
                insert answerSequences.values();
            }

            //Create learning record type map
            Map<String,String> learningRTMap = new Map<String,String>();
            String learningObjectName = LMSUtils.getPackageNamespace()+'Learning__c';
            for(RecordType rt : [select Id,DeveloperName from RecordType where SobjectType = :learningObjectName]){
                learningRTMap.put(rt.DeveloperName,rt.Id);
            }

            //Create lookup children
            for(Object lo : lookupObjects){
                Map<String,Object> lHeader = (Map<String,Object>)lo;
                String headerName = addTimeStamp?(String)lHeader.get('name')+ts:(String)lHeader.get('name');
                String type = (String)lHeader.get('type');
                if(type == 'answer-sequence'){
                    Map<String,Object> lookUpContent = (Map<String,Object>)lHeader.get('content');
                    List<Object> sequenceItems = getObjectList(lookUpContent,'options');
                    for(Object sit : sequenceItems){
                        Map<String,Object> it = (Map<String,Object>)sit;
                        Answer_Sequence_Item__c asi = new Answer_Sequence_Item__c();
                        asi.Order__c = getIntegerValue(it.get('order'),null);
                        asi.Answer_Text__c = getStringValue(it.get('answer-text'),null);
                        asi.Item_Id__c = getStringValue(it.get('answer-id'),'');
                        asi.Is_Correct_Answer__c = getBooleanValue(it.get('is-correct-answer'),false);
                        asi.Answer_Sequence__c = answerSequences.get(headerName).Id;
                        answerSequenceItems.put(headerName+asi.Item_Id__c,asi);
                    }
                }
            }
            if(answerSequenceItems.size() > 0){
                insert answerSequenceItems.values();
            }

            //Iterate over learning objects

            List<Object> learningObjects = getObjectList(dataMap,'learning-objects');

            for(Object lo : learningObjects){

                //Create learning header
                Map<String,Object> lHeader = (Map<String,Object>)lo;
                Learning__c l = new Learning__c();
                String lName = addTimeStamp?(String)lHeader.get('name')+ts:(String)lHeader.get('name');
                l.Name = lName;
                l.RecordTypeId = learningRTMap.get((String)lHeader.get('record-type'));
                l.Duration__c = getIntegerValue(lHeader.get('duration'),null);
                l.Description__c = getStringValue(lHeader.get('description'),null);
                l.Sync_progress__c = getBooleanValue(lHeader.get('sync-progress'),false);
                learnings.put(l.Name,l);

            }

            if(learnings.size() > 0){
                insert learnings.values();
            }

            //Create learning content
            for(Object lo : learningObjects){

                Map<String,Object> lHeader = (Map<String,Object>)lo;
                Map<String,Object> lContent = (Map<String,Object>)lHeader.get('content');
                String headerName = addTimeStamp?(String)lHeader.get('name')+ts:(String)lHeader.get('name');

                if((String)lHeader.get('record-type') == 'Resource'){
                    Training_Resource__c tr = new Training_Resource__c();
                    tr.Name = (String)lContent.get('name');
                    tr.Resource_URL__c = getStringValue(lContent.get('resource-url'),null);
                    tr.Add_training_parameters_to_URL__c = getBooleanValue(lContent.get('training-params-url'),false);
                    tr.Description__c = getStringValue(lContent.get('description'),null);
                    tr.Display_in_Iframe__c = getBooleanValue(lContent.get('display-in-iframe'),false);
                    tr.Learning__c = learnings.get(headerName).Id;
                    resources.put(tr.Learning__c,tr);
                }else if((String)lHeader.get('record-type') == 'Task'){
                    Task__c tk = new Task__c();
                    tk.Name = (String)lContent.get('name');
                    tk.External_Resource_Name__c = getStringValue(lContent.get('resource-name'),null);
                    tk.External_Resource_URL__c = getStringValue(lContent.get('resource-url'),null);
                    tk.External_Resource_Target__c = getStringValue(lContent.get('resource-target'),null);
                    tk.Add_training_parameters_to_URL__c = getBooleanValue(lContent.get('training-params-url'),false);
                    tk.Description__c = getStringValue(lContent.get('description'),null);
                    tk.Learning__c = learnings.get(headerName).Id;
                    tk.Enable_Image_Upload__c = getBooleanValue(lContent.get('enable-image-upload'),false);
                    tk.Disable_Undo__c = getBooleanValue(lContent.get('disable-undo'),false);
                    tasks.put(tk.Learning__c ,tk);
                }else if((String)lHeader.get('record-type') == 'Quiz'){
                    Quiz__c qz = new Quiz__c();
                    qz.Name = (String)lContent.get('name');
                    qz.Passing_Score__c = getDoubleValue(lContent.get('passing-score'),null);
                    qz.Max_Attempts__c = getIntegerValue(lContent.get('max-attempts'),null);
                    qz.Description__c = getStringValue(lContent.get('description'),null);
                    qz.Learning__c = learnings.get(headerName).Id;
                    quizzes.put(qz.Learning__c,qz);
                }
            }

            if(resources.size() > 0){
                insert resources.values();
            }

            if(tasks.size() > 0){
                insert tasks.values();
            }

            if(quizzes.size() > 0){
                insert quizzes.values();
            }

            //Create quiz question lines
            for(Object lo : learningObjects){

                Map<String,Object> lHeader = (Map<String,Object>)lo;

                if((String)lHeader.get('record-type') == 'Quiz'){
                    Map<String,Object> lContent = (Map<String,Object>)lHeader.get('content');
                    List<Object> qLineObjects = getObjectList(lContent,'question-lines');
                    String headerName = addTimeStamp?(String)lHeader.get('name')+ts:(String)lHeader.get('name');

                    for(Object qlo : qLineObjects){
                        Map<String,Object> qlHeader = (Map<String,Object>)qlo;
                        String qlHeaderName = headerName+(String)qlHeader.get('name');
                        Question_Line__c ql = new Question_Line__c();
                        ql.Name = (String)qlHeader.get('name');
                        ql.Order__c = getIntegerValue(qlHeader.get('order'),null);
                        ql.Description__c = getStringValue(qlHeader.get('description'),null);
                        Learning__c l = learnings.get(headerName);
                        ql.Quiz__c = quizzes.get(l.id).Id;
                        questionLines.put(qlHeaderName,ql);
                    }
                }
            }

            if(questionLines.size() > 0){
                insert questionLines.values();
            }

            //Create quiz questions
            for(Object lo : learningObjects){

                Map<String,Object> lHeader = (Map<String,Object>)lo;

                if((String)lHeader.get('record-type') == 'Quiz'){
                    Map<String,Object> lContent = (Map<String,Object>)lHeader.get('content');
                    List<Object> qLineObjects = getObjectList(lContent,'question-lines');
                    String headerName = addTimeStamp?(String)lHeader.get('name')+ts:(String)lHeader.get('name');

                    for(Object qlo : qLineObjects){
                        Map<String,Object> qlHeader = (Map<String,Object>)qlo;
                        List<Object> questionObjects = getObjectList(qlHeader,'questions');
                        String qlHeaderName = headerName+(String)qlHeader.get('name');
                        Integer qCount = 0;

                        for(Object qo : questionObjects){
                            Map<String,Object> qHeader = (Map<String,Object>)qo;
                            Question__c q = new Question__c();
                            q.Type__c = (String)qHeader.get('type');
                            q.Order__c = getIntegerValue(qHeader.get('order'),null);
                            q.Description__c = getStringValue(qHeader.get('description'),null);
                            if(qHeader.get('answer-sequence') != null){
                                String aswSeqName = addTimeStamp?(String)qHeader.get('answer-sequence')+ts:(String)qHeader.get('answer-sequence');
                                q.Answer_Sequence__c = answerSequences.get(aswSeqName).Id;
                            }else if(qHeader.get('correct-boolean') != null){
                                q.Correct_Boolean__c = (String)qHeader.get('correct-boolean');
                            }else if(qHeader.get('correct-number') != null){
                                q.Correct_Number__c = (Double)qHeader.get('correct-number');
                            }
                            q.Question_Line__c = questionLines.get(qlHeaderName).Id;
                            questions.put(qlHeaderName+''+qCount,q);
                            qCount++;
                        }
                    }
                }
            }

            if(questions.size() > 0){
                insert questions.values();
            }

            //Publish learnings

            Map<String,Learning_Version__c> lVersions = new Map<String,Learning_Version__c>();
            List<Learning__c> insertedLearnings = new List<Learning__c>();

            if(learnings.size() > 0){
                insertedLearnings = [select id
                                            ,Name
                                            ,RecordType.DeveloperName
                                            from Learning__c
                                            where id in :learnings.values()];
            }

            for(Learning__c l : insertedLearnings){
                Learning_Version__c lv = new Learning_Version__c();
                lv.Learning__c = l.id;
                lv.Version__c = 1;
                lv.Type__c = 'Published';
                lv.Version_selection_behavior__c = null;
                if(l.RecordType.DeveloperName == 'Resource'){
                    lv.Training_Resource__c = resources.get(l.id).Id;
                }else if(l.RecordType.DeveloperName == 'Task'){
                    lv.Task__c= tasks.get(l.id).Id;
                }else if(l.RecordType.DeveloperName == 'Quiz'){
                    lv.Quiz__c= quizzes.get(l.id).Id;
                }
                lVersions.put(l.id,lv);
            }

            if(lVersions.size() > 0){
                insert lVersions.values();
            }

            //Update header information
            for(Learning__c l : insertedLearnings){
                l.Current_Published_Version__c = lVersions.get(l.id).Id;
                l.Published__c = true;
            }

            if(insertedLearnings.size() > 0){
                update insertedLearnings;
            }

            //Create achievements
            List<Object> achievementObjects = getObjectList(dataMap,'achievement-objects');

            for(Object ao : achievementObjects){

                Map<String,Object> achievementHeader = (Map<String,Object>)ao;
                Achievement__c a = new Achievement__c();
                String aName = addTimeStamp?(String)achievementHeader.get('name')+ts:(String)achievementHeader.get('name');
                a.Name = aName;
                a.Type__c = (String)achievementHeader.get('type');
                a.Eligible_Image__c = getStringValue(achievementHeader.get('eligible-image'),'');
                a.Acquired_Image__c = getStringValue(achievementHeader.get('acquired-image'),'');
                if(LMSUtils.getPackageNamespace() != ''){
                    String uiLibNS = LMSUtils.getPackageNamespace()+'almond_uilib';
                    a.Eligible_Image__c = a.Eligible_Image__c.replace('almond_uilib',uiLibNS);
                    a.Acquired_Image__c = a.Acquired_Image__c.replace('almond_uilib',uiLibNS);
                }
                String categoryName = (String)achievementHeader.get('achievement-category');
                categoryName = addTimeStamp?categoryName+ts:categoryName;
                if(existingRecordsMap.get('achievement-category') != null && existingRecordsMap.get('achievement-category').get(categoryName) != null){
                    a.Achievement_Category__c = existingRecordsMap.get('achievement-category').get(categoryName);
                }
                achievements.put(a.Name,a);
            }

            if(achievements.size() > 0){
                insert achievements.values();
            }

            //Create training plans
            List<Object> planObjects = getObjectList(dataMap,'plan-objects');

            for(Object po : planObjects){
                //Create plan header
                Map<String,Object> pHeader = (Map<String,Object>)po;
                Training_Plan__c tp = new Training_Plan__c();
                String tplanName = addTimeStamp?(String)pHeader.get('name')+ts:(String)pHeader.get('name');
                tp.Name = tplanName;
                tp.Description__c = getStringValue(pHeader.get('description'),null);
                tp.Status__c = getStringValue(pHeader.get('status'),null);
                tp.Start_Date__c = (Date.today()).addDays(-1);
                tp.End_Date__c = (Date.today()).addDays(365);
                tp.Intro_Video_URL__c = getStringValue(pHeader.get('intro-video-url'),null);
                tp.Background_Image_URL__c = getStringValue(pHeader.get('background-image-url'),null);
                tp.Background_Color__c = getStringValue(pHeader.get('background-color'),null);
                tp.Text_Color__c = getStringValue(pHeader.get('text-color'),null);
                tp.Enforce_Sequence__c = getBooleanValue(pHeader.get('enforce-sequence'),false);
                tp.Enable_Self_Registration__c = getBooleanValue(pHeader.get('enable-self-registration'),false);
                tp.Self_Registration_Access__c = getStringValue(pHeader.get('self-registration-access'),null);
                tp.Hide_Chatter_Photos__c = getBooleanValue(pHeader.get('hide-chatter-photos'),false);
                plans.put(tp.Name,tp);
            }

            if(plans.size() > 0){
                insert plans.values();
            }

            //Create sections
            for(Object po : planObjects){
                Map<String,Object> pHeader = (Map<String,Object>)po;
                String planName = addTimeStamp?(String)pHeader.get('name')+ts:(String)pHeader.get('name');
                List<Object> sectionObjects = getObjectList(pHeader,'sections');

                for(Object so : sectionObjects){
                    Map<String,Object> soHeader = (Map<String,Object>)so;
                    Training_Plan_Section__c tps = new Training_Plan_Section__c();
                    String planSectionName = addTimeStamp?(String)soHeader.get('name')+ts:(String)soHeader.get('name');
                    tps.Name = planSectionName;
                    tps.Training_Plan__c = plans.get(planName).Id;
                    tps.Order__c = getIntegerValue(soHeader.get('order'),null);
                    tps.Optional__c = getBooleanValue(soHeader.get('optional'),false);
                    sections.put(planName+'_'+tps.Name,tps);
                }
            }

            if(sections.size() > 0){
                insert sections.values();
            }

            //Create section items
            for(Object po : planObjects){
                Map<String,Object> pHeader = (Map<String,Object>)po;
                String planName = addTimeStamp?(String)pHeader.get('name')+ts:(String)pHeader.get('name');

                List<Object> sectionObjects = getObjectList(pHeader,'sections');

                for(Object so : sectionObjects){
                    Map<String,Object> soHeader = (Map<String,Object>)so;
                    String soHeaderName = planName+'_'+(String)soHeader.get('name');
                    soHeaderName += addTimeStamp?ts:'';

                    List<Object> itemObjects = getObjectList(soHeader,'items');

                    for(Object si : itemObjects){
                        Map<String,Object> siHeader = (Map<String,Object>)si;

                        Training_Plan_Section_Item__c tpsi = new Training_Plan_Section_Item__c();
                        tpsi.Order__c = getIntegerValue(siHeader.get('order'),null);
                        tpsi.Optional__c = getBooleanValue(siHeader.get('optional'),false);
                        tpsi.Training_Plan_Section__c = sections.get(soHeaderName).Id;
                        String learningName = addTimeStamp?(String)siHeader.get('learning')+ts:(String)siHeader.get('learning');
                        tpsi.Learning__c = learnings.get(learningName).Id;
                        sectionItems.put(soHeaderName+'_'+tpsi.Order__c,tpsi);
                    }
                }

            }

            if(sectionItems.size() > 0){
                insert sectionItems.values();
            }

            //Create training plan achievements
            for(Object po : planObjects){
                Map<String,Object> pHeader = (Map<String,Object>)po;
                String planName = addTimeStamp?(String)pHeader.get('name')+ts:(String)pHeader.get('name');

                List<Object> tplanAchievementObjects = getObjectList(pHeader,'achievements');

                for(Object pa : tplanAchievementObjects){
                    Map<String,Object> tpaHeader = (Map<String,Object>)pa;

                    String achievementName = addTimeStamp?(String)tpaHeader.get('achievement')+ts:(String)tpaHeader.get('achievement');
                    String sectionKey = planName+'_'+(String)tpaHeader.get('section');
                    sectionKey+= addTimeStamp?ts:'';

                    Training_Plan_Achievement__c tpa = new Training_Plan_Achievement__c();
                    tpa.Training_Plan__c = plans.get(planName).Id;

                    tpa.Training_Plan_Section__c= sections.get(sectionKey)!=null?sections.get(sectionKey).Id:null;
                    tpa.Main_Achievement__c = (Boolean)tpaHeader.get('main-achievement');

                    if(achievements.get(achievementName) != null){
                        tpa.Achievement__c = achievements.get(achievementName).Id;
                    }

                    planAchievements.put(planName+'_'+achievementName,tpa);
                }

            }

            if(planAchievements.size() > 0){
                insert planAchievements.values();
            }

            //Create training tracks
            if(dataMap.get('track-objects') != null){

                List<Object> trackObjects = getObjectList(dataMap,'track-objects');

                for(Object po : trackObjects){

                    //Create plan header
                    Map<String,Object> pHeader = (Map<String,Object>)po;
                    Training_Track__c tk = new Training_Track__c();
                    String trackName = addTimeStamp?(String)pHeader.get('name')+ts:(String)pHeader.get('name');
                    tk.Name = trackName;
                    tk.Description__c = getStringValue(pHeader.get('description'),null);
                    tk.Status__c = getStringValue(pHeader.get('status'),'Draft');
                    tk.Order__C = getIntegerValue(pHeader.get('order'),null);
                    tk.Background_Image_URL__c = getStringValue(pHeader.get('background-image-url'),null);
                    tk.Text_Color__c = getStringValue(pHeader.get('text-color-url'),null);
                    tk.Background_Color__c = getStringValue(pHeader.get('background-color'),null);
                    String achievementName = addTimeStamp?(String)pHeader.get('achievement')+ts:(String)pHeader.get('achievement');

                    if(achievements.get(achievementName) != null){
                      tk.Achievement__c = achievements.get(achievementName).Id;
                    }
                    tracks.put(tk.Name,tk);

                }

                if(tracks.size() > 0){
                    insert tracks.values();
                }

                //Create track levels
                for(Object po : trackObjects){
                    Map<String,Object> pHeader = (Map<String,Object>)po;
                    String trackName = addTimeStamp?(String)pHeader.get('name')+ts:(String)pHeader.get('name');

                    List<Object> levelObjects = getObjectList(pHeader,'levels');

                    for(Object lv : levelObjects){
                        Map<String,Object> lvHeader = (Map<String,Object>)lv;
                        Training_Track_Level__c ttl = new Training_Track_Level__c();
                        String levelName = addTimeStamp?(String)lvHeader.get('name')+ts:(String)lvHeader.get('name');
                        ttl.Name = levelName;
                        ttl.Training_Track__c = tracks.get(trackName).Id;
                        ttl.Description__c = getStringValue(lvHeader.get('description'),null);
                        ttl.Order__c = getIntegerValue(lvHeader.get('order'),null);
                        levels.put(trackName+'_'+ttl.Name,ttl);
                    }
                }

                if(levels.size() > 0){
                    insert levels.values();
                }

                //Create track items
                for(Object to : trackObjects){
                    Map<String,Object> tHeader = (Map<String,Object>)to;
                    String trackName = addTimeStamp?(String)tHeader.get('name')+ts:(String)tHeader.get('name');

                    List<Object> levelObjects = getObjectList(tHeader,'levels');

                    for(Object lv : levelObjects){
                        Map<String,Object> lvHeader = (Map<String,Object>)lv;
                        String lvHeaderName = trackName+'_'+(String)lvHeader.get('name');
                        lvHeaderName += addTimeStamp?ts:'';

                        List<Object> itemObjects = getObjectList(lvHeader,'items');

                        for(Object ti : itemObjects){
                            Map<String,Object> tiHeader = (Map<String,Object>)ti;
                            Training_Track_Level_Item__c ttli = new Training_Track_Level_Item__c();
                            ttli.Order__c = getIntegerValue(tiHeader.get('order'),null);
                            ttli.Training_Track_Level__c = levels.get(lvHeaderName).Id;
                            String planName = addTimeStamp?(String)tiHeader.get('plan')+ts:(String)tiHeader.get('plan');
                            ttli.Training_Plan__c = plans.get(planName).Id;
                            trackItems.put(lvHeaderName+'_'+ttli.Order__c,ttli);
                        }
                    }

                }

                if(trackItems.size() > 0){
                    insert trackItems.values();
                }

            }

        }catch(Exception e){
            Database.rollback(sp);
            throw new LMSInitException(e.getMessage());
        }

    }

    private static List<Object> getObjectList(Map<String,Object> o, String key){
        if(o != null && o.get(key) != null){
            return (List<Object>)o.get(key);
        }else{
            return new List<Object>();
        }
    }

    private static String getStringValue(Object o, String defaultValue){
        return o!=null?(String)o:defaultValue;
    }

    private static Boolean getBooleanValue(Object o, Boolean defaultValue){
        return o!=null?(Boolean)o:defaultValue;
    }

    private static Integer getIntegerValue(Object o, Integer defaultValue){
        return o!=null?(Integer)o:defaultValue;
    }

    private static Double getDoubleValue(Object o, Double defaultValue){
        return o!=null?(Double)o:defaultValue;
    }

    private static String getTimeStamp(){
        DateTime dtimenow = DateTime.now();
        String ts = dtimenow.second()+''+dtimenow.millisecond();
        return ts;
    }

}
