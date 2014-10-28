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
@isTest
public class TestLearningData {

	public static List<Learning__c> createTestLearning(Integer iNum, String recordType, Boolean bSyncProgress){
		List<Learning__c> lResult = new List<Learning__c>();
		String learningObjectName = LMSUtils.getPackageNamespace()+'Learning__c';
		List<RecordType> learningRT = [select Id, Name, DeveloperName from RecordType where SobjectType = :learningObjectName and DeveloperName =: recordType];

		for(Integer i = 0; i < iNum; i++){
			Learning__c olearning = new Learning__c();
			olearning.Description__c = 'dummy description';
			olearning.Duration__c = TestUtilClass.getRandomInteger(5, 200); //minutes
			olearning.Sync_progress__c = bSyncProgress;
			olearning.RecordTypeId = learningRT.get(0).Id;

			lResult.add(olearning);
		}

		insert lResult;
		return lResult;
	}


	public static List<Learning_Category__c> createTestLearningCategories(Integer iNum){
		List<Learning_Category__c> lResult = new List<Learning_Category__c>();
		for(Integer i = 0; i < iNum; i++){
			Learning_Category__c lc = new Learning_Category__c();
			lc.Name =  'Test Category '+i;
			lResult.add(lc);
		}

		insert lResult;
		return lResult;
	}

	public static List<Quiz__c> createTestQuiz(List<Learning__c> learnings){
		List<Quiz__c> lResult = new List<Quiz__c>();

		for(Learning__c ol : learnings){
			Quiz__c oquiz = new Quiz__c();
			oquiz.Description__c = 'dummy description';
			oquiz.Learning__c = ol.Id;
			oquiz.Max_Attempts__c = TestUtilClass.getRandomInteger(0, 20);
			oquiz.Passing_Score__c = 70;

			lResult.add(oquiz);
		}

		insert lResult;
		return lResult;
	}

	public static List<Quiz__c> createTestQuiz(List<Learning__c> learnings, Map<String,Object> params){
		List<Quiz__c> lResult = new List<Quiz__c>();

		for(Learning__c ol : learnings){
			Quiz__c oquiz = new Quiz__c();
			oquiz.Description__c = 'dummy description';
			oquiz.Learning__c = ol.Id;
			oquiz.Max_Attempts__c = TestUtilClass.getRandomInteger(0, 20);
			oquiz.Passing_Score__c = (Decimal)params.get('Passing_Score__c');
			lResult.add(oquiz);
		}

		insert lResult;
		return lResult;
	}

	public static List<Question_Line__c> createTestQuestionLine(List<Quiz__c> lquiz, Integer iNum){
		List<Question_Line__c> lResult = new List<Question_Line__c>();

		for(Quiz__c oquiz : lquiz){
			for(Integer i = 0; i < iNum; i++){
				Question_Line__c oql = new Question_Line__c();
				oql.Description__c = 'dummy description';
				oql.Order__c = i;
				oql.Quiz__c = oquiz.Id;

				lResult.add(oql);
			}
		}

		insert lResult;
		return lResult;
	}

	public static List<Question__c> createTestQuestions(List<Question_Line__c> qlines, Integer iNum, String questionType){
		List<Question__c> lResult = new List<Question__c>();
		Map<String,List<Question__c>> mResult = new Map<String,List<Question__c>>();

		for(Question_Line__c oql : qlines){
			for(Integer i = 0; i < iNum; i++){
				Question__c oq = new Question__c();
				String qtype = String.isBlank(questionType) ? TestUtilClass.getRandomQuestionType() : questionType;

				if(!mResult.containsKey(qtype)){
					mResult.put(qtype, new List<Question__c>());
				}

				if(qtype == 'Boolean'){
					oq.Correct_Boolean__c = (Math.roundToLong(Math.random()) == 1) ? 'true' : 'false';
				}

				if(qtype == 'Number'){
					oq.Correct_Number__c = TestUtilClass.getRandomInteger(1, 100);
				}

				oq.Description__c = 'dummy description';
				oq.Description_RTA__c = 'dummy large description';
				oq.Order__c = i;
				oq.Question_Line__c = oql.Id;
				oq.Type__c = qtype;
				oq.Answer_Sequence__c = null;


				mResult.get(qtype).add(oq);
			}
		}

		//handle select one & select multiple
		//iterate result maps and create answer sequence
		List<Question__c> lselectone = mResult.get('SelectOneQuestion');
		List<Question__c> lselectmultiple = mResult.get('SelectMultipleQuestion');

		if(lselectone != null && !lselectone.isEmpty()){
			List<Answer_Sequence__c> aseq = createTestAnswerSequences(lselectone.size(), 'SelectOneQuestion');
			Integer countSelOne = lselectone.size() - 1;

			for(Question__c qst : mResult.get('SelectOneQuestion')){
				qst.Answer_Sequence__c = aseq.get(countSelOne).Id;
				countSelOne--;
			}
		}

		if(lselectmultiple != null && !lselectmultiple.isEmpty()){
			List<Answer_Sequence__c> aseqM = createTestAnswerSequences(lselectmultiple.size(), 'SelectMultipleQuestion');
			Integer countSelMult = lselectmultiple.size() - 1;

			for(Question__c qst : lselectmultiple){
				qst.Answer_Sequence__c = aseqM.get(countSelMult).Id;
				countSelMult--;
			}
		}

		for(String key : mResult.keySet()){
			lResult.addAll(mResult.get(key));
		}

		insert lResult;
		return lResult;
	}

