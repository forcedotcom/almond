public with sharing class s1SalesforceSessionManagerImpl{
    
    // Rest service name. Configurations (Credentials) are maintained in HTIntegration package for each service against its
    // Confif key
    public String configKey;
    
    public s1SalesforceSessionManagerImpl(String configKey) {
        this.configKey = configKey;
    }
    
    // if newSessionRequired flag is true, creates a new session for the given config key
    // else returns the existing session for the given config key
    public String getSession(Boolean newSessionRequired) {
        String accessToken = '';
        if(newSessionRequired){
            accessToken = createNewSalesforceSession();
        }
        else{
        }
        return accessToken;
    }
    
    // Forms the key used for Storing the Session ID for given service
    public String getSessionKey(){
        return this.configKey + '_SESSION_ID';
    }
    
    //ClienId, ClientSecret, OauthToken, AccountId, Username, Password, Endpoint        
    public String createNewSalesforceSession() {    
        String access_token = '';
        Http h = new Http();
        HttpRequest req = getHttpRequest(this.configKey);
        try {
            HttpResponse res = h.send(req);
            Map<String,String> tokensResponse;
            system.debug(' res.getBody() ' + res.getBody());
            tokensResponse = (Map<String,String>)JSON.deserialize(res.getBody(),Map<String,String>.class);
            access_token = tokensResponse.get('access_token');
        }catch(Exception e){
            system.debug(e.getMessage());
            system.debug(e.getStackTraceString());
        }
        system.debug('access_token');
        return access_token;
    }
    
    private HttpRequest getHttpRequest(String configKey) {
        String endpoint = 'https://supportforce.my.salesforce.com';
        String authorizationServerURL = endpoint+'/services/oauth2/token';
        String payLoad = getPayLoad(configKey);
        
        HttpRequest req = new HttpRequest();
        req.setTimeout(60000);
        req.setEndpoint(authorizationServerURL );
        req.setMethod('POST');
        req.setBody(payLoad);
        
        
        return req;
    }
    
    private String getPayLoad(String configKey) {
        String payLoad = '';
        String consumerKey = 'CONSUMER_KEY';
        String consumerSecret = 'CONSUMER_SECRET';
        
        
        String username = 'your@user.com';
        String password = 'THEPASSWORD';
        payLoad = 'grant_type=password';
        payLoad+='&client_id='+consumerKey;
        payLoad+='&client_secret='+consumerSecret;
        payLoad+='&username='+username;
        payLoad+='&password='+password;         
        
        //Uncomment to see request payload
        system.debug('Payload ' + payLoad);
        return payLoad;
        
    }
}