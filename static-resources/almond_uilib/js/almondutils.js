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

    var myTrainingMenuHandler = function(elem){
        //remove existing active
        var old_active = $(elem).parent().find('.almond-nav-active');
        old_active.removeClass('almond-nav-active');

        $(elem).addClass('almond-nav-active');

        //call apex controller
        loadtplansJS($(elem).attr('lms-status-id'));
    };

	return {
  		redirectHandler : redirectHandler,
		isSF1 : isSF1,
		myTrainingMenuHandler : myTrainingMenuHandler,
		redirectHandlerWithTarget : redirectHandlerWithTarget,
		redirectHandlerWithStatus : redirectHandlerWithStatus,
		redirectHandlerWithTargetPopUp : redirectHandlerWithTargetPopUp,
		isMobileDevice : isMobileDevice
	};

})(jQuery);