	public static List<Answer_Sequence__c> createTestAnswerSequences(Integer iNum, String qtype){
		List<Answer_Sequence__c> lResult = new List<Answer_Sequence__c>();

		for(Integer i = 0; i < iNum; i++){
			Answer_Sequence__c oaseq = new Answer_Sequence__c();
			oaseq.Internal_Notes__c = 'dummy internal notes';

			lResult.add(oaseq);
		}

		insert lResult;
		//call create answer seq items
		List<Answer_Sequence_Item__c> lasi = createTestAnswerSeqItems(lResult, TestUtilClass.getRandomInteger(2, 6), qtype);
		return lResult;
	}

	public static List<Answer_Sequence_Item__c> createTestAnswerSeqItems(List<Answer_Sequence__c> ansSeq, Integer iNum, String qtype){
		List<Answer_Sequence_Item__c> lResult = new List<Answer_Sequence_Item__c>();

		for(Answer_Sequence__c oas : ansSeq){
			List<Answer_Sequence_Item__c> lResultInt = new List<Answer_Sequence_Item__c>();

			for(Integer i = 0; i < iNum; i++){
				Answer_Sequence_Item__c oasi = new Answer_Sequence_Item__c();
				oasi.Item_Id__c = TestUtilClass.getRandomUniqueString(20);
				oasi.Answer_Sequence__c = oas.Id;
				oasi.Answer_Text__c = TestUtilClass.getRandomSentence(10); //.substring(1,254);
				oasi.Is_Correct_Answer__c = false;
				oasi.Order__c = i;

				lResultInt.add(oasi);
			}

			if(qtype == 'SelectOneQuestion'){
				lResultInt.get(TestUtilClass.getRandomInteger(0, iNum)).Is_Correct_Answer__c = true;
			}

			if(qtype == 'SelectMultipleQuestion'){
				for(Integer i = 0; i < TestUtilClass.getRandomInteger(1, iNum); i++){
					lResultInt.get(TestUtilClass.getRandomInteger(0, iNum)).Is_Correct_Answer__c = true;
				}
			}
			lResult.addAll(lResultInt);
		}

		insert lResult;
		return lResult;
	}

