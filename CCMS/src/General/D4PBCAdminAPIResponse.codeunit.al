namespace D4P.CCMS.General;

/// <summary>
/// Reusable parser for Business Central admin-API responses.
///
/// Async admin-API actions (scheduleUpdate / updateApp / startDatabaseExport /
/// activateFeature) return an EnvironmentOperation object (HTTP 202 Accepted)
/// whose identifier lives in the root "id" property — the same field the
/// operations list parser reads (see "D4P BC Operations Helper".InsertOperation,
/// which calls GetJsonGuid(JOperation, 'id', ...)). The action helpers today
/// read the body into ResponseText and only Message() it in debug mode, so the
/// cloud operation id is discarded and the async poll contract (return
/// operationId) cannot be satisfied. This codeunit centralises extracting that id.
/// </summary>
codeunit 62004 "D4P BC Admin API Response"
{
    Access = Public;

    /// <summary>
    /// Returns the cloud operation id carried in an admin-API operation response
    /// body, as text. Returns '' when the body is empty, not JSON, or carries no
    /// operation id.
    /// </summary>
    /// <param name="ResponseBody">Raw admin-API response body (JSON).</param>
    /// <returns>The operation id as text, or '' when none is present.</returns>
    procedure TryGetOperationId(ResponseBody: Text): Text
    begin
        // RED-phase stub: not yet implemented. Returns '' so the app compiles
        // while the operationId-extraction test fails (proving the behaviour is
        // not yet present). The GREEN phase parses ResponseBody and returns the
        // root "id" property.
        exit('');
    end;
}
