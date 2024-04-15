import json
import boto3
from decimal import Decimal

def lambda_handler(event, context):
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('VisitorCount')
    response = table.update_item(
        Key={'Id': '1'},
        UpdateExpression='ADD visitors :incr',
        ExpressionAttributeValues={':incr': 1},
        ReturnValues='UPDATED_NEW'
    )
    
    visitor_count = response['Attributes']['visitors']

    # Convert Decimal to int for serialization
    visitor_count_int = int(visitor_count)

    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Origin': 'marcellusb.com',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
        },
        'body': json.dumps({'visitor_count': visitor_count_int}),
    }