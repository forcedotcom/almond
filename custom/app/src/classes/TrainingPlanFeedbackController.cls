public with sharing class TrainingPlanFeedbackController {
	public LMS_Feedback__c lmsfeedback {get; set;}
	public String tplanname {get; set;}
	private String assignmentId {get; set;}
	private String trainingplanId {get; set;}
	public Boolean hasMessages{get{return ApexPages.hasMessages();}}
	public String lmstemplate {get; set;}

	public TrainingPlanFeedbackController(){
		assignmentId = ApexPages.CurrentPage().getParameters().get('aid');
		trainingplanId = ApexPages.CurrentPage().getParameters().get('tid');
		lmsfeedback = new LMS_Feedback__c();
		lmstemplate = LMSUtils.isMobileDevice() ? 's1LMS_Template' : 'LMS_Template';

    	if(String.isnotBlank(assignmentId) && String.isnotBlank(trainingplanId)){
    		assignmentId = string.escapeSingleQuotes(assignmentId);
    		Learning_Assignment__c la = [select Id, Training_Plan__c, Training_Plan__r.Name, User__c from Learning_Assignment__c where Id =:assignmentId ];

    		tplanname = la.Training_Plan__r.Name;
    		lmsfeedback.Training_Plan__c = la.Training_Plan__c;
    		lmsfeedback.User__c = la.User__c;

    	}else{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There was an error with loading feedback, please contact your system administrator.'));
    	}
	}

	public PageReference save() {

		try{
			if(lmsfeedback.Activity_value__c == null || lmsfeedback.Confidence_customizing__c == null || lmsfeedback.Support_Material_value__c == null || lmsfeedback.Time_Spent_Preparing__c == null || String.isBlank(lmsfeedback.Participant_Comments__c) ){
				LMSUtils.addErrorMessage('All fields are required.');
				return null;
			}

			lmsfeedback.OwnerId = UserInfo.getUserId();
			insert lmsfeedback;

			Learning_Assignment__c la = new Learning_Assignment__c( Id = assignmentId);
			la.Progress__c = 'Completed';
			la.Progress_Percentage__c = 100;
			update la;

		}catch(Exception e){
			LMSUtils.addErrorMessage(e.getMessage());
            return null;
		}

		return redirectToPlanDetail();
	}

	public PageReference cancel(){
        return redirectToPlanDetail();
    }

    public PageReference redirectToPlanDetail(){
    	PageReference ref = LMSUtils.isMobileDevice() ? Page.s1TrainingPlanDetail : Page.TrainingPlanDetail;
        ref.getParameters().put('id',trainingplanId);
        ref.getParameters().put('aid',assignmentId);
        ref.setRedirect(true);
        return ref;
    }

}
