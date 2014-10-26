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
public with sharing class TrainingPlanSectionsHelper {

    public static void processBeforeUpdate(Map<Id,Training_Plan_Section__c> oldSectionsMap,Map<Id,Training_Plan_Section__c> newSectionsMap){
        validateRequiredItemsInOptionalSections(newSectionsMap.values(),oldSectionsMap);
    }

    //This method validates that an optional section doesn't have required items
    private static void validateRequiredItemsInOptionalSections(List<Training_Plan_Section__c> sections, Map<Id,Training_Plan_Section__c> oldSections){

        List<Training_Plan_Section__c> optionalSections = new List<Training_Plan_Section__c>();

        for(Training_Plan_Section__c sec : sections){

            Training_Plan_Section__c oldSec = null;

            if(oldSections != null){
                oldSec = oldSections.get(sec.Id);
            }

            //Only do validations for optional sections
            if(sec.Optional__c){

            if(oldSec == null){
                    //Inserts are ignored for now
                }else{
                    if(!oldSec.Optional__c){
                        //Only validate if value is changing from required to Optional
                        optionalSections.add(sec);
                    }
                }

            }
        }

        //Continue only if we have optional sections to validate
        if(optionalSections.size()>0){

            Set<Id> sectionsWithRequiredItems = new Set<Id>();
            String ns = LMSUtils.getPackageNamespace();
            //Get all required items in the referenced sections
            AggregateResult[] groupedResults = [select Training_Plan_Section__c
                                                        ,count(Id) cnt
                                                        from Training_Plan_Section_Item__c
                                                        where Training_Plan_Section__c in :optionalSections
                                                        and Optional__c = false
                                                        group by Training_Plan_Section__c];

            //If one of the sections has at least 1 required item we add it to a map
            for (AggregateResult ar : groupedResults)  {
                if((Integer)ar.get('cnt') > 0){
                    sectionsWithRequiredItems.add((String)ar.get(ns+'Training_Plan_Section__c'));
                }
            }

            //Add an error for all of those optional sections with required items
            for(Training_Plan_Section__c optSec : optionalSections){
                if(sectionsWithRequiredItems.contains(optSec.Id)){
                    optSec.addError('Sections with required items cannot be made optional');
                }
            }

        }

    }

}
