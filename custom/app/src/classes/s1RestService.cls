public with sharing class s1RestService {
    private static String SESSION_ID = null;
    
    public String getContactId(String email) {
        String contactId = null;
        try{
            String query = 'select Id from Contact where Email =\'' + email + '\'';
            
            s1SalesforceSessionManagerImpl sfimpl = new s1SalesforceSessionManagerImpl('SF');
            SESSION_ID = sfimpl.getSession(true);

            String encodedQuery = EncodingUtil.urlEncode(query,'UTF-8');
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint( 'https://supportforce.my.salesforce.com/services/data/v29.0/query?q=' + encodedQuery);
            req.setHeader('Authorization', 'OAuth ' + SESSION_ID);
            req.setHeader('Content-Type', 'application/json');
            req.setMethod('GET');


            HTTPResponse res = new Http().send(req);
            String body = res.getBody();

            if (res.getStatusCode() != 200) {
                return null;   
            }

            
            Map<String, Object> jsonResponseMap = (Map<String, Object>) system.JSON.deserializeUntyped(body);
            List<Object> records = (List<Object>) jsonResponseMap.get('records');
            
            if(records.size() > 0) {
                Map<String,Object> record =  ( Map<String,Object>) records.get(0);
                contactId = (String) record.get('Id');
            }

            

        } catch(Exception ex) {
            system.debug(ex.getMessage());
        }

        return contactId;
    }

    public String createSupportForceTicket(String email, String subject, String description, String internalSupportCategory) {
        String contactId = getContactId(email);
        String caseId = null;
        if(String.isNotBlank(contactId)) {
            String caseOwnerId = '00570000001X92s'; //ashwin
            String priority = '1 - High'; //priority
            String ticketRecordType= '0120000000000BSAAY'; //record type
            //String interalSupportCategoryFieldId = '00N00000006pKA8';
            //String supportForceOrgId = '00D00000000hg76';
            //String internalSupportCategory=  'Internal GUS.com App: Assetforce Requests: Access'; //supportCaetgory;
            
            Map<String,String> attributesMap = new Map<String,String>();
            attributesMap.put('type','Case');
            attributesMap.put('url','/services/data/v29.0/sobjects/Case');

            Map<String,Object> caseBody = new Map<String,Object>();
            caseBody.put('attributes',attributesMap);
            caseBody.put('Subject',subject);
            caseBody.put('Priority',priority);
            caseBody.put('Description',description);
            caseBody.put('RecordTypeId',ticketRecordType);
            caseBody.put('Internal_Support_Category__c',internalSupportCategory);
            caseBody.put('OwnerId',caseOwnerId);
            caseBody.put('ContactId',contactId);

            String json = system.JSON.serialize(caseBody);

            system.debug('json ' + json);
            
            HttpRequest req = new HttpRequest();
            req.setTimeout(60000);
            req.setHeader('Authorization','OAuth '+ SESSION_ID);
            req.setHeader('Content-Type','application/json');
            req.setEndpoint('https://supportforce.my.salesforce.com/services/data/v29.0/sobjects/Case');
            req.setMethod('POST');
            req.setBody(json);

            //Response: {"id":"5007000000XLEmFAAX","success":true,"errors":[]}
            
            try {
                    HttpResponse res = new Http().send(req);
                    system.debug(res.getBody());
                    system.debug(res.getStatusCode());
                    Map<String, Object> jsonResponseMap = (Map<String, Object>) system.JSON.deserializeUntyped(res.getBody());
                    caseid = (String) jsonResponseMap.get('id');
            }catch(Exception ex){
                System.debug(ex.getMessage());
            }
        }

        return caseId;
            
    }
}