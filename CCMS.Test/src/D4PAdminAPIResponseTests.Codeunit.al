namespace D4P.CCMS.Test;

using D4P.CCMS.General;
using System.TestLibraries.Utilities;

/// <summary>
/// RED-phase tests for the admin-API operationId extraction contract
/// (solution plan §2 / §5.1: scheduleUpdate / updateApp / startDatabaseExport /
/// activateFeature must parse the cloud operationId out of the admin-API
/// response body — today the helpers discard it).
///
/// Requirement under test: given an admin-API EnvironmentOperation response body,
/// "D4P BC Admin API Response".TryGetOperationId must return the operation's id.
/// The real shape is grounded in "D4P BC Operations Helper".InsertOperation,
/// which reads the operation id from the root "id" property
/// (GetJsonGuid(JOperation, 'id', ...)), and in the BC Admin Center API docs
/// (EnvironmentOperation / app-operation resource: id + type + status).
///
/// Assertions are falsifiable against that requirement: the first test pins the
/// exact GUID that must come back; the second pins that a non-operation body
/// yields '' (so a GREEN implementation cannot satisfy the suite by hardcoding
/// the GUID).
/// </summary>
codeunit 62106 "D4P Admin API Response Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    procedure TryGetOperationId_ReturnsRootIdGuid_FromOperationResponse()
    var
        AdminAPIResponse: Codeunit "D4P BC Admin API Response";
        ResponseBody: Text;
        ExpectedOperationId: Text;
        ActualOperationId: Text;
    begin
        // [GIVEN] A realistic admin-API EnvironmentOperation response body for a
        //         long-running scheduleUpdate, whose operation id sits in the
        //         root "id" property (the field the operations parser reads).
        ExpectedOperationId := 'b2c5e9d1-3f4a-4c8b-9e7d-1a2b3c4d5e6f';
        ResponseBody :=
            '{' +
            '"id":"' + ExpectedOperationId + '",' +
            '"type":"Update",' +
            '"status":"scheduled",' +
            '"environmentName":"Production",' +
            '"productFamily":"BusinessCentral",' +
            '"createdOn":"2026-06-06T10:00:00Z"' +
            '}';

        // [WHEN] Extracting the operation id from that body.
        ActualOperationId := AdminAPIResponse.TryGetOperationId(ResponseBody);

        // [THEN] The returned text equals the operation's "id" GUID — so the async
        //        action can hand the caller a real operationId to poll.
        Assert.AreEqual(
            ExpectedOperationId,
            ActualOperationId,
            'TryGetOperationId must return the operation id from the root "id" property of the admin-API operation response');
    end;

    [Test]
    procedure TryGetOperationId_ReturnsEmpty_ForBodyWithoutOperationId()
    var
        AdminAPIResponse: Codeunit "D4P BC Admin API Response";
        ActualOperationId: Text;
    begin
        // [GIVEN] A body that carries no operation id (empty / garbage). This pins
        //         the negative case so a GREEN implementation cannot pass the suite
        //         by hardcoding the positive GUID.
        // [WHEN] Extracting the operation id from a non-operation body.
        ActualOperationId := AdminAPIResponse.TryGetOperationId('not-json-and-no-operation-id');

        // [THEN] No id is fabricated.
        Assert.AreEqual(
            '',
            ActualOperationId,
            'TryGetOperationId must return '''' when the body carries no operation id');
    end;
}
