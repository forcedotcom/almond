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
public with sharing class TrainingPlanAssignmentExtensionNew{

    public String firstName{get;set;}
    public String lastName{get;set;}
    public String email{get;set;}
    public String profileId{get;set;}
    public String roleId{get;set;}
    public String profileName{get;set;}
    public String roleName{get;set;}
    public Training_Plan_Assignment__c dummyAssignment{get;set;}
    public Training_Plan_Assignment__c dummySingleAssignment{get;set;}
    private String trainingPlanId;
    public Boolean filterExistingUsers{get;set;}
    public Boolean hasCommunities{get;set;}
    public String communityId{get;set;}

    public List<UserWrapper> users{get;set;}

    public class UserWrapper{
        public Boolean isSelected{get;set;}
        public String userId{get;set;}
        public transient User userRecord{get;set;}
        public UserWrapper(){}
    }

    public TrainingPlanAssignmentExtensionNew(ApexPages.StandardController cont){
        init();
        trainingPlanId = cont.getRecord().Id;
        filterExistingUsers = true;
    }

    private void init(){
        dummyAssignment = new Training_Plan_Assignment__c();
        dummySingleAssignment = new Training_Plan_Assignment__c();
        firstName = null;
        lastName = null;
        email = null;
        profileName = null;
        roleName = null;
        communityId = null;
        profileId = '';
        roleId = '';
        users = new List<UserWrapper>();
        hasCommunities = LMSUtils.hasCommunities();
    }

    public List<SelectOption> getProfiles() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('','--None--'));
        for(Profile p : [select id,Name from Profile where UserType IN ('Standard','CsnOnly') limit 300]){
            options.add(new SelectOption(p.Id,p.Name));
        }
        return options;
    }

    public List<SelectOption> getRoles() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('','--None--'));
        for(UserRole ur : [select id,Name from UserRole where PortalType = 'None' limit 300]){
            options.add(new SelectOption(ur.Id,ur.Name));
        }
        return options;
    }

    public PageReference searchUsers(){

        Set<Id> validPermSets = LMSUtils.getLMSPermSets();

        Set<Id> existingUserIds = new Set<Id>();

        //Get existing assignments
        if(filterExistingUsers){
            for(Training_Plan_Assignment__c tpa : [select id
                                                        ,User__c
                                                        from Training_Plan_Assignment__c
                                                        where Training_Plan__c = :trainingPlanId
                                                        and User__r.UserType IN ('Standard','CsnOnly')
                                                        LIMIT 10000]){
                existingUserIds.add(tpa.User__c);
            }
        }

        users = new List<UserWrapper>();
        String soql = 'SELECT id,name,email,profileId,userroleId,managerId FROM User WHERE isActive = true AND UserType IN (\'Standard\',\'CsnOnly\')';
        if(!String.isBlank(firstName)){
            soql += ' AND firstname = :firstName';
        }
        if (!String.isBlank(lastName)){
            soql += ' AND lastname = :lastName';
        }
        if (!String.isBlank(email)){
            soql += ' AND email = :email';
        }
        if (!String.isBlank(profileId)){
            soql += ' AND profileId = :profileId';
        }
        if (!String.isBlank(roleId)){
            soql += ' AND userroleId = :roleId';
        }
        if (!String.isBlank(profileName)){
            soql += ' AND profile.Name = :profileName';
        }
        if (!String.isBlank(roleName)){
            soql += ' AND userrole.name = :roleName';
        }
        if(dummyAssignment != null && dummyAssignment.User__c != null){
        	Id mgrId = dummyAssignment.User__c;
        	soql += ' AND managerId = :mgrId';
        }

        //Remove existing users
        if(existingUserIds.size()>0){
            soql+=' AND id NOT IN :existingUserIds';
        }

        soql+=' limit 500';

        Map<Id,User> userMap = new Map<Id,User>();
        for(User u : (List<User>)Database.query(soql)){
            userMap.put(u.Id,u);
        }

        if(userMap.size() == 0){
            return null;
        }

        Set<Id> validUsers = new Set<Id>();
        for(PermissionSetAssignment psa : [select Id
                                              ,AssigneeId
                                              from PermissionSetAssignment
                                              where PermissionSetId in :validPermSets
                                              and AssigneeId in :userMap.keySet()]){
            validUsers.add(psa.AssigneeId);
        }

        for(User u : userMap.values()){
            if(validUsers.contains(u.Id)){
                UserWrapper uw = new UserWrapper();
                uw.isSelected = false;
                uw.userId = u.Id;
                uw.userRecord = u;
                users.add(uw);
            }
        }

        return null;
    }

    public PageReference assignUsers(){
        try{


            assignmentAccessCheck();

            Set<Id> selectedUserIds = new Set<Id>();

            for(UserWrapper uw : users){
                if(uw.isSelected){
                    selectedUserIds.add(uw.userId);
                }
            }

            if(trainingPlanId != null && selectedUserIds.size() >0){
                LMSService.upsertAssignments(selectedUserIds,trainingPlanId,null);
            }

        }catch(Exception e){
            LMSUtils.logException(e,'TrainingPlanAssignmentExtensionNew');
            LMSUtils.addGenericUnknownErrorMessage('TrainingPlanAssignmentExtensionNew - assignUsers (1)');
            return null;
        }
        //Redirect to view page
        ApexPages.StandardController refController = new ApexPages.StandardController(new Training_Plan__c(id=trainingPlanId));
        return refController.view();
    }

    public PageReference assignSingleUser(){
        try{

            assignmentAccessCheck();

            if(dummySingleAssignment != null && dummySingleAssignment.User__c != null){
                if(LMSUtils.isValidLMSUser(dummySingleAssignment.User__c)){

                    communityId = String.isBlank(communityId)?null:communityId;

                    LMSService.upsertAssignments(new Set<Id>{dummySingleAssignment.User__c},trainingPlanId,communityId);
                    LMSUtils.addSuccessMessage(System.Label.ALMS_Single_User_Assignment_Success);
                }else{
                    LMSUtils.addErrorMessage(System.Label.ALMS_User_Missing_Perms);
                }
            }else{
                LMSUtils.addErrorMessage(System.Label.ALMS_Invalid_Single_User);
            }

            return null;

        }catch(Exception e){
            LMSUtils.logException(e,'TrainingPlanAssignmentExtensionNew');
            LMSUtils.addGenericUnknownErrorMessage('TrainingPlanAssignmentExtensionNew - assignUsers (1)');
            return null;
        }
    }

    public PageReference goToImportAssignments(){
        PageReference ref = Page.TrainingPlanImportAssignments;
        ref.getParameters().put('id',trainingPlanId);
        ref.getParameters().put('retURL','/'+trainingPlanId);
        return ref;
    }

    public List<SelectOption> getCommunities() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('','--None--'));

        if(hasCommunities){
            for(SObject so : (List<SObject>)Database.query('select id,Name from Network limit 100')){
                options.add(new SelectOption(so.Id,(String)so.get('Name')));
            }
        }
        return options;
    }

    private void assignmentAccessCheck(){
        //BEGIN Access Check
        Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
        relatedFieldsObjects.put(Learning_Assignment__c.sObjectType,new List<String>{
            'User__c'
            ,'Contact__c'
            ,'Learning__c'
            ,'Learning_Version__c'
            ,'Training_Plan__c'
            ,'Training_Plan_Section__c'
            ,'Training_Plan_Section_Item__c'
        });
        LMS_ESAPI.isAuthorizedToCreate(relatedFieldsObjects);
        LMS_ESAPI.isAuthorizedToUpdate(relatedFieldsObjects);
        //END Access Check
    }
}
