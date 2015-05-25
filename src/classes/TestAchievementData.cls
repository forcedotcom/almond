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
@isTest
public class TestAchievementData {

    public static List<Achievement_Category__c> createAchievementCategories(Integer iNum){
        List<Achievement_Category__c> lResults = new List<Achievement_Category__c>();

        for(Integer i = 0; i < iNum; i++){
            Achievement_Category__c oACat = new Achievement_Category__c();
            oACat.Name = TestUtilClass.getRandomUniqueString(20);
            lResults.add(oACat);
        }

        insert lResults;
        return lResults;
    }

    public static List<Achievement__c> createAchievements(Integer iNum, Id aCategoryID, String sType){
        List<Achievement__c> lResults = new List<Achievement__c>();

        for(Integer i = 0; i < iNum; i++){
            Achievement__c oachievement = new Achievement__c();
            oachievement.Achievement_Category__c = aCategoryID;
            oachievement.Acquired_Image__c = '<div>Random Rich Text Content:Acquired Image</div>';
            oachievement.Eligible_Image__c = '<div>Random Rich Text Content:Eligible Image</div>';
            oachievement.Expiration_Date__c = TestUtilClass.getRandomFutureDate();
            oachievement.Type__c = sType;

            lResults.add(oachievement);
        }

        insert lResults;
        return lResults;
    }

    public static List<Achievement__c> createInternalAchievements(Integer iNum, Id aCategoryID, String sType){
        List<Achievement__c> lResults = new List<Achievement__c>();

        for(Integer i = 0; i < iNum; i++){
            Achievement__c oachievement = new Achievement__c();
            oachievement.Achievement_Category__c = aCategoryID;
            oachievement.Acquired_Image__c = '<div>Random Rich Text Content:Acquired Image</div>';
            oachievement.Eligible_Image__c = '<div>Random Rich Text Content:Eligible Image</div>';
            oachievement.Expiration_Date__c = TestUtilClass.getRandomFutureDate();
            oachievement.Is_Internal__c = true;
            oachievement.Type__c = sType;

            lResults.add(oachievement);
        }

        insert lResults;
        return lResults;
    }

    public static List<WorkBadgeDefinition> createWorkBadges(Integer iNum){

        Document document = new Document();
        document.AuthorId = UserInfo.getUserId();
        document.FolderId = UserInfo.getUserId();
        String docName = 'Doc'+TestUtilClass.getTimeStamp();
        document.Name = docName;
        document.DeveloperName = docName;
        document.Body = Blob.valueOf('Test Document Body');
        document.ContentType = 'image/png';
        document.IsPublic = true;
        document.Type = 'png';
        insert document;

        List<WorkBadgeDefinition> results = new List<WorkBadgeDefinition>();
        for(Integer i =0;i < iNum;i++){
            WorkBadgeDefinition wb = new WorkBadgeDefinition();
            wb.Description = 'test';
            wb.ImageUrl = document.Id;
            wb.IsActive = true;
            wb.IsCompanyWide = true;
            wb.Name = 'testBadge'+i;
            results.add(wb);
        }
        insert results;
        return results;

    }

}
