var deviceCodePollingTimer;

function StartPolling(pollIntervalSeconds) {
    StopPolling();

    deviceCodePollingTimer = setTimeout(function () {
        deviceCodePollingTimer = null;
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('PollingTick', null);
    }, pollIntervalSeconds * 1000);
}

function StopPolling() {
    if (deviceCodePollingTimer) {
        clearTimeout(deviceCodePollingTimer);
        deviceCodePollingTimer = null;
    }
}