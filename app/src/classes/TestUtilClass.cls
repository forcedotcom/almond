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
public class TestUtilClass {

    public static String getTimeStamp(){
        DateTime dtimenow = DateTime.now();
        String ts = dtimenow.second()+''+dtimenow.millisecond();
        return ts;
    }

    public static Integer getRandomInteger(Integer lower, Integer upper){
        return (Integer) Math.floor(Math.random() * (upper - lower)) + lower;
    }

    public static String getRandomQuestionType(){
        Integer option = getRandomInteger(1, 5);
        String sResult;

        if(option == 1)
            sResult = 'Text';
        else if(option == 2)
            sResult = 'Number';
        else if(option == 3)
            sResult = 'SelectOneQuestion';
        else if(option == 4)
            sResult = 'SelectMultipleQuestion';
        else if(option == 5)
            sResult = 'Boolean';
        else
            sResult = 'Text';

        return sResult;
    }

    public static String getRandomSentence(Integer wordNum){
        List<String> wordbank = new List<String>{'Hipster','Ipsum','Lorem','is', 'win', 'hot dog', 'Wes Anderson', 'to', 'do it', 'cupcakes', 'the'};
        String sResult;

        for(Integer i = 0; i < wordNum; i++){
            Integer wbposition = getRandomInteger(0, wordbank.size());
            sResult += wordbank.get(wbposition);
        }

        return sResult;
    }

    public static String getRandomUniqueString(Integer length){
        return EncodingUtil.base64Encode(crypto.generateAesKey(256)).substring(1,length);
    }

    public static Date getRandomFutureDate(){
        DateTime dt = System.now().addDays(getRandomInteger(0, 3));
        return Date.newinstance(dt.year(), dt.month(), dt.day());
    }

    public static List<User> createUsers(Integer iNum,String profileName){
        String localizedProfileName = getLocalizedProfileName(profileName);
        Profile oProfile = [select Id, Name, PermissionsCustomizeApplication from Profile where Name = :localizedProfileName limit 1];

        List<User> lResults = new List<User>();
        for(Integer i = 0; i < iNum; i++){
            User oUser = new User();
            oUser.FirstName = 'Tester';
            oUser.LastName = 'McCoy The '+i;
            oUser.Email = 'tester.mccoy' + getTimeStamp()+''+i+'@salesforce.com.test';
            oUser.Username = 'tester.mccoy' + getTimeStamp()+''+i+'@salesforce.com.test';
            oUser.CommunityNickname = getTimeStamp()+''+i;
            oUser.Alias = 't'+getTimeStamp()+''+i;
            oUser.TimeZoneSidKey = 'America/El_Salvador';
            oUser.LocaleSidKey = 'en_US';
            oUser.EmailEncodingKey = 'UTF-8';
            oUser.ProfileId = oProfile.Id;
            oUser.LanguageLocaleKey = 'en_US';
            oUser.IsActive = true;

            lResults.add(oUser);
        }

        insert lResults;
        return lResults;
    }


    /**
    *Method used to add Permission Sets to Test Users. NOTE: execute this method always inside of a System.runAs(...)
    *
    */
    public static void addPermissionSet(List<User> lusers, String permSetName){
        List<PermissionSetAssignment> lpsa = new List<PermissionSetAssignment>();
        List<PermissionSet> lps = [select id from PermissionSet where Name = :permSetName];

        for(User ouser : lusers){
            PermissionSetAssignment opsa = new PermissionSetAssignment();
            opsa.AssigneeId = ouser.Id;
            opsa.PermissionSetId = lps.get(0).Id;

            lpsa.add(opsa);
        }

        insert lpsa;
    }

    private static String getLocalizedProfileName(String profileName){
        if(UserInfo.getLanguage() == 'en_US'){
            return profileName;
        }else if(profileName == 'System Administrator'){
            return System.Label.ALMS_Sys_Admin_Profile;
        }else if(profileName == 'Standard User'){
            return System.Label.ALMS_Standard_User_Profile;
        }
        return profileName;
    }
}
