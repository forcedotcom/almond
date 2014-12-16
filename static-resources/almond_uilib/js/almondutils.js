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
var almond = (function($){

    var redirectHandler = function(url,retainHistory){
        retainHistory = typeof retainHistory !== "undefined" ? retainHistory : false;
        if(isSF1()){
            sforce.one.navigateToURL(url,!retainHistory);
        }else{
            window.location.href = url;
        }
    };

    var redirectHandlerWithStatus = function(url,retainHistory){
        if(typeof forceShowStatus != "undefined"){
            forceShowStatus();
        }
        redirectHandler(url,retainHistory);
    };

    var redirectHandlerWithTarget = function(url,target,retainHistory){
        if(isSF1() && isMobileDevice()){
            redirectHandler(url,retainHistory);
        }else{
            if(target == "_blank"){
                window.open(url,target);
            }else{
                redirectHandler(url,retainHistory);
            }
        }
    };

    var redirectHandlerWithTargetPopUp = function(url,retainHistory,loadingIconURL){
        if(isSF1() && isMobileDevice()){
            redirectHandler(url,retainHistory);
        }else{
            //Open a new browser window
            $.ajax({
             url: loadingIconURL,
             success: function(){window.open(url);},
             async: false
            });
        }
    };

    var isSF1 = function(){
        return (typeof sforce != 'undefined') && (sforce != null);
    }

    var isMobileDevice = function(){
        if(/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)) {
            return true;
        }else{
            return false;
        }
    }

    var myTrainingMenuHandler = function(elem,redirectURL){
        var selectedStatus = $(elem).attr('lms-status-id');
        //call apex controller
        if(redirectURL){
            redirectHandlerWithStatus(redirectURL+'?status='+selectedStatus,false);
        }
    };

    var enableSF1Shortcuts = function(){
        if(isSF1()){
            $(window).bind('keydown', function(event) {
                if (event.ctrlKey){
                    switch (String.fromCharCode(event.which).toLowerCase()) {
                    case 't':
                        event.preventDefault();
                        SfdcApp.projectOneNavigator.fireContainerEvent("one:toggleNav");
                        break;
                    case 'r':
                        event.preventDefault();
                        location.reload();
                        break;
                    }
                }
            });
        }
    };

    return {
        redirectHandler : redirectHandler,
        isSF1 : isSF1,
        myTrainingMenuHandler : myTrainingMenuHandler,
        redirectHandlerWithTarget : redirectHandlerWithTarget,
        redirectHandlerWithStatus : redirectHandlerWithStatus,
        redirectHandlerWithTargetPopUp : redirectHandlerWithTargetPopUp,
        isMobileDevice : isMobileDevice,
        enableSF1Shortcuts : enableSF1Shortcuts
    };

})(jQuery);
