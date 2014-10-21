public with sharing class s1AccessTicketsController {
    
    private static Map<String,String> categoryMap = new Map<String,String>();
    private static Map<String,String> typeSubjectMap = new Map<String,String>();
    public String subject {get;set;}
    
    public String description {get;set;}
    public String email {get;set;}
    public Boolean isCompleted{get;private set;}
    public boolean hasMessages{get{return ApexPages.hasMessages();}}
    private String type;

    static {
        categoryMap.put('businesscard','Facilities: Facilities - Japan: Business Card Order');
        categoryMap.put('perforce','Internal GUS.com App: Assetforce Requests: Access');
        categoryMap.put('gtm','IT Helpdesk: Access: GoToMeeting - Account request');
        typeSubjectMap.put('gtm','Go To Meeting Acount');
        typeSubjectMap.put('perforce','Perforce Access');
        typeSubjectMap.put('businesscard', ' Business Cards');
    }

    public s1AccessTicketsController() {
        type = ApexPages.currentPage().getParameters().get('type');
        String assignmentId = ApexPages.currentPage().getParameters().get('aid');
        isCompleted = false;
        subject = typeSubjectMap.get(type);
        Learning_Assignment__c currentAssignment = null;
        //Get additional user info
        User curUser = [select id,name,email,phone,title from User where id = :UserInfo.getUserId()];
        email = curUser.email;
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
    }

    public PageReference save() {
       
        if(String.isBlank(email)) {
            email = 'ashwin.reddy@salesforce.com';
        }

        if(String.isBlank(type)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please pass case category'));
            return null;
        }

        if(String.isBlank(subject)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter a subject'));
            return null;
        }

        if(String.isBlank(description)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter a description'));
            return null;
        }

        s1RestService rs = new s1RestService();
        String caseId = rs.createSupportForceTicket(email,subject,description,categoryMap.get(type));

        if(String.isBlank(caseId)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There was an error while creating supportforce ticket. Please try again.'));
            return null;
        }
        String assignmentId = ApexPages.currentPage().getParameters().get('aid');
        Learning_Assignment__c asgmt = new Learning_Assignment__c(id=assignmentId);
        asgmt.Progress__c = 'Completed';
        asgmt.Progress_Percentage__c = 100;
        update asgmt;

        //create a note
        Note n = new Note();
        n.Title = type + 'supportforce ticket.';
        n.Body= 'https://supportforce.my.salesforce.com/' + caseId;
        n.ParentId = assignmentId;
        
        insert n;
        
        String emailSubject = typeSubjectMap.get(type) + ' ticket';
        String emailBody = 'https://supportforce.my.salesforce.com/' + caseId;
        
        sendEmail(email, emailSubject, emailBody);
        return redirectToPlanDetail();
    }
    
    public PageReference cancelSubmission(){
        return redirectToPlanDetail();
    }
    
    public PageReference redirectToPlanDetail(){
        String assignmentId = ApexPages.currentPage().getParameters().get('aid');
        String trainingPlanId = ApexPages.currentPage().getParameters().get('tid');
        
        PageReference p = Page.TrainingPlanDetail;
        if(LMSUtils.isMobileDevice()) {
            p = Page.s1TrainingPlanDetail;
        }
        p.getParameters().put('id',trainingPlanId);
        p.getParameters().put('aid',assignmentId);

        return p;
    }
    
    private void sendEmail(String address, String subject, String body){
    	try {
    	    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
	        String[] toAddresses = new String[1]; 
	        toAddresses[0] = address;
	        mail.setToAddresses(toAddresses); 
	        mail.setOrgWideEmailAddressId('0D2i0000000TNxf');
	        mail.setSubject(subject);
	        mail.setPlainTextBody (body);
	        if (toAddresses.size() > 0) {
	            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
	        }      
    	}catch(Exception ex) {
    	    System.debug(ex.getMessage());
    	} 
    }
    

}