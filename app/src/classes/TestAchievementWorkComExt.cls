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
private class TestAchievementWorkComExt{

    static testMethod void testAddingNewBadge(){

        List<Achievement_Category__c> lAchieveCat = TestAchievementData.createAchievementCategories(1);
        List<Achievement__c> lAchievement = TestAchievementData.createAchievements(1, lAchieveCat.get(0).Id, 'Achievements');
        List<WorkBadgeDefinition> lWorkBadges = TestAchievementData.createWorkBadges(10);

        PageReference pageRef = Page.AchievementWorkCom;
        Test.setCurrentPage(pageRef);
        Test.startTest();

            //Grab the first achievement
            Achievement__c  ac = lAchievement.get(0);
            AchievementWorkComExt cont = new AchievementWorkComExt(new Apexpages.StandardController(ac));

            List<WorkBadgeDefinition> contBadges = cont.badges;
            System.assertEquals(10,contBadges.size());
            System.assertEquals(null,cont.selectedBadge);

            PageReference saveResultRef = cont.saveBadgeInfo();
            System.assert(saveResultRef == null);

            //Select a badge from the list
            Id selectedBadge = contBadges.get(0).Id;
            cont.selectedBadge = selectedBadge;

            saveResultRef = cont.saveBadgeInfo();
            System.assert(saveResultRef != null);

            List<Achievement__c> updatedAchievements = [select id,Work_Badge_Id__c from Achievement__c where id = :ac.Id];
            System.assert(updatedAchievements.get(0).Work_Badge_Id__c != null);

        Test.stopTest();
    }

}
