public with sharing class s1SubmitBioController {

    public String description{get;set;}
    public String hobbies{get;set;}
    public Id imageId{get;private set;}
    
    public String distList{get;set;}
    public String assignmentId{get;private set;}
    public Boolean hasMessages{get{return ApexPages.hasMessages();}}
    public User curUser{get;private set;}
    
    public Boolean isCompleted{get;private set;}
    
    private Id trainingPlanId;
    private Learning_Assignment__c currentAssignment;

    public s1SubmitBioController(){
        init();
    }
    
    private void init(){
        assignmentId = ApexPages.currentPage().getParameters().get('aid');
        description = null;
        isCompleted = false;
        hobbies = null;
        distList= null;
        currentAssignment = null;
        //Get additional user info
        curUser = [select id,name,email,phone,title from User where id = :UserInfo.getUserId()];
        //Get additional assignment info
        //Get more info for current assignment
        List<Learning_Assignment__c> assignments = [select id
                                                        ,Training_Plan_Section__c
                                                        ,Training_Plan__c
                                                        ,Progress__c
                                                        from Learning_Assignment__c 
                                                        where id = :assignmentId];
                                                        
        if(assignments.size()>0){
            currentAssignment = assignments.get(0);
            if(currentAssignment.Progress__c == 'Completed'){
            	isCompleted = true;
            }
        }             
        
        imageId = getUserImage();                 
    }
    
    
    public PageReference submitBio(){
        return sendEmail();
    }
    
    private PageReference sendEmail(){
        
        if(String.isBlank(distList)|| String.isBlank(description)  || String.isBlank(hobbies)){
            LMSUtils.addErrorMessage('Please fill-in all required fields');
            return null;
        }else{
            try{
                String[] toAddresses = new String[] {curUser.email,distList};
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                
                //mail.setTargetObjectId(UserInfo.getUserId());
                
                mail.setToAddresses(toAddresses);
                mail.setSubject('Hello World from '+UserInfo.getName());
                mail.setSenderDisplayName('Salesforce.com On-boarding');
                mail.setUseSignature(false);
                mail.setBccSender(false);
                mail.setSaveAsActivity(true);
                
                String emailBody = '<body>';
                
                emailBody += '<h1>'+UserInfo.getName()+'</h1>';
                emailBody += '<br/>';
                emailBody += '<h2>About Me :</h2>';
                emailBody += '<p>'+description+'</p>';
                emailBody += '<h2>Hobbies :</h2>';
                emailBody += '<p>'+hobbies+'</p>';            
                
                emailBody += '</body>';
    
                mail.setHtmlBody(emailBody);
                
                List<Attachment> atts =[ select body from Attachment where id = :imageId];
                
                if(atts.size()>0){
                	Attachment att = atts.get(0);
	                Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
	                efa.setFileName('HelloWorld.png');
	                efa.setBody(att.body);
	                mail.setFileAttachments(new Messaging.EmailFileAttachment[] {efa});
                }
                
                Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});  
                
                Learning_Assignment__c asgmt = new Learning_Assignment__c(id=assignmentId);
                asgmt.Progress__c = 'Completed';
                asgmt.Progress_Percentage__c = 100;
                update asgmt;
                
				return redirectToPlanDetail();
            
            }catch(Exception e){
                ApexPages.addMessages(e);
                return null;
            }

        }

    }
    
	public PageReference cancelSubmission(){
		return redirectToPlanDetail();
	}
	
	private PageReference redirectToPlanDetail(){
		PageReference ref = Page.TrainingPlanDetail;
		if(LMSUtils.isMobileDevice()){
			ref = Page.s1TrainingPlanDetail;
		}
	    ref.getParameters().put('id',trainingPlanId);
	    ref.getParameters().put('aid',assignmentId);
	    ref.setRedirect(true);
	    return ref;		
	}
	
    private Id getUserImage(){

        Id result = null;
        
        if(currentAssignment != null){

            trainingPlanId = currentAssignment.Training_Plan__c;
            ID sectionId = currentAssignment.Training_Plan_Section__c;
            
            if(sectionId != null){
                //Get learning assignment for the task with picture
                List<Learning_Assignment__c> imageAssignments = [select id
                                                                ,Name 
                                                                from Learning_Assignment__c 
                                                                where Training_Plan_Section__c = :sectionId
                                                                and User__c = :UserInfo.getUserId()
                                                                and Learning_Version__r.Task__r.Enable_Image_Upload__c = true
                                                                order by CreatedDate asc];
                
                if(imageAssignments.size()>0){                                 
                    Learning_Assignment__c imageAssignment = imageAssignments.get(0);
                    if(imageAssignment != null){
                        //Fetch attachment from assignment
                        List<Attachment> attachments = [select id from Attachment where ParentId = :imageAssignment.Id];
                        if(attachments.size()>0){
                            result = attachments.get(0).Id;
                        }
                    }
                }
            }
        }
        
        return result;
    }
}