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
global with sharing class LMSPlugins{

    private static String LMS_PLUGIN_SUFFIX = 'LMSPlugin';

    global class LMSPluginsException extends Exception{}

    global class LearningConfig{
        global String objectName{get;set;}
        global String learningVersionLookupField{get;set;}
        global String launchURL{get;set;}
        global String launchTarget{get;set;}
        global String customVFDomain{get;set;}

        public String namespacePrefix{get;set;}
        public String getLaunchURLWithNamespace(){

            //Update relative urls to avoid using the almond package namespace instead of the plugin's namespace
            if(!String.isBlank(launchURL)  && launchURL.startsWith('/apex/')){
                //Get the current org's instance url
                String sfdcBaseURL = System.URL.getSalesforceBaseUrl().toExternalForm();
                String sfdcHost = System.URL.getSalesforceBaseUrl().getHost();
                String customDomain = sfdcHost.substring(0,sfdcHost.indexOf('.'));

                String almondNSPrefix  = LMSUtils.getNamespacePrefix();

                if(!String.isBlank(almondNSPrefix)){
                    String domainNS1 = almondNSPrefix+'.';
                    String domainNS2 = '--'+almondNSPrefix;
                    Boolean startsWithNS = sfdcHost.startsWith(domainNS1);
                    Boolean endsWithNS = customDomain.endsWith(domainNS2);

                    if(startsWithNS || endsWithNS){
                        String toReplace = startsWithNS?domainNS1:domainNS2;
                        String customVFDomain = String.isBlank(customVFDomain)?'salesforce.com':customVFDomain;
                        String cleanSfdcHost =  sfdcHost.replace(toReplace,'').replace('visual.force.com',customVFDomain);
                        sfdcBaseURL = sfdcBaseURL.replace(sfdcHost, cleanSfdcHost);
                    }
                }

                //Pre-pend base url to the relative path
                if(!String.isBlank(namespacePrefix) && !launchURL.contains(namespacePrefix+'__')){
                    //Update launchURL If a relative url starting with /apex/ doesn't contain the namespace of the apex
                    launchURL = sfdcBaseURL+'/apex/'+namespacePrefix+'__'+launchURL.substringAfter('/apex/');
                }else{
                    launchURL = sfdcBaseURL+launchURL;
                }
            }
            return launchURL;
        }
    }

    global interface Learning{
        LMSPlugins.LearningConfig init();
    }

    public static LMSPlugins.LearningConfig getLearningPluginConfig(String pluginName){
        String pluginKlass = pluginName+LMS_PLUGIN_SUFFIX;
        String pluginNamespace = '';
        //Check for registered plugins by name pattern
        LMSPlugins.WithoutSharingOps wsops = new LMSPlugins.WithoutSharingOps();
        List<ApexClass> pluginClasses = wsops.getApexClassesForPlugin(pluginKlass);

        if(pluginClasses.size() == 1){
            if(pluginClasses.get(0).NamespacePrefix != null){
                pluginNamespace = pluginClasses.get(0).NamespacePrefix;
            }
        }else if(pluginClasses.size() > 0){
            throw new LMSPluginsException('Multiple plugin configurations found for : '+pluginKlass);
        }else{
            throw new LMSPluginsException('Invalid plugin configuration for : '+pluginKlass);
        }
        //Initialize instance if valid match is found
        Type t = Type.forName(pluginNamespace,pluginKlass);
        if(t == null) throw new LMSPluginsException('Invalid Plugin : '+pluginKlass);
        LMSPlugins.Learning plugin = (LMSPlugins.Learning)t.newInstance();
        //Extract plugin configuration
        LMSPlugins.LearningConfig config = plugin.init();
        //Update the namespace prefix with the namespace of the matching apex plugin
        config.namespacePrefix = pluginNamespace;
        return config;
    }

  	private without sharing class WithoutSharingOps{

        public List<ApexClass> getApexClassesForPlugin(String pluginKlass){
            List<ApexClass> pluginClasses = [select Id
                                                    ,Name
                                                    ,NamespacePrefix
                                                    from ApexClass
                                                    where Name = :pluginKlass
                                                    and Status = 'Active'];

            return pluginClasses;
        }

    }

}
