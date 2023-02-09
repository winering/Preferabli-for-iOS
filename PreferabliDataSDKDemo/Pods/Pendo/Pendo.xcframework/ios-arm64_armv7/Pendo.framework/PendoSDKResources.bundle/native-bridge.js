const kGuideStepId = 'guideStepId';
const kAdditionalInfo = 'additionalInfo';
const kDisplayDuration = 'displayDuration';
const kPollTypes = 'pollTypes';

function getFromContext(context, name) {
    return context[name];
}

function getOrientation() {
    var orientation = PNDNativeBridge.getDeviceOrientation();
    return orientation;
}

function logD(msg) {
    PNDNativeBridge.log(msg);
};

function StandIn(id) {
    this.elementId = id;
};

function getGuideStepId(context) {
    return getFromContext(context, kGuideStepId)
}

function getStepPollTypes(context) {
    return getFromContext(context, kPollTypes)
}

function gaTracker(trackingId) {
    return PNDNativeBridge.gaTracker(trackingId);
}

StandIn.prototype.getPageNumber = function () {
    return PNDNativeBridge.getPageNumber(this.elementId);
};

StandIn.prototype.getAnswers = function () {
    var dict = PNDNativeBridge.getAnswers(this.elementId);
    var additionalInfo = dict[kAdditionalInfo];
    return additionalInfo;
};

StandIn.prototype.isValid = function () {
    return PNDNativeBridge.isValid(this.elementId);
};

var dispatchActions = function (actions, context) {
    PNDNativeBridge.dispatchActionsContext(actions, context);
};

var findElementById = function (id) {
    return new StandIn(id);
};

function getGuideStepDuration(context) {
    return getFromContext(context, kDisplayDuration).toString();
}

function getDurationGuideDismissed(context) {
    return getGuideStepDuration(context);
}

function getPollResponseById(pollId) {
    var responseId = PNDNativeBridge.getPollResponseById(pollId);
    return responseId;
}