	public static Map<String, Response__c> createTestQuestionResponses(set<Id> qlineIds, Id UserId, Id learningAssignmentId){
		Map<String, Response__c> mResult = new Map<String, Response__c>();

		Set<String> typeOne = new Set<String>{'Text','Number','Boolean'};
		List<Question__c> lquestions1 = [select Id,
											Answer_Sequence__c,
											Correct_Boolean__c,
											Correct_Number__c,
											Question_Line__c,
											Type__c from Question__c where Question_Line__c in :qlineIds and Type__c in :typeOne];

		if(!lquestions1.isEmpty()){
			for(Question__c q1: lquestions1){
				Response__c response = new Response__c();
				if(q1.Type__c == 'Text'){
					response.Response_Text__c = 'Dummy Value';
					response.Response_Text_Long__c = 'Dummy Value Long';
				}

				if(q1.Type__c == 'Number'){
					response.Number_Response__c = q1.Correct_Number__c;
				}

				if(q1.Type__c == 'Boolean'){
					response.Boolean_Response__c = q1.Correct_Boolean__c;
				}

				response.Learning_Assignment__c = learningAssignmentId;
				response.Question__c = q1.Id;
				response.User__c = UserId;

				mResult.put(q1.Id, response);
			}
		}

		Set<String> typeTwo = new Set<String>{'SelectOneQuestion','SelectMultipleQuestion'};
		List<Question__c> lquestions2 = [select Id,
											Answer_Sequence__c,
											Correct_Boolean__c,
											Correct_Number__c,
											Question_Line__c,
											Type__c from Question__c where Question_Line__c in :qlineIds and Type__c in :typeTwo and Answer_Sequence__c != null];

		if(!lquestions2.isEmpty()){

			set<Id> asSet = new Set<Id>();
			for(Question__c oq2 : lquestions2){
				asSet.add(oq2.Answer_Sequence__c);
			}

			Map<String, List<Answer_Sequence_Item__c>> mAnsSeqItem = new Map<String, List<Answer_Sequence_Item__c>>();

			for(Answer_Sequence_Item__c oAnsSeqItem : [select Id,
														Item_Id__c,
														Answer_Sequence__c,
														Answer_Text__c
														from Answer_Sequence_Item__c
														where Answer_Sequence__c in :asSet and Is_Correct_Answer__c = true]){

				if(mAnsSeqItem.containsKey(oAnsSeqItem.Answer_Sequence__c)){
					mAnsSeqItem.get(oAnsSeqItem.Answer_Sequence__c).add(oAnsSeqItem);
				}else{
					mAnsSeqItem.put(oAnsSeqItem.Answer_Sequence__c, new List<Answer_Sequence_Item__c>{oAnsSeqItem});
				}
			}//for

			for(Question__c q2: lquestions2){
				Response__c response = new Response__c();
				if(q2.Type__c == 'SelectOneQuestion'){
					response.Response_Answer_Sequence_Label__c = mAnsSeqItem.get(q2.Answer_Sequence__c).get(0).Answer_Text__c;
					response.Response_Answer_Sequence_Long__c = mAnsSeqItem.get(q2.Answer_Sequence__c).get(0).Item_Id__c;
				}

				if(q2.Type__c == 'SelectMultipleQuestion'){
					String labels = '';
					String longs = '';
					for(Answer_Sequence_Item__c oasi : mAnsSeqItem.get(q2.Answer_Sequence__c)){
						labels += oasi.Answer_Text__c + ';';
						longs += oasi.Item_Id__c + ';';
					}

					response.Response_Answer_Sequence_Label__c = labels;
					response.Response_Answer_Sequence_Long__c = longs;
				}

				response.Response_Answer_Sequence__c = q2.Answer_Sequence__c;
				response.Learning_Assignment__c = learningAssignmentId;
				response.Question__c = q2.Id;
				response.User__c = UserId;

				mResult.put(q2.Id, response);
			}//for q2

		}//if lquestions2

		return mResult;
	}

	public static List<Training_Resource__c> createTestTrainingResource(List<Learning__c> learnings){
		List<Training_Resource__c> lResult = new List<Training_Resource__c>();

		for(Learning__c olearn : learnings){
			Training_Resource__c tresource = new Training_Resource__c();
			tresource.Name = TestUtilClass.getRandomUniqueString(20);
			tresource.Add_training_parameters_to_URL__c = false;
			tresource.Prevent_completion_on_launch__c = false;
			tresource.Description__c = TestUtilClass.getRandomSentence(5);
			tresource.Display_in_Iframe__c = false;
			tresource.Learning__c = olearn.Id;
			tresource.Resource_URL__c = 'https://www.' + TestUtilClass.getRandomUniqueString(10) + '.com';

			lResult.add(tresource);
		}

		insert lResult;
		return lResult;
	}

	public static List<Task__c> createTestTask(List<Learning__c> learnings){
		List<Task__c> lResult = new List<Task__c>();

		for(Learning__c olearn : learnings){
			Task__c task = new Task__c();
			task.Name = TestUtilClass.getRandomUniqueString(20);
			task.Add_training_parameters_to_URL__c = false;
			task.Description__c = TestUtilClass.getRandomSentence(5);
			task.Enable_Image_Upload__c = false;
			task.External_Resource_Name__c = TestUtilClass.getRandomSentence(3);
			task.External_Resource_Target__c = 'blank';
			task.External_Resource_URL__c = 'https://www.' + TestUtilClass.getRandomUniqueString(10) + '.com';
			task.Learning__c = olearn.Id;
			task.Requires_Manager_Approval__c = false;

			lResult.add(task);
		}

		insert lResult;
		return lResult;
	}

	public static void publishLearning(Id learningId,String learningType,Id learningContentId,Boolean askForVersionSelection){

		Learning__c learning = new Learning__c(id=learningId);
		Map<String,String> rtFieldMapping = new Map<String,String>{
           'task'=>'Task__c'
           ,'quiz'=>'Quiz__c'
           ,'resource'=>'Training_Resource__c'
        };

	    Learning_Version__c lVersion = new Learning_Version__c();
	    lVersion.Learning__c = learningId;
	    lVersion.Version_selection_behavior__c = askForVersionSelection?'Ask user for version selection':'Update version on launch';
		lVersion.put(rtFieldMapping.get(learningType),learningContentId);
	    lVersion.Type__c = 'Published';
	    lVersion.Version__c = 1;
	    insert lVersion;

	    //Update learning with latest published version reference
	    learning.Published__c = true;
	    learning.Current_Published_Version__c = lVersion.Id;
	    update learning;
	}

}
