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
public with sharing class TrainingPlanImportAssignmentsExt {

    public String selectedReportId{get;set;}
    public String selectedFolderId{get;set;}
    public List<SelectOption> importReports{get;set;}
    public String customColumnIndex{get;set;}
    private Id trainingPlanId;

    public TrainingPlanImportAssignmentsExt(ApexPages.StandardController cont){
        trainingPlanId = cont.getRecord().Id;
        importReports = new List<SelectOption>();
        selectedFolderId = null;
        selectedReportId = null;
        customColumnIndex = null;
    }

    public List<SelectOption> getReportFolders(){
        List<SelectOption> options = new List<SelectOption>();
        selectedReportId = null;
        options.add(new SelectOption('','-- Select Folder --'));
        for(Folder f : [select id,name from Folder where Type = 'Report']){
            if(f.name != null){
                options.add(new SelectOption(f.Id,f.Name));
            }
        }
        return options;
    }

    public PageReference loadReports(){
        importReports = new List<SelectOption>();
        if(!String.isBlank(selectedFolderId)){
            for(Report r : [select Format,Id,Name from Report where OwnerId = :selectedFolderId]){
                if(r.Format == 'Tabular'){
                    importReports.add(new SelectOption(r.Id,r.Name));
                }
            }
        }else{
            LMSUtils.addErrorMessage('Please select a valid folder from the list');
        }
        return null;
    }

    public PageReference importRecords(){
        try{
            if(selectedReportId != null){
                runReportAndImportData(selectedReportId);
                return new PageReference('/'+trainingPlanId);
            }else{
                LMSUtils.addErrorMessage('Please select a report from the report list');
                return null;
            }
        }catch(Exception e){
            ApexPages.addMessages(e);
            return null;
        }
    }

    private void runReportAndImportData(Id reportId){

        //BEGIN Access Check
        Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
        relatedFieldsObjects.put(Training_Plan_Batch_Operation__c.sObjectType,new List<String>{
            'Training_Plan__c'
            ,'Type__c'
            ,'Successes__c'
            ,'Status__c'
            ,'Errors__c'
        });
        relatedFieldsObjects.put(Batch_Operation_Record__c.sObjectType,new List<String>{
            'Training_Plan_Batch_Operation__c'
            ,'Record_Key__c'
            ,'Record_Type__c'
        });
        LMS_ESAPI.isAuthorizedToCreate(relatedFieldsObjects);
        //END Access Check

        List<String> userIds = new List<String>();

        // Run the report
        Reports.ReportResults results = Reports.ReportManager.runReport(reportId,true);

        //Get report metadata
        Reports.ReportExtendedMetadata extMetadata = results.getReportExtendedMetadata();
        Map<String,Reports.DetailColumn> columnInfoMap = extMetadata.getDetailColumnInfo();

        //Fetch user id column index
        Integer userIdCol = null;

        if(String.isBlank(customColumnIndex)){
            Integer colCount = 0;
            for(String colKey : columnInfoMap.keySet()){
                Reports.DetailColumn col = columnInfoMap.get(colKey);
                if(col.getName()=='USER_ID'){
                    userIdCol = colCount;
                }
                colCount++;
            }
        }else{
            userIdCol = Integer.valueOf(customColumnIndex);
        }

        //Extract user ids from factMap

        if(userIdCol != null){
            Map<String,Reports.ReportFactWithDetails> factMap = (Map<String,Reports.ReportFactWithDetails>)results.getFactMap();
            for(String key : factMap.keySet()){
                Reports.ReportFactWithDetails rFact = factMap.get(key);
                List<Reports.ReportDetailRow> rows = rFact.getRows();
                for(Reports.ReportDetailRow row : rows){
                    List<Reports.ReportDataCell> cells = row.getDataCells();
                    Reports.ReportDataCell cell = cells[userIdCol];
                    if(cell.getValue() != null){
                        String uid = (String)cell.getValue();
                        if(uid.startsWith('005')){
                            //Limit the number oF entries for unit tests
                            if(Test.isRunningTest() && userIds.size() == 5){
                                break;
                            }
                            userIds.add(uid);
                        }
                    }
                }
            }
        }

        //Create batch operation and batch operation items
        if(userIds.size() > 0){
            Training_Plan_Batch_Operation__c tpbo = new Training_Plan_Batch_Operation__c();
            tpbo.Training_Plan__c = trainingPlanId;
            tpbo.Type__c = 'Upsert Assignments';
            tpbo.Successes__c = 0;
            tpbo.Status__c = 'New';
            tpbo.Errors__c = 0;
            insert tpbo;

            List<Batch_Operation_Record__c> batchOperationRecords = new List<Batch_Operation_Record__c>();
            for(String uid : userIds){
                Batch_Operation_Record__c bor = new Batch_Operation_Record__c();
                bor.Training_Plan_Batch_Operation__c = tpbo.Id;
                bor.Record_Key__c = uid;
                bor.Record_Type__c = 'User';
                batchOperationRecords.add(bor);
            }

            insert batchOperationRecords;

            //Start batch job here
            try{
                Id batchJobId = Database.executeBatch(new TrainingPlanAssignmentsUpsertBatch(trainingPlanId,tpbo.Id), 10);
            }catch(Exception e){
                tpbo.Status__c = 'Failed';
                update tpbo;
            }
        }else{
            throw new LMSException('Report did not return any records or we were unable to retrieve valid users ids from the specified column');
        }
    }

}
