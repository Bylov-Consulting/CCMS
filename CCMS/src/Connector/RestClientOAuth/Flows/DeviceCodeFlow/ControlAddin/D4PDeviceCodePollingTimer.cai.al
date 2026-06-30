namespace D4P.CCMS.Connector.RestClientOAuth;
controladdin "D4P Device Code Polling Timer"
{
    StartupScript = 'src/Connector/RestClientOAuth/Flows/DeviceCodeFlow/ControlAddin/startup.js';
    Scripts = 'src/Connector/RestClientOAuth/Flows/DeviceCodeFlow/ControlAddin/script.js';

    MinimumHeight = 1;
    MaximumHeight = 1;
    RequestedHeight = 1;
    MinimumWidth = 1;
    MaximumWidth = 1;
    RequestedWidth = 1;

    event ControlAddInReady();
    event PollingTick();
    procedure StartPolling(PollIntervalSeconds: Integer);
    procedure StopPolling();
}