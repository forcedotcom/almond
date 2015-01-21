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
public with sharing class AchievementsUserSearchController extends LMSBaseController{

    @TestVisible
    private ApexPages.StandardSetController setCon;
    public Boolean hasMessages{get{return ApexPages.hasMessages();}}
    public String currentSearchTerm{get;private set;}

    public AchievementsUserSearchController(){
        init();
    }

    private void init(){
        try{

            //BEGIN Access Check
            Map<Schema.sObjectType,List<String>> relatedFieldsObjects = new Map<Schema.sObjectType,List<String>>();
                relatedFieldsObjects.put(User.sObjectType,new List<String>{
                'Name'
                ,'SmallPhotoUrl'
                });
            LMS_ESAPI.isAuthorizedToView(relatedFieldsObjects);
            //END Access Check

            String searchTerm = ApexPages.currentPage().getParameters().get('q');
            currentSearchTerm = searchTerm;

            if(searchTerm != null && !String.isBlank(searchTerm) && searchTerm.trim().length() > 2){
                System.debug('serchTerm ' +searchTerm);
                searchTerm = '%'+searchTerm+'%';

                Set<String> userTypes = new Set<String>{'Standard','CsnOnly'};
                Set<String> partnerTypes = new Set<String>{'PowerPartner','PowerCustomerSuccess'};
                Set<String> customerTypes = new Set<String>{'CSPLitePortal','CustomerSuccess'};

                if(LMSUtils.isPortalUser()){
                    if(partnerTypes.contains(UserInfo.getUserType())){
                        userTypes.addAll(partnerTypes);
                    }else{
                        userTypes.addAll(customerTypes);
                    }
                }else if(LMSUtils.getCurrentNetworkId() != null){
                    userTypes.addAll(partnerTypes);
                    userTypes.addAll(customerTypes);
                }

                this.setCon = new ApexPages.StandardSetController(Database.getQueryLocator(
                    [SELECT Id
                            ,Name
                            ,SmallPhotoUrl
                            FROM User
                            WHERE IsActive = true
                            AND UserType IN :userTypes
                            AND Name LIKE :searchTerm
                            ORDER BY CreatedDate desc
                            LIMIT 200]
                ));

                this.setCon.setpageNumber(1);
                this.setCon.setPageSize(10);
            }else{
                LMSUtils.addErrorMessage(System.Label.ALMS_Search_Minimum_Characters);
            }
        }catch(Exception e){
            LMSUtils.logException(e,'AchievementsUserSearchController');
            LMSUtils.addGenericUnknownErrorMessage('AchievementsUserSearchController - init (1)');
        }
    }

    public List<User> getSearchResults() {
        List<User> results = new List<User>();
        if(this.setCon != null){
            results = (List<User>) this.setCon.getRecords();
        }
        return results;
    }

    public Boolean getHasPrevious(){
        return this.setCon.getHasPrevious();
    }

    public Boolean getHasNext(){
        return this.setCon.getHasNext();
    }

    public Integer getPageNumber(){
        return this.setCon.getPageNumber();
    }

    public void doNext(){
        if(this.setCon.getHasNext()){
            this.setCon.next();
        }
    }

    public void doPrevious(){
        if(this.setCon.getHasPrevious()){
            this.setCon.previous();
        }
    }

    public Integer getTotalPages(){
        Decimal totalSize = this.setCon.getResultSize();
        Decimal pageSize = this.setCon.getPageSize();

        Decimal pages = totalSize/pageSize;

        return (Integer)pages.round(System.RoundingMode.CEILING);
    }

}
