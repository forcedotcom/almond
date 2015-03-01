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
public with sharing class LMSConstants {

    public static final String RT_TRAINING_RESOURCE = 'Resource';
    public static final String RT_TASK = 'Task';
    public static final String RT_QUIZ = 'Quiz';

    public static final String TPLAN_STATUS_NOT_STARTED = 'Not Started';
    public static final String TPLAN_STATUS_IN_PROGRESS = 'In Progress';
    public static final String TPLAN_STATUS_COMPLETED = 'Completed';
    public static final String TPLAN_STATUS_VISIBILITY_CATALOG = 'Catalog';
    public static final String TPLAN_STATUS_ACTIVE = 'Active';

    public static final String ASSIGNMENT_STATUS_NOT_STARTED = 'Not Started';
    public static final String ASSIGNMENT_STATUS_IN_PROGRESS = 'In Progress';
    public static final String ASSIGNMENT_STATUS_IN_REVIEW = 'In Review';
    public static final String ASSIGNMENT_STATUS_COMPLETED = 'Completed';

    public static final String ASSIGNMENT_EVAL_PASSED = 'Passed';
    public static final String ASSIGNMENT_EVAL_FAILED = 'Failed';

    public static final String AA_ACQUIRED_STATUS = 'Acquired';
    public static final String AA_ELIGIBLE_STATUS = 'Eligible';
    public static final String AA_OVERRIDE_STATUS = 'Override';

    public static final String LV_ASK_VERSION = 'Ask user for version selection';
    public static final String LV_UPDATE_ON_LAUNCH = 'Update version on launch';
    public static final String LV_DECISION_PENDING = 'Pending';

    public static final String TTRACK_ACTIVE_STATUS = 'Active';
    public static final String TTRACK_DRAFT_STATUS = 'Draft';

    public static final String TPLAN_PUBLIC_EXTERNAL = 'External';

    public static final String ASSIGNMENT_NEW_VERSION_TAKEN = 'New version taken';
    public static final String ASSIGNMENT_USE_OLD_VERSION = 'Keep using old version';

}
