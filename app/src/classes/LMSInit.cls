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

    private static String fetchInitData(){
        String resourceName = 'almond_LMSInitData';
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

    private static String getTimeStamp(){
        DateTime dtimenow = DateTime.now();
        String ts = dtimenow.second()+''+dtimenow.millisecond();
        return ts;
    }

    public static void initData(Boolean addTimeStamp,String achievementCategoryName){

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
        LMS_ESAPI.isAuthorizedToCreate(relatedFieldsObjects);
        //END Access Check

        Savepoint sp = Database.setSavepoint();

        try{

            //Check for sample categories
            Map<String,Achievement_Category__c> acMap = new Map<String,Achievement_Category__c>();
            for(Achievement_Category__c sampleAC : [select id,name from Achievement_Category__c where Name = :achievementCategoryName]){
                acMap.put(sampleAC.name,sampleAc);
            }

            if(acMap.size()==0){
                Achievement_Category__c ac = new Achievement_Category__c();
                ac.Name = achievementCategoryName;
                acMap.put(ac.name,ac);
                insert acMap.values();
            }


            Map<String,Object> dataMap = (Map<String,Object>)JSON.deserializeUntyped(fetchInitData());
            String ts = '_'+getTimeStamp();

            //Create record type map
            Map<String,String> learningRTMap = new Map<String,String>();
            String learningObjectName = LMSUtils.getPackageNamespace()+'Learning__c';
            for(RecordType rt : [select Id,DeveloperName from RecordType where SobjectType = :learningObjectName]){
                learningRTMap.put(rt.DeveloperName,rt.Id);
            }

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

            //Iterate over lookup objects
            List<Object> lookupObjects = (List<Object>)dataMap.get('lookup-objects');
            for(Object lo : lookupObjects){
                Map<String,Object> lHeader = (Map<String,Object>)lo;
                String name = (String)lHeader.get('name');
                String type = (String)lHeader.get('type');
                if(type == 'answer-sequence'){
                    Answer_Sequence__c aseq = new Answer_Sequence__c();
                    answerSequences.put(name+ts,aseq);
                }
            }

            insert answerSequences.values();

            for(Object lo : lookupObjects){
                Map<String,Object> lHeader = (Map<String,Object>)lo;
                String name = (String)lHeader.get('name');
                String type = (String)lHeader.get('type');
                String headerName = name+ts;
                if(type == 'answer-sequence'){
                    Map<String,Object> lookUpContent = (Map<String,Object>)lHeader.get('content');
                    List<Object> sequenceItems = (List<Object>)lookUpContent.get('options');
                    for(Object sit : sequenceItems){
                        Map<String,Object> it = (Map<String,Object>)sit;
                        Answer_Sequence_Item__c asi = new Answer_Sequence_Item__c();
                        asi.Order__c = (Integer)it.get('order');
                        asi.Answer_Text__c = (String)it.get('answer-text');
                        asi.Item_Id__c = (String)it.get('answer-id')+'_'+ts;
                        asi.Is_Correct_Answer__c = (Boolean)it.get('is-correct-answer');
                        asi.Answer_Sequence__c = answerSequences.get(headerName).Id;
                        answerSequenceItems.put(headerName+asi.Item_Id__c,asi);
                    }
                }
            }

            insert answerSequenceItems.values();

            //Iterate over learning objects
            List<Object> learningObjects = (List<Object>)dataMap.get('learning-objects');

            for(Object lo : learningObjects){

                //Create learning header
                Map<String,Object> lHeader = (Map<String,Object>)lo;
                Learning__c l = new Learning__c();
                String lName = addTimeStamp?(String)lHeader.get('name')+ts:(String)lHeader.get('name');
                l.Name = lName;
                l.RecordTypeId = learningRTMap.get((String)lHeader.get('record-type'));
                l.Duration__c = (Integer)lHeader.get('duration');
                l.Description__c = (String)lHeader.get('description');
                l.Sync_progress__c = (Boolean)lHeader.get('sync-progress');
                learnings.put(l.Name,l);

            }

            insert learnings.values();

            //Create learning content
            for(Object lo : learningObjects){

                Map<String,Object> lHeader = (Map<String,Object>)lo;
                Map<String,Object> lContent = (Map<String,Object>)lHeader.get('content');
                String headerName = addTimeStamp?(String)lHeader.get('name')+ts:(String)lHeader.get('name');

                if((String)lHeader.get('record-type') == 'Resource'){
                    Training_Resource__c tr = new Training_Resource__c();
                    tr.Name = (String)lContent.get('name');
                    tr.Resource_URL__c = (String)lContent.get('resource-url');
                    tr.Add_training_parameters_to_URL__c = (Boolean)lContent.get('training-params-url');
                    tr.Description__c = (String)lContent.get('description');
                    tr.Display_in_Iframe__c = (Boolean)lContent.get('display-in-iframe');
                    tr.Learning__c = learnings.get(headerName).Id;
                    resources.put(tr.Learning__c,tr);
                }else if((String)lHeader.get('record-type') == 'Task'){
                    Task__c tk = new Task__c();
                    tk.Name = (String)lContent.get('name');
                    tk.External_Resource_Name__c = (String)lContent.get('resource-name');
                    tk.External_Resource_URL__c = (String)lContent.get('resource-url');
                    tk.Add_training_parameters_to_URL__c = (Boolean)lContent.get('training-params-url');
                    tk.Description__c = (String)lContent.get('description');
                    tk.Learning__c = learnings.get(headerName).Id;
                    tasks.put(tk.Learning__c ,tk);
                }else if((String)lHeader.get('record-type') == 'Quiz'){
                    Quiz__c qz = new Quiz__c();
                    qz.Name = (String)lContent.get('name');
                    qz.Passing_Score__c = (Double)lContent.get('passing-score');
                    qz.Max_Attempts__c = (Integer)lContent.get('max-attempts');
                    qz.Description__c = (String)lContent.get('description');
                    qz.Learning__c = learnings.get(headerName).Id;
                    quizzes.put(qz.Learning__c,qz);
                }
            }

            insert resources.values();
            insert tasks.values();
            insert quizzes.values();

            //Create quiz question lines
            for(Object lo : learningObjects){

                Map<String,Object> lHeader = (Map<String,Object>)lo;

                if((String)lHeader.get('record-type') == 'Quiz'){
                    Map<String,Object> lContent = (Map<String,Object>)lHeader.get('content');
                    List<Object> qLineObjects = (List<Object>)lContent.get('question-lines');
                    String headerName = addTimeStamp?(String)lHeader.get('name')+ts:(String)lHeader.get('name');

                    for(Object qlo : qLineObjects){
                        Map<String,Object> qlHeader = (Map<String,Object>)qlo;
                        String qlHeaderName = headerName+(String)qlHeader.get('name');
                        Question_Line__c ql = new Question_Line__c();
                        ql.Name = (String)qlHeader.get('name');
                        ql.Order__c = (Integer)qlHeader.get('order');
                        ql.Description__c = (String)qlHeader.get('description');
                        Learning__c l = learnings.get(headerName);
                        ql.Quiz__c = quizzes.get(l.id).Id;
                        questionLines.put(qlHeaderName,ql);
                    }
                }
            }

            insert questionLines.values();

            //Create quiz questions
            for(Object lo : learningObjects){

                Map<String,Object> lHeader = (Map<String,Object>)lo;

                if((String)lHeader.get('record-type') == 'Quiz'){
                    Map<String,Object> lContent = (Map<String,Object>)lHeader.get('content');
                    List<Object> qLineObjects = (List<Object>)lContent.get('question-lines');
                    String headerName = addTimeStamp?(String)lHeader.get('name')+ts:(String)lHeader.get('name');

                    for(Object qlo : qLineObjects){
                        Map<String,Object> qlHeader = (Map<String,Object>)qlo;
                        List<Object> questionObjects = (List<Object>)qlHeader.get('questions');
                        String qlHeaderName = headerName+(String)qlHeader.get('name');
                        Integer qCount = 0;

                        for(Object qo : questionObjects){
                            Map<String,Object> qHeader = (Map<String,Object>)qo;
                            Question__c q = new Question__c();
                            q.Description__c = (String)qHeader.get('description');
                            q.Type__c = (String)qHeader.get('type');
                            q.Order__c = (Integer)qHeader.get('order');
                            if(qHeader.get('answer-sequence') != null){
                                q.Answer_Sequence__c = answerSequences.get((String)qHeader.get('answer-sequence')+ts).Id;
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

            insert questions.values();


            //Publish learnings
            Map<String,Learning_Version__c> lVersions = new Map<String,Learning_Version__c>();
            List<Learning__c> insertedLearnings = [select id
                                        ,Name
                                        ,RecordType.DeveloperName
                                        from Learning__c
                                        where id in :learnings.values()];

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

            insert lVersions.values();

            //Update header information
            for(Learning__c l : insertedLearnings){
                l.Current_Published_Version__c = lVersions.get(l.id).Id;
                l.Published__c = true;
            }

            update insertedLearnings;

            //Create achievements
            List<Object> achievementObjects = (List<Object>)dataMap.get('achievement-objects');

            for(Object ao : achievementObjects){

                Map<String,Object> achievementHeader = (Map<String,Object>)ao;
                Achievement__c a = new Achievement__c();
                String aName = addTimeStamp?(String)achievementHeader.get('name')+ts:(String)achievementHeader.get('name');
                a.Name = aName;
                a.Type__c = (String)achievementHeader.get('type');
                a.Eligible_Image__c = (String)achievementHeader.get('eligible-image');
                a.Acquired_Image__c = (String)achievementHeader.get('acquired-image');
                if(LMSUtils.getPackageNamespace() != ''){
                    String uiLibNS = LMSUtils.getPackageNamespace()+'almond_uilib';
                    a.Eligible_Image__c = a.Eligible_Image__c.replace('almond_uilib',uiLibNS);
                    a.Acquired_Image__c = a.Acquired_Image__c.replace('almond_uilib',uiLibNS);
                }
                a.Achievement_Category__c = acMap.get(achievementCategoryName).Id;
                achievements.put(a.Name,a);
            }

            insert achievements.values();

            //Create training plans
            List<Object> planObjects = (List<Object>)dataMap.get('plan-objects');

            for(Object po : planObjects){

                //Create plan header
                Map<String,Object> pHeader = (Map<String,Object>)po;
                Training_Plan__c tp = new Training_Plan__c();
                String tplanName = addTimeStamp?(String)pHeader.get('name')+ts:(String)pHeader.get('name');
                tp.Name = tplanName;
                tp.Description__c = (String)pHeader.get('description');
                tp.Status__c = (String)pHeader.get('status');
                tp.Start_Date__c = (Date.today()).addDays(-1);
                tp.End_Date__c = (Date.today()).addDays(365);
                tp.Enforce_Sequence__c = (Boolean)pHeader.get('enforce-sequence');
                tp.Enable_Self_Registration__c = (Boolean)pHeader.get('enable-self-registration');
                tp.Self_Registration_Access__c = (String)pHeader.get('self-registration-access');
                plans.put(tp.Name,tp);

            }

            insert plans.values();

            //Create sections
            for(Object po : planObjects){
                Map<String,Object> pHeader = (Map<String,Object>)po;
                String planName = addTimeStamp?(String)pHeader.get('name')+ts:(String)pHeader.get('name');
                List<Object> sectionObjects = (List<Object>)pHeader.get('sections');

                for(Object so : sectionObjects){
                    Map<String,Object> soHeader = (Map<String,Object>)so;
                    Training_Plan_Section__c tps = new Training_Plan_Section__c();
                    String planSectionName = addTimeStamp?(String)soHeader.get('name')+ts:(String)soHeader.get('name');
                    tps.Name = planSectionName;
                    tps.Training_Plan__c = plans.get(planName).Id;
                    tps.Order__c = (Integer)soHeader.get('order');
                    sections.put(planName+'_'+tps.Name,tps);
                }
            }

            insert sections.values();

            //Create section items
            for(Object po : planObjects){
                Map<String,Object> pHeader = (Map<String,Object>)po;
                String planName = addTimeStamp?(String)pHeader.get('name')+ts:(String)pHeader.get('name');

                List<Object> sectionObjects = (List<Object>)pHeader.get('sections');

                for(Object so : sectionObjects){
                    Map<String,Object> soHeader = (Map<String,Object>)so;
                    String soHeaderName = planName+'_'+(String)soHeader.get('name');
                    soHeaderName += addTimeStamp?ts:'';

                    List<Object> itemObjects = (List<Object>)soHeader.get('items');

                    for(Object si : itemObjects){
                        Map<String,Object> siHeader = (Map<String,Object>)si;

                        Training_Plan_Section_Item__c tpsi = new Training_Plan_Section_Item__c();
                        tpsi.Order__c = (Integer)siHeader.get('order');
                        tpsi.Training_Plan_Section__c = sections.get(soHeaderName).Id;
                        String learningName = addTimeStamp?(String)siHeader.get('learning')+ts:(String)siHeader.get('learning');
                        tpsi.Learning__c = learnings.get(learningName).Id;
                        sectionItems.put(soHeaderName+'_'+tpsi.Order__c,tpsi);
                    }
                }

            }

            insert sectionItems.values();

            //Create training plan achievements
            for(Object po : planObjects){
                Map<String,Object> pHeader = (Map<String,Object>)po;
                String planName = addTimeStamp?(String)pHeader.get('name')+ts:(String)pHeader.get('name');

                List<Object> tplanAchievementObjects = (List<Object>)pHeader.get('achievements');

                for(Object pa : tplanAchievementObjects){
                    Map<String,Object> tpaHeader = (Map<String,Object>)pa;

                    String achievementName = addTimeStamp?(String)tpaHeader.get('achievement')+ts:(String)tpaHeader.get('achievement');
                    String sectionKey = planName+'_'+(String)tpaHeader.get('section');
                    sectionKey+= addTimeStamp?ts:'';

                    Training_Plan_Achievement__c tpa = new Training_Plan_Achievement__c();
                    tpa.Training_Plan__c = plans.get(planName).Id;

                    tpa.Training_Plan_Section__c= sections.get(sectionKey)!=null?sections.get(sectionKey).Id:null;
                    tpa.Achievement__c = achievements.get(achievementName).Id;
                    tpa.Main_Achievement__c = (Boolean)tpaHeader.get('main-achievement');

                    planAchievements.put(planName+'_'+achievementName,tpa);
                }

            }

            insert planAchievements.values();

        }catch(Exception e){
            Database.rollback(sp);
            throw new LMSInitException(e.getMessage());
        }

    }

}
