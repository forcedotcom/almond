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
public class TestParams {

    public class TrainingPlanParam{
        public Date startDate;
        public Date endDate;
        public String status;
        public String selfRegistrationAccess;
        public Boolean enableSelfRegistration;
        public Boolean chatterNotificationsEnabled;
        public Boolean enforceSequence;
        public String description;
        public String name;

        public TrainingPlanParam(){
            this.name = 'Test TPlan '+TestUtilClass.getTimeStamp();
            this.startDate = Date.today().addDays(-1);
            this.endDate = Date.today().addDays(10);
            this.status = 'Active';

            this.enableSelfRegistration = false;
            this.selfRegistrationAccess = null;
            this.chatterNotificationsEnabled = false;
            this.enforceSequence = true;
            this.description = 'Sample description';
        }
    }

    public class TrainingTrackParam{
        public String status;
        public String textColor;
        public String backgroundColor;
        public String backgroundImageURL;
        public String description;
        public String name;
        public String achievementId;

        public TrainingTrackParam(){
            this.name = 'Test TTrack '+TestUtilClass.getTimeStamp();
            this.status = 'Active';
            this.textColor = '#000000';
            this.backgroundColor = '#EEEEEE';
            this.backgroundImageURL = 'https://www.salesforce.com/bg.png';
            this.description = 'Sample description';
            this.achievementId = null;
        }
    }

}
