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
public with sharing class LearningDeleteSharedAssignmentsExt {

    private String learningId;

    public LearningDeleteSharedAssignmentsExt(ApexPages.StandardController cont){
        learningId = cont.getRecord().Id;
        init();
    }

    private void init(){
        //Nothing to do here for now...
    }

    public PageReference deleteUnusuedSharedAssignments(){
        try{

            //BEGIN Access Check
            List<Schema.sObjectType> objectTypesToDelete = new List<Schema.sObjectType>();
            objectTypesToDelete.add(Shared_Learning_Assignment__c.sObjectType);
            LMS_ESAPI.isAuthorizedToDelete(objectTypesToDelete);
            //END Access Check

            Id batchInstanceId = Database.executeBatch(new LearningDeleteSharedAsgmtsBatch(learningId),20);
            LMSUtils.addSuccessMessage(System.Label.ALMS_Batch_Delete_Queued_Success);
        }catch(Exception e){
            ApexPages.addMessages(e);
        }
        return null;
    }

}
