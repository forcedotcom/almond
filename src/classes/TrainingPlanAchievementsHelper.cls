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
public with sharing class TrainingPlanAchievementsHelper{

    public static void processBeforeInserts(List<Training_Plan_Achievement__c> tplanachievements){
        setType(tplanachievements);
    }

    public static void processBeforeUpdates(Map<Id,Training_Plan_Achievement__c> oldMap,Map<Id,Training_Plan_Achievement__c> newMap){

        List<Training_Plan_Achievement__c> updatedTPAs = new List<Training_Plan_Achievement__c>();
        for(Training_Plan_Achievement__c newTPA : newMap.values()){
            Training_Plan_Achievement__c oldTPA = oldMap.get(newTPA.Id);
            if(newTPA.Training_Plan_Section__c != oldTPA.Training_Plan_Section__c){
                updatedTPAs.add(newTPA);
            }
        }
        if(updatedTPAs.size()>0){
            setType(updatedTPAs);
        }
    }

    private static void setType(List<Training_Plan_Achievement__c> tplanachievements){

        for(Training_Plan_Achievement__c tpa : tplanachievements){
            if(tpa.Training_Plan_Section__c != null){
                tpa.Type__c = 'Section';
            }else{
             	tpa.Type__c = 'Plan';
            }
        }

    }
}
