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
public with sharing class TrainingTrackDetailCtrl extends LMSBaseController{

    private String trackId{get;private set;}
    public transient Training_Track__c track{get;private set;}
    public transient List<TrainingTrackLevel> trackLevels{get;private set;}
    public Integer totalItems{get;private set;}
    public Integer totalCompleted{get;private set;}

    public TrainingTrackDetailCtrl(){
        trackId = ApexPages.currentPage().getParameters().get('id');
        init();
    }

    private void init(){
        totalItems = 0;
        totalCompleted = 0;
        List<Training_Track__c> tracks = LMSService.getTrainingTracks('Active',trackId, LMSUtils.isPortalUser());

        // If we have access to the track header, proceed to fetch track item details
        if(tracks.size()>0){
            track = tracks.get(0);
            trackLevels = LMSWrappersService.getTrainingTrackLevels(LMSService.getTrainingTrackLevels(trackId, LMSUtils.isPortalUser()));

            //Fetch overall progress
            for(TrainingTrackLevel ttlevel : trackLevels){
                for(TrainingTrackItem ti : ttlevel.trackItems){
                    totalItems++;
                    if(ti.tplanAssignment != null & ti.tplanAssignment.Status__c == LMSConstants.TPLAN_STATUS_COMPLETED){
                        totalCompleted++;
                    }
                }
            }

        }else{
            LMSUtils.addErrorMessage(System.Label.ALMS_Training_Track_No_Access);
        }
    }

}
