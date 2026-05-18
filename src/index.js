const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, PutCommand } = require("@aws-sdk/lib-dynamodb");

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

const TABLE_NAME = process.env.DYNAMODB_TABLE;
if (!TABLE_NAME) {
    throw new Error("DYNAMODB_TABLE environment variable is required");
}

function getApiSourceIp(event) {
    const http = event.requestContext?.http;
    if (http?.sourceIp) return http.sourceIp;

    const ip = event.body?.ip;
    if (ip) return ip;

    return null;
}

function apiResponse(statusCode, body) {
    return {
        statusCode,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
    };
}

exports.handler = async (event) => {
    console.log("Received event:", JSON.stringify(event, null, 2));

    const recordsToProcess = [];
    const isApiGateway = Boolean(event.requestContext && !event.Records);

    if (event.Records) {
        for (const record of event.Records) {
            const body = JSON.parse(record.body);
            const ip = body.ip || "Unknown SQS IP";
            recordsToProcess.push(saveToDynamoDB(ip, "SQS_Trigger"));
        }
    } else if (event.requestContext) {
        const ip = getApiSourceIp(event) || "Unknown API IP";
        recordsToProcess.push(saveToDynamoDB(ip, "API_Gateway_Trigger"));
    }

    if (recordsToProcess.length === 0) {
        const message = "No records to process";
        console.error(message, JSON.stringify(event));
        if (isApiGateway) {
            return apiResponse(400, { message });
        }
        throw new Error(message);
    }

    await Promise.all(recordsToProcess);

    if (isApiGateway) {
        return apiResponse(200, { message: "IP successfully logged!" });
    }

    return { batchItemFailures: [] };
};

async function saveToDynamoDB(ipAddress, source) {
    const command = new PutCommand({
        TableName: TABLE_NAME,
        Item: {
            visitor_ip: ipAddress,
            timestamp: new Date().toISOString(),
            trigger_source: source,
        },
    });
    return docClient.send(command);
}
